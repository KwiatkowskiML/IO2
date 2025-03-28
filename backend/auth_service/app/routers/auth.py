# auth_service/app/routers/auth.py
from typing import List
from datetime import datetime, timedelta

from app.database import get_db
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError
from app.models.user import User, UserRole, UserStatus
from fastapi.security import OAuth2PasswordRequestForm
from fastapi import Depends, APIRouter, HTTPException, BackgroundTasks, status
from app.schemas.auth import (
    Token,
    UserCreate,
    AdminCreate,
    UserResponse,
    PasswordReset,
    OrganizerCreate,
    OrganizerResponse,
    VerificationRequest,
    PasswordResetConfirm,
)
from app.security import (
    ACCESS_TOKEN_EXPIRE_MINUTES,
    verify_password,
    get_current_user,
    get_current_admin,
    get_password_hash,
    create_access_token,
    verify_admin_secret,
    generate_reset_token,
)

# Future import for email sending functionality
# from app.services.email import send_password_reset_email, send_verification_email

router = APIRouter(prefix="/auth", tags=["authentication"])


@router.post("/register/customer", response_model=Token, status_code=status.HTTP_201_CREATED)
def register_customer(user: UserCreate, db: Session = Depends(get_db)):
    """Register a new customer account"""
    try:
        # Check if email already exists
        db_user = db.query(User).filter(User.email == user.email).first()
        if db_user:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Email already registered")

        # Check if login already exists
        db_login = db.query(User).filter(User.login == user.login).first()
        if db_login:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Login already taken")

        # Create new user with hashed password
        hashed_password = get_password_hash(user.password)
        db_user = User(
            email=user.email,
            login=user.login,
            password_hash=hashed_password,
            first_name=user.first_name,
            last_name=user.last_name,
            role=UserRole.CUSTOMER,
            status=UserStatus.ACTIVE,
        )

        db.add(db_user)
        db.commit()
        db.refresh(db_user)

        # Generate access token
        access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
        access_token = create_access_token(
            data={"sub": db_user.email, "role": db_user.role.value}, expires_delta=access_token_expires
        )

        return {"token": access_token, "message": "User registered successfully"}

    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Registration failed due to database error")


@router.post("/register/organizer", response_model=Token, status_code=status.HTTP_201_CREATED)
def register_organizer(user: OrganizerCreate, db: Session = Depends(get_db)):
    """Register a new organizer account (requires verification)"""
    try:
        # Check if email already exists
        db_user = db.query(User).filter(User.email == user.email).first()
        if db_user:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Email already registered")

        # Check if login already exists
        db_login = db.query(User).filter(User.login == user.login).first()
        if db_login:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Login already taken")

        # Create new organizer with hashed password
        hashed_password = get_password_hash(user.password)
        db_user = User(
            email=user.email,
            login=user.login,
            password_hash=hashed_password,
            first_name=user.first_name,
            last_name=user.last_name,
            role=UserRole.ORGANIZER,
            status=UserStatus.VERIFICATION_PENDING,
            company_name=user.company_name,
            is_verified=False,
        )

        db.add(db_user)
        db.commit()
        db.refresh(db_user)

        # Generate a token even though the account is not verified
        # This can be used for initial login to check verification status
        access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
        access_token = create_access_token(
            data={"sub": db_user.email, "role": db_user.role.value}, expires_delta=access_token_expires
        )

        return {
            "token": access_token,
            "message": "Organizer registered successfully, awaiting administrator verification",
        }

    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Registration failed due to database error")


@router.post("/register/admin", response_model=Token, status_code=status.HTTP_201_CREATED)
def register_admin(user: AdminCreate, db: Session = Depends(get_db)):
    """Register a new administrator account (requires admin secret key)"""
    # Verify admin secret key
    verify_admin_secret(user.admin_secret_key)

    try:
        # Check if email already exists
        db_user = db.query(User).filter(User.email == user.email).first()
        if db_user:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Email already registered")

        # Check if login already exists
        db_login = db.query(User).filter(User.login == user.login).first()
        if db_login:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Login already taken")

        # Create new admin with hashed password
        hashed_password = get_password_hash(user.password)
        db_user = User(
            email=user.email,
            login=user.login,
            password_hash=hashed_password,
            first_name=user.first_name,
            last_name=user.last_name,
            role=UserRole.ADMINISTRATOR,
            status=UserStatus.ACTIVE,
        )

        db.add(db_user)
        db.commit()
        db.refresh(db_user)

        # Generate access token
        access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
        access_token = create_access_token(
            data={"sub": db_user.email, "role": db_user.role.value}, expires_delta=access_token_expires
        )

        return {"token": access_token, "message": "Administrator registered successfully"}

    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Registration failed due to database error")


@router.post("/token", response_model=Token)
def login_for_access_token(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    """Login endpoint that exchanges username (email) and password for an access token"""
    # Find the user
    user = db.query(User).filter(User.email == form_data.username).first()
    if not user or not verify_password(form_data.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # Check if the user is banned
    if user.status == UserStatus.BANNED:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Account banned")

    # Check if the organizer is verified
    if user.role == UserRole.ORGANIZER and user.status == UserStatus.VERIFICATION_PENDING:
        return {"token": "", "message": "Your account is pending verification by an administrator"}

    # Generate access token
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.email, "role": user.role.value}, expires_delta=access_token_expires
    )

    return {"token": access_token, "message": "Login successful"}


@router.post("/logout")
def logout():
    """Logout (client should discard the token)"""
    return {"message": "Logout successful"}


@router.get("/me", response_model=UserResponse)
def read_users_me(current_user: User = Depends(get_current_user)):
    """Get current user information"""
    return current_user


@router.post("/verify-organizer", response_model=OrganizerResponse)
def verify_organizer(
    verification: VerificationRequest, db: Session = Depends(get_db), admin: User = Depends(get_current_admin)
):
    """Verify or reject an organizer account (admin only)"""
    # Find the organizer
    organizer = db.query(User).filter(User.id == verification.organizer_id, User.role == UserRole.ORGANIZER).first()

    if not organizer:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Organizer not found")

    if verification.approve:
        organizer.status = UserStatus.ACTIVE
        organizer.is_verified = True
    else:
        # If rejected, we keep the account but mark it as banned
        organizer.status = UserStatus.BANNED

    db.commit()
    db.refresh(organizer)

    return organizer


@router.get("/pending-organizers", response_model=List[OrganizerResponse])
def list_pending_organizers(db: Session = Depends(get_db), admin: User = Depends(get_current_admin)):
    """List all organizers pending verification (admin only)"""
    organizers = (
        db.query(User).filter(User.role == UserRole.ORGANIZER, User.status == UserStatus.VERIFICATION_PENDING).all()
    )

    return organizers


@router.post("/request-password-reset")
def request_password_reset(
    reset_request: PasswordReset, background_tasks: BackgroundTasks, db: Session = Depends(get_db)
):
    """Request a password reset link via email"""
    user = db.query(User).filter(User.email == reset_request.email).first()

    # Even if user doesn't exist, return success to prevent email enumeration
    if not user:
        return {"message": "If your email is registered, you will receive a password reset link"}

    reset_token = generate_reset_token()

    # Set token expiry (24 hours)
    token_expiry = datetime.utcnow() + timedelta(hours=24)

    user.token = reset_token
    user.token_expiry = token_expiry
    db.commit()

    # Send email with reset token
    # when email service is implemented
    return {"message": "Password reset not supported. Contact our administators."}


@router.post("/reset-password")
def reset_password(reset_confirm: PasswordResetConfirm, db: Session = Depends(get_db)):
    """Reset password using a valid reset token"""
    user = db.query(User).filter(User.token == reset_confirm.token).first()

    if not user or not user.token_expiry or user.token_expiry < datetime.utcnow():
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid or expired reset token")

    user.password_hash = get_password_hash(reset_confirm.new_password)

    user.token = None
    user.token_expiry = None

    db.commit()

    return {"message": "Password has been reset successfully"}


@router.post("/ban-user/{user_id}")
def ban_user(user_id: int, db: Session = Depends(get_db), admin: User = Depends(get_current_admin)):
    """Ban a user (admin only)"""
    # Find the user
    user = db.query(User).filter(User.id == user_id).first()

    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

    user.status = UserStatus.BANNED
    db.commit()

    return {"message": "User has been banned"}


@router.post("/unban-user/{user_id}")
def unban_user(user_id: int, db: Session = Depends(get_db), admin: User = Depends(get_current_admin)):
    """Unban a user (admin only)"""
    user = db.query(User).filter(User.id == user_id).first()

    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

    if user.status != UserStatus.BANNED:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="User is not banned")

    user.status = UserStatus.ACTIVE
    db.commit()

    return {"message": "User has been unbanned"}
