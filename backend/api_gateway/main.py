import os
import json
import time
import logging
from typing import Any, Dict, Optional

import jwt
import httpx
from pydantic import BaseModel
from fastapi.middleware.cors import CORSMiddleware
from fastapi import Header, Depends, FastAPI, Request, Response, HTTPException

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[logging.StreamHandler()],
)
logger = logging.getLogger("api_gateway")

# Service URLs
USER_AUTH_SERVICE_URL = os.getenv("USER_AUTH_SERVICE_URL", "http://user_auth_service:8000")
EVENT_TICKETING_SERVICE_URL = os.getenv("EVENT_TICKETING_SERVICE_URL", "http://event_ticketing_service:8001")

# JWT Configuration (should match user_auth_service)
SECRET_KEY = os.getenv("SECRET_KEY", "your-256-bit-secret")
ALGORITHM = "HS256"

app = FastAPI(
    title="Resellio API Gateway",
    description="API Gateway for Resellio ticket selling platform",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # For production, restrict this to specific origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Client for making requests to microservices
client = httpx.AsyncClient(
    timeout=30.0,
)


class ServiceResponse(BaseModel):
    status_code: int
    content: Any
    headers: Dict[str, str]


async def validate_token(
    authorization: Optional[str] = Header(None),
) -> Optional[Dict]:
    """Validate JWT token if provided"""
    if not authorization or not authorization.startswith("Bearer "):
        return None

    token = authorization.replace("Bearer ", "")
    try:
        # Just verify the token is valid, we don't need user info for most proxy operations
        return jwt.decode(
            token,
            SECRET_KEY,
            algorithms=[ALGORITHM],
        )
    except jwt.PyJWTError as e:
        logger.warning(f"Invalid token: {e}")
        raise HTTPException(
            status_code=401,
            detail="Invalid authentication credentials (are you using the correct secret?)",
        )


async def proxy_request(
    request: Request,
    target_service_url: str,
    path: str,
    token_data: Optional[Dict] = None,
) -> ServiceResponse:
    """
    Proxy a request to a target microservice

    Args:
        request: The incoming request
        target_service_url: Base URL of the target service
        path: Path to forward to at the target service
        token_data: Optional validated token data
    """
    url = f"{target_service_url}/{path}"
    body = await request.body()
    headers = dict(request.headers)

    # Remove headers that should not be forwarded
    headers.pop("host", None)

    logger.info(f"Proxying request: {request.method} {path} -> {url}")
    start_time = time.time()

    try:
        # Make the request to the target service
        response = await client.request(
            method=request.method,
            url=url,
            content=body,
            headers=headers,
            params=request.query_params,
            follow_redirects=True,
        )

        elapsed = time.time() - start_time
        logger.info(f"Response: {response.status_code} in {elapsed: .4f}s")

        # Forward the response
        return ServiceResponse(
            status_code=response.status_code,
            content=response.content,
            headers=dict(response.headers),
        )
    except httpx.RequestError as e:
        logger.error(f"Error proxying request: {str(e)}")
        elapsed = time.time() - start_time
        logger.error(f"Request failed after {elapsed: .4f}s")

        return ServiceResponse(
            status_code=503,
            content=json.dumps({"detail": f"Service unavailable: {str(e)}"}).encode(),
            headers={"Content-Type": "application/json"},
        )


@app.get("/health")
async def health_check():
    """Health check endpoint for the gateway itself"""
    return {
        "status": "healthy",
        "service": "API Gateway",
    }


@app.get("/debug")
async def debug_info(
    request: Request,
):
    """Debug endpoint to see request information"""
    return {
        "url": str(request.url),
        "method": request.method,
        "path": request.url.path,
        "query_params": dict(request.query_params),
        "headers": dict(request.headers),
        "client_host": request.client.host if request.client else None,
        "services": {
            "user_auth": USER_AUTH_SERVICE_URL,
            "event_ticketing": EVENT_TICKETING_SERVICE_URL,
        },
    }


# Auth Service Routes
@app.api_route("/api/auth/{path:path}", methods=["GET", "POST", "PUT", "DELETE"])
async def auth_service_proxy(
    request: Request,
    path: str,
):
    """Proxy requests to the auth service"""
    response = await proxy_request(
        request,
        USER_AUTH_SERVICE_URL,
        f"auth/{path}",
        None,
    )

    return Response(
        content=response.content,
        status_code=response.status_code,
        headers=response.headers,
    )


@app.api_route("/api/user/{path:path}", methods=["GET", "POST", "PUT", "DELETE"])
async def user_service_proxy(
    request: Request,
    path: str,
    token_data: Dict = Depends(validate_token),
):
    """Proxy requests to the user endpoints with token validation"""
    response = await proxy_request(
        request,
        USER_AUTH_SERVICE_URL,
        f"user/{path}",
        token_data,
    )

    return Response(
        content=response.content,
        status_code=response.status_code,
        headers=response.headers,
    )


# Event Ticketing Service Routes
@app.get("/api/events")
async def get_events_list(
    request: Request,
    token_data: Optional[Dict] = Depends(validate_token),
):
    """Proxy GET requests to the events listing endpoint"""
    response = await proxy_request(
        request,
        EVENT_TICKETING_SERVICE_URL,
        "events",
        token_data,
    )

    return Response(
        content=response.content,
        status_code=response.status_code,
        headers=response.headers,
    )


@app.api_route("/api/events/{path:path}", methods=["GET", "POST", "PUT", "DELETE"])
async def events_proxy(
    request: Request,
    path: str,
    token_data: Optional[Dict] = Depends(validate_token),
):
    """Proxy requests to the events endpoints"""
    response = await proxy_request(
        request,
        EVENT_TICKETING_SERVICE_URL,
        f"events/{path}",
        token_data,
    )

    return Response(
        content=response.content,
        status_code=response.status_code,
        headers=response.headers,
    )


@app.get("/api/tickets")
async def get_tickets_list(
    request: Request,
    token_data: Optional[Dict] = Depends(validate_token),
):
    """Proxy GET requests to the tickets listing endpoint"""
    response = await proxy_request(
        request,
        EVENT_TICKETING_SERVICE_URL,
        "tickets",
        token_data,
    )

    return Response(
        content=response.content,
        status_code=response.status_code,
        headers=response.headers,
    )


@app.api_route("/api/tickets/{path:path}", methods=["GET", "POST", "PUT", "DELETE"])
async def tickets_proxy(
    request: Request,
    path: str,
    token_data: Optional[Dict] = Depends(validate_token),
):
    """Proxy requests to the tickets endpoints"""
    response = await proxy_request(
        request,
        EVENT_TICKETING_SERVICE_URL,
        f"tickets/{path}",
        token_data,
    )

    return Response(
        content=response.content,
        status_code=response.status_code,
        headers=response.headers,
    )


@app.get("/api/ticket-types")
async def get_ticket_types_list(
    request: Request,
    token_data: Optional[Dict] = Depends(validate_token),
):
    """Proxy GET requests to the ticket types listing endpoint"""
    response = await proxy_request(
        request,
        EVENT_TICKETING_SERVICE_URL,
        "ticket-types",
        token_data,
    )

    return Response(
        content=response.content,
        status_code=response.status_code,
        headers=response.headers,
    )


@app.api_route("/api/ticket-types/{path:path}", methods=["GET", "POST", "PUT", "DELETE"])
async def ticket_types_proxy(
    request: Request,
    path: str,
    token_data: Optional[Dict] = Depends(validate_token),
):
    """Proxy requests to the ticket types endpoints"""
    response = await proxy_request(
        request,
        EVENT_TICKETING_SERVICE_URL,
        f"ticket-types/{path}",
        token_data,
    )

    return Response(
        content=response.content,
        status_code=response.status_code,
        headers=response.headers,
    )


@app.get("/api/cart/items")
async def get_cart_items(
    request: Request,
    token_data: Dict = Depends(validate_token),
):
    """Proxy GET requests to the cart items endpoint (requires authentication)"""
    if not token_data:
        raise HTTPException(
            status_code=401,
            detail="Authentication required",
        )

    response = await proxy_request(
        request,
        EVENT_TICKETING_SERVICE_URL,
        "cart/items",
        token_data,
    )

    return Response(
        content=response.content,
        status_code=response.status_code,
        headers=response.headers,
    )


@app.api_route("/api/cart/{path:path}", methods=["GET", "POST", "PUT", "DELETE"])
async def cart_proxy(
    request: Request,
    path: str,
    token_data: Dict = Depends(validate_token),
):
    """Proxy requests to the cart endpoints (requires authentication)"""
    if not token_data:
        raise HTTPException(
            status_code=401,
            detail="Authentication required",
        )

    response = await proxy_request(
        request,
        EVENT_TICKETING_SERVICE_URL,
        f"cart/{path}",
        token_data,
    )

    return Response(
        content=response.content,
        status_code=response.status_code,
        headers=response.headers,
    )


@app.get("/")
async def root():
    """Root endpoint with API info"""
    return {
        "service": "Resellio API Gateway",
        "version": "1.0.0",
        "available_endpoints": [
            "/api/auth/*",
            "/api/user/*",
            "/api/events/*",
            "/api/tickets/*",
            "/api/ticket-types/*",
            "/api/cart/*",
        ],
    }


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8080,
        reload=True,
    )
