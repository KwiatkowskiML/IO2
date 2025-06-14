import os
import secrets
from typing import Optional
from datetime import datetime, timezone, timedelta

import jwt
from app.database import get_db
from sqlalchemy.orm import Session
from passlib.context import CryptContext
from fastapi.security import OAuth2PasswordBearer
from fastapi import Depends, HTTPException, status
from app.models import User, Organizer, Administrator

# Get security settings from environment variables or use defaults
SECRET_KEY = os.getenv("SECRET_KEY", "your-256-bit-secret")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "30"))
ADMIN_SECRET_KEY = os.getenv("ADMIN_SECRET_KEY", "admin-secret-key")

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/auth/token")

def decode_token(token: str):
    """Decode a JWT token and return the payload"""
    return jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])


def get_token_data(token: str = Depends(oauth2_scheme)):
    """Extract and validate data from the JWT token"""
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        email: str = payload.get("sub")
        role: str = payload.get("role")
        if email is None:
            raise credentials_exception
        return {"email": email, "role": role}
    except jwt.PyJWTError:
        raise credentials_exception


def verify_password(plain_password, hashed_password):
    """Verify that the plain password matches the hashed password"""
    return pwd_context.verify(plain_password, hashed_password)


def get_password_hash(password):
    """Generate a bcrypt hash for the given password"""
    return pwd_context.hash(password)


def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    """Create a JWT access token with an optional expiration"""
    to_encode = data.copy()

    if expires_delta:
        expire = datetime.now(timezone.utc) + expires_delta
    else:
        expire = datetime.now(timezone.utc) + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)

    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt


def generate_reset_token():
    """Generate a random token for password reset"""
    return secrets.token_urlsafe(32)


def get_current_user(token_data: dict = Depends(get_token_data), db: Session = Depends(get_db)):
    """Get the current user based on the JWT token"""
    user = db.query(User).filter(User.email == token_data["email"]).first()
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")
    if not user.is_active:
        raise HTTPException(status_code=403, detail="Account banned")
    return user


def get_current_active_user(current_user: User = Depends(get_current_user)):
    """Check if the current user is active"""
    if not current_user.is_active:
        raise HTTPException(status_code=400, detail="Inactive user")
    return current_user


def get_current_organizer(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """Check if the current user is a verified organizer"""
    if current_user.user_type != "organizer":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not an organizer")

    organizer = db.query(Organizer).filter(Organizer.user_id == current_user.user_id).first()
    if not organizer or not organizer.is_verified:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Organizer not verified yet")

    return current_user


def get_current_admin(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """Check if the current user is an administrator"""
    if current_user.user_type != "administrator":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not an administrator")

    admin = db.query(Administrator).filter(Administrator.user_id == current_user.user_id).first()
    if not admin:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not an administrator")

    return current_user


def verify_admin_secret(admin_secret_key: str):
    """Verify that the admin secret key is correct"""
    if admin_secret_key != ADMIN_SECRET_KEY:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Invalid admin secret key")
    return True
