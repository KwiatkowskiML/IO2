"""
Fixed auth.py - Addresses admin banning and initial admin security issues
"""

import logging
from typing import List, Optional
from datetime import datetime, timedelta

from app.database import get_db
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError
from fastapi.security import OAuth2PasswordRequestForm

from app.repositories.auth_repository import AuthRepository
from app.schemas.user import UserResponse, OrganizerResponse
from app.models import User, Customer, Organizer, Administrator
from fastapi import Depends, APIRouter, HTTPException, BackgroundTasks, status, Query
from sqlalchemy import and_, or_
from app.security import INITIAL_ADMIN_EMAIL

from app.schemas.auth import (
    Token,
    UserCreate,
    AdminCreate,
    PasswordReset,
    OrganizerCreate,
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
    verify_initial_admin_credentials,
)
from app.services.email_service import send_account_verification_email

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/auth", tags=["authentication"])


@router.post("/register/customer", status_code=status.HTTP_201_CREATED)
def register_customer(
        user: UserCreate,
        background_tasks: BackgroundTasks,
        db: Session = Depends(get_db),
):
    """Register a new customer account"""

    if user.email == INITIAL_ADMIN_EMAIL:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="This email address is reserved and cannot be used for registration",
        )

    # Check if email already exists
    new_user = db.query(User).filter(User.email == user.email).first()
    if new_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered",
        )

    # Check if login already exists
    db_login = db.query(User).filter(User.login == user.login).first()
    if db_login:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Login already taken",
        )

    try:
        # Create new user with hashed password
        hashed_password = get_password_hash(user.password)
        new_user = User(
            email=user.email,
            login=user.login,
            password_hash=hashed_password,
            first_name=user.first_name,
            last_name=user.last_name,
            user_type="customer",
            is_active=False,  # User is inactive until email verification
        )
        new_user.set_email_verification_token()

        db.add(new_user)
        db.flush()  # Flush to get the user_id without committing

        # Create customer record
        db_customer = Customer(user_id=new_user.user_id)
        db.add(db_customer)

        db.commit()
        db.refresh(new_user)

        # Send verification email in the background
        background_tasks.add_task(
            send_account_verification_email,
            to_email=new_user.email,
            user_name=new_user.first_name,
            verification_token=new_user.email_verification_token
        )

        return {
            "message": "User registered successfully. Please check your email to activate your account.",
            "user_id": new_user.user_id}

    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST,
                            detail="Registration failed due to database error")
    except Exception as e:
        db.rollback()
        logger.error(f"Unexpected error during customer registration: {e}", exc_info=True)
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST,
                            detail="Registration failed due to database error")


@router.post("/register/organizer", response_model=Token, status_code=status.HTTP_201_CREATED)
def register_organizer(user: OrganizerCreate, db: Session = Depends(get_db)):
    """Register a new organizer account (requires verification)"""
    try:
        # Check if email already exists
        db_user = db.query(User).filter(User.email == user.email).first()
        if db_user:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST,
                                detail="Email already registered")

        # Check if login already exists
        db_login = db.query(User).filter(User.login == user.login).first()
        if db_login:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST,
                                detail="Login already taken")

        # Create new user with hashed password
        hashed_password = get_password_hash(user.password)
        db_user = User(
            email=user.email,
            login=user.login,
            password_hash=hashed_password,
            first_name=user.first_name,
            last_name=user.last_name,
            user_type="organizer",
            is_active=True,
        )

        db.add(db_user)
        db.flush()  # Flush to get the user_id without committing

        # Create organizer record
        db_organizer = Organizer(user_id=db_user.user_id, company_name=user.company_name,
                                 is_verified=False)
        db.add(db_organizer)

        db.commit()
        db.refresh(db_user)

        # Generate a token even though the account is not verified
        # This can be used for initial login to check verification status
        access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
        access_token = create_access_token(
            data={
                "sub": user.email,
                "role": db_user.user_type,
                "user_id": db_user.user_id,
                "role_id": db_organizer.organizer_id,
                "name": user.first_name,
            },
            expires_delta=access_token_expires,
        )

        return {
            "token": access_token,
            "message": "Organizer registered successfully, awaiting administrator verification",
        }

    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST,
                            detail="Registration failed due to database error")


@router.post("/register/admin", response_model=Token, status_code=status.HTTP_201_CREATED)
def register_admin(
        user: AdminCreate,
        db: Session = Depends(get_db),
        current_admin: User = Depends(get_current_admin)
):
    """Register a new administrator account (requires existing admin authentication)"""
    # Verify admin secret key (additional security layer)
    verify_admin_secret(user.admin_secret_key)

    try:
        # Check if email already exists
        db_user = db.query(User).filter(User.email == user.email).first()
        if db_user:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST,
                                detail="Email already registered")

        # Check if login already exists
        db_login = db.query(User).filter(User.login == user.login).first()
        if db_login:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST,
                                detail="Login already taken")

        # Create new admin with hashed password
        hashed_password = get_password_hash(user.password)
        db_user = User(
            email=user.email,
            login=user.login,
            password_hash=hashed_password,
            first_name=user.first_name,
            last_name=user.last_name,
            user_type="administrator",
            is_active=True,
        )

        db.add(db_user)
        db.flush()  # Flush to get the user_id without committing

        # Create administrator record
        db_admin = Administrator(user_id=db_user.user_id)
        db.add(db_admin)

        db.commit()
        db.refresh(db_user)

        # Generate access token
        access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
        access_token = create_access_token(
            data={
                "sub": user.email,
                "role": db_user.user_type,
                "user_id": db_user.user_id,
                "role_id": db_admin.admin_id,
                "name": user.first_name,
            },
            expires_delta=access_token_expires,
        )

        return {"token": access_token, "message": "Administrator registered successfully"}

    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST,
                            detail="Registration failed due to database error")


@router.post("/token", response_model=Token)
def login_for_access_token(form_data: OAuth2PasswordRequestForm = Depends(),
                           db: Session = Depends(get_db)):
    """Login endpoint that exchanges username (email) and password for an access token"""

    user = db.query(User).filter(User.email == form_data.username).first()

    if not user and verify_initial_admin_credentials(form_data.username, form_data.password):
        # Create the initial admin user since it doesn't exist
        hashed_password = get_password_hash(form_data.password)
        admin_user = User(
            email=form_data.username,
            login="initial_admin",
            password_hash=hashed_password,
            first_name="Initial",
            last_name="Admin",
            user_type="administrator",
            is_active=True,
        )

        db.add(admin_user)
        db.flush()

        # Create administrator record
        admin_record = Administrator(user_id=admin_user.user_id)
        db.add(admin_record)

        db.commit()
        db.refresh(admin_user)
        db.refresh(admin_record)

        # Generate access token for initial admin
        access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
        access_token = create_access_token(
            data={
                "sub": admin_user.email,
                "role": admin_user.user_type,
                "user_id": admin_user.user_id,
                "role_id": admin_record.admin_id,
                "name": admin_user.first_name,
            },
            expires_delta=access_token_expires,
        )

        return {"token": access_token, "message": "Login successful"}

    if not user or not verify_password(form_data.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # Check if the user is active
    if not user.is_active:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Account banned")

    role_id = None

    # Check if the organizer is verified
    if user.user_type == "organizer":
        organizer = db.query(Organizer).filter(Organizer.user_id == user.user_id).first()
        role_id = organizer.organizer_id
        if not organizer.is_verified:
            return {"token": "",
                    "message": "Your account is pending verification by an administrator"}

    if user.user_type == "administrator":
        role_id = db.query(Administrator).filter(
            Administrator.user_id == user.user_id).first().admin_id
    elif user.user_type == "customer":
        role_id = db.query(Customer).filter(Customer.user_id == user.user_id).first().customer_id

    if role_id is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Incorrect user role")

    # Generate access token
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={
            "sub": user.email,
            "role": user.user_type,
            "user_id": user.user_id,
            "role_id": role_id,
            "name": user.first_name,
        },
        expires_delta=access_token_expires,
    )

    return {"token": access_token, "message": "Login successful"}


@router.post("/logout")
def logout():
    """Logout (client should discard the token)"""
    return {"message": "Logout successful"}


@router.post("/verify-organizer", response_model=OrganizerResponse)
def verify_organizer(
        verification: VerificationRequest, db: Session = Depends(get_db),
        admin: User = Depends(get_current_admin)
):
    """Verify or reject an organizer account (admin only)"""
    # Find the organizer
    organizer = db.query(Organizer).filter(
        Organizer.organizer_id == verification.organizer_id).first()

    if not organizer:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Organizer not found")

    # Find the associated user
    user = db.query(User).filter(User.user_id == organizer.user_id).first()

    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

    if verification.approve:
        organizer.is_verified = True
    else:
        # If rejected, we keep the account but mark it as inactive
        user.is_active = False

    db.commit()
    db.refresh(organizer)
    db.refresh(user)

    # Combine user and organizer for response
    user_dict = {c.name: getattr(user, c.name) for c in user.__table__.columns}
    user_dict["organizer_id"] = organizer.organizer_id
    user_dict["company_name"] = organizer.company_name
    user_dict["is_verified"] = organizer.is_verified

    return user_dict


@router.get("/pending-organizers", response_model=List[OrganizerResponse])
def list_pending_organizers(db: Session = Depends(get_db),
                            admin: User = Depends(get_current_admin)):
    """List all organizers pending verification (admin only)"""
    # Join User and Organizer tables to get all unverified organizers
    unverified_organizers = (
        db.query(User, Organizer)
        .join(Organizer, User.user_id == Organizer.user_id)
        .filter(User.user_type == "organizer", ~Organizer.is_verified, User.is_active)
        .all()
    )

    # Format the response
    result = []
    for user, organizer in unverified_organizers:
        user_dict = {c.name: getattr(user, c.name) for c in user.__table__.columns}
        user_dict["organizer_id"] = organizer.organizer_id
        user_dict["company_name"] = organizer.company_name
        user_dict["is_verified"] = organizer.is_verified
        result.append(user_dict)

    return result


@router.post("/request-password-reset")
def request_password_reset(
        reset_request: PasswordReset, background_tasks: BackgroundTasks,
        db: Session = Depends(get_db)
):
    """Request a password reset link via email"""
    user = db.query(User).filter(User.email == reset_request.email).first()

    if not user:
        return {"message": "If your email is registered, you will receive a password reset link"}

    reset_token = generate_reset_token()  # noqa
    token_expiry = datetime.utcnow() + timedelta(hours=24)  # noqa

    # TODO: Store token in user's session - and look it up in the table (make a new table for tokens?)

    return {"message": "Password reset not supported. Contact our administrators."}


@router.post("/reset-password")
def reset_password(reset_confirm: PasswordResetConfirm, db: Session = Depends(get_db)):
    """Reset password using a valid reset token"""
    # TODO
    return {"message": "Password reset functionality not implemented. Contact administrators."}


@router.post("/ban-user/{user_id}")
def ban_user(user_id: int, db: Session = Depends(get_db), admin: User = Depends(get_current_admin)):
    """Ban a user (admin only) - FIXED: Prevent banning other admins"""
    # Find the user
    user = db.query(User).filter(User.user_id == user_id).first()

    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

    if user.user_type == "administrator":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Cannot ban administrator accounts"
        )

    if user.user_id == admin.user_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot ban yourself"
        )

    user.is_active = False
    db.commit()

    return {"message": "User has been banned"}


@router.post("/unban-user/{user_id}")
def unban_user(user_id: int, db: Session = Depends(get_db),
               admin: User = Depends(get_current_admin)):
    """Unban a user (admin only)"""
    user = db.query(User).filter(User.user_id == user_id).first()

    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

    if user.is_active:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="User is not banned")

    user.is_active = True
    db.commit()

    return {"message": "User has been unbanned"}


@router.get("/verify-email", response_model=Token, summary="Verify Email Address")
async def verify_email_address(
        token: str = Query(...,
                           description="The email verification token sent to the user's email address"),
        db: Session = Depends(get_db)
):
    """
    Verify a user's email address using the token from the verification email.
    If successful, activates the user and returns an access token for immediate login.
    """
    auth_repo = AuthRepository(db)
    return auth_repo.verify_email_and_generate_token(verification_token=token)


@router.post("/approve-user/{user_id}")
def approve_user(user_id: int, db: Session = Depends(get_db),
                 admin: User = Depends(get_current_admin)):
    """Approve user (admin only)"""
    user = db.query(User).filter(User.user_id == user_id).first()

    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

    if user.is_active:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="User is active")

    auth_repo = AuthRepository(db)
    return auth_repo.verify_email_and_generate_token(
        verification_token=user.email_verification_token)


@router.get("/users", response_model=List[OrganizerResponse])
def list_users(
        page: int = Query(1, ge=1, description="Page number"),
        limit: int = Query(50, ge=1, le=100, description="Items per page"),
        search: Optional[str] = Query(None,
                                      description="Search by email, login, first_name, or last_name"),
        user_type: Optional[str] = Query(None,
                                         description="Filter by user type (customer, organizer, administrator)"),
        is_active: Optional[bool] = Query(None, description="Filter by active status"),
        is_verified: Optional[bool] = Query(None,
                                            description="Filter by verification status (organizers only)"),
        sort_by: str = Query("creation_date", description="Sort field"),
        sort_order: str = Query("desc", description="Sort order (asc/desc)"),
        db: Session = Depends(get_db),
        admin: User = Depends(get_current_admin)
):
    query = db.query(User).outerjoin(Organizer, User.user_id == Organizer.user_id)

    if search:
        search_filter = f"%{search}%"
        query = query.filter(
            or_(
                User.email.ilike(search_filter),
                User.login.ilike(search_filter),
                User.first_name.ilike(search_filter),
                User.last_name.ilike(search_filter)
            )
        )

    if user_type:
        if user_type not in ["customer", "organizer", "administrator"]:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid user_type. Must be one of: customer, organizer, administrator"
            )
        query = query.filter(User.user_type == user_type)

    if is_active is not None:
        query = query.filter(User.is_active == is_active)

    if is_verified is not None:
        query = query.filter(
            and_(
                User.user_type == "organizer",
                Organizer.is_verified == is_verified
            )
        )

    if sort_by not in ["creation_date", "email", "first_name", "last_name", "user_type"]:
        sort_by = "creation_date"

    if sort_order.lower() == "asc":
        query = query.order_by(getattr(User, sort_by).asc())
    else:
        query = query.order_by(getattr(User, sort_by).desc())

    offset = (page - 1) * limit
    users = query.offset(offset).limit(limit).all()

    result = []
    for user in users:
        user_response = OrganizerResponse(
            user_id=user.user_id,
            email=user.email,
            login=user.login,
            first_name=user.first_name,
            last_name=user.last_name,
            user_type=user.user_type,
            is_active=user.is_active
        )

        if user.user_type == "organizer" and user.organizer:
            organizer_response = OrganizerResponse(
                user_id=user.user_id,
                email=user.email,
                login=user.login,
                first_name=user.first_name,
                last_name=user.last_name,
                user_type=user.user_type,
                is_active=user.is_active,
                organizer_id=user.organizer.organizer_id,
                company_name=user.organizer.company_name,
                is_verified=user.organizer.is_verified
            )
            result.append(organizer_response)
        else:
            result.append(user_response)

    return result


@router.get("/users/stats")
def get_user_stats(
        db: Session = Depends(get_db),
        admin: User = Depends(get_current_admin)
):
    total_users = db.query(User).count()
    active_users = db.query(User).filter(User.is_active == True).count()
    banned_users = db.query(User).filter(User.is_active == False).count()

    customers = db.query(User).filter(User.user_type == "customer").count()
    organizers = db.query(User).filter(User.user_type == "organizer").count()
    administrators = db.query(User).filter(User.user_type == "administrator").count()

    verified_organizers = db.query(Organizer).filter(Organizer.is_verified == True).count()
    pending_organizers = db.query(Organizer).filter(Organizer.is_verified == False).count()

    return {
        "total_users": total_users,
        "active_users": active_users,
        "banned_users": banned_users,
        "users_by_type": {
            "customers": customers,
            "organizers": organizers,
            "administrators": administrators
        },
        "organizer_stats": {
            "verified": verified_organizers,
            "pending": pending_organizers
        }
    }


@router.get("/users/{user_id}", response_model=OrganizerResponse)
def get_user_details(
        user_id: int,
        db: Session = Depends(get_db),
        admin: User = Depends(get_current_admin)
):
    user = db.query(User).filter(User.user_id == user_id).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )

    if user.user_type == "organizer":
        organizer = db.query(Organizer).filter(Organizer.user_id == user.user_id).first()
        if organizer:
            return OrganizerResponse(
                user_id=user.user_id,
                email=user.email,
                login=user.login,
                first_name=user.first_name,
                last_name=user.last_name,
                user_type=user.user_type,
                is_active=user.is_active,
                organizer_id=organizer.organizer_id,
                company_name=organizer.company_name,
                is_verified=organizer.is_verified
            )

    return UserResponse(
        user_id=user.user_id,
        email=user.email,
        login=user.login,
        first_name=user.first_name,
        last_name=user.last_name,
        user_type=user.user_type,
        is_active=user.is_active
    )