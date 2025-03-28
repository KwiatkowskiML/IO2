import uvicorn
from app.routers import auth
from app.database import engine
from app.models.user import Base
from fastapi import Depends, FastAPI
from app.security import get_current_user
from fastapi.middleware.cors import CORSMiddleware

Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Resellio Auth Service",
    description="Authentication microservice for Resellio ticket selling platform",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # For production, restrict this to specific origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)


@app.get("/")
def read_root():
    """Root endpoint to verify service is running"""
    return {
        "service": "Resellio Auth Service",
        "status": "operational",
        "version": "0.0.1",
    }


@app.get("/health")
def health_check():
    """Health check endpoint for monitoring"""
    return {"status": "healthy"}


@app.get("/protected")
def protected_route(user=Depends(get_current_user)):
    """Test endpoint to verify authentication is working"""
    return {"message": "This is a protected route", "user_id": user.user_id, "email": user.email, "role": user.role}


if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
