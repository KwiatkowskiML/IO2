import os
import logging
from typing import Dict, Optional

import jwt
from fastapi import Header, HTTPException, status

# JWT Configuration
SECRET_KEY = os.getenv("SECRET_KEY", "your-256-bit-secret")
ALGORITHM = os.getenv("ALGORITHM", "HS256")

print(f"Secret: {SECRET_KEY}")

logger = logging.getLogger(__name__)


def decode_jwt(
    token: str,
) -> Dict:
    """
    Decode a JWT token and return the payload

    Args:
        token: JWT token string

    Returns:
        Dict containing decoded token claims

    Raises:
        HTTPException: If token is invalid
    """
    try:
        payload = jwt.decode(
            token,
            SECRET_KEY,
            algorithms=[ALGORITHM],
        )
        return payload
    except jwt.ExpiredSignatureError:
        logger.error("Token has expired")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token has expired",
        )
    except jwt.InvalidTokenError as e:
        logger.error(f"Invalid token: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token",
        )


def get_token_from_header(
    authorization: Optional[str],
) -> str:
    """
    Extract JWT token from authorization header

    Args:
        authorization: Authorization header string

    Returns:
        JWT token

    Raises:
        HTTPException: If authorization header is missing or invalid
    """
    if not authorization:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authorization header is required",
        )

    parts = authorization.split()

    if parts[0].lower() != "bearer":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authorization header must start with Bearer",
        )

    if len(parts) == 1:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token not found",
        )

    if len(parts) > 2:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authorization header must be Bearer {token}",
        )

    return parts[1]


def get_user_from_token(
    authorization: Optional[str] = Header(None),
) -> Dict:
    """
    Extract user information from JWT token

    Args:
        authorization: Authorization header

    Returns:
        Dict with user information

    Raises:
        HTTPException: If token is invalid or user info is missing
    """
    if not authorization:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authorization required",
        )

    token = get_token_from_header(authorization)
    print(token)
    payload = decode_jwt(token)
    print(payload)

    # Extract user information
    user_id = payload.get("user_id")
    email = payload.get("sub")
    name = payload.get("name")

    # Validate required fields
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User ID not found in token",
        )

    if not email:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Email not found in token",
        )

    # Name can be optional, use email username as fallback
    if not name:
        name = email.split("@")[0]

    return {
        "user_id": user_id,
        "email": email,
        "name": name,
    }
