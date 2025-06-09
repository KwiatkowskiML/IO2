from typing import Union
from app.models import User, Organiser
from app.database import get_db
from sqlalchemy.orm import Session
from app.security import get_current_user
from sqlalchemy.exc import IntegrityError
from app.schemas.user import UserResponse, UserProfileUpdate, OrganizerResponse
from fastapi import Depends, APIRouter, HTTPException, status

router = APIRouter(prefix="/user", tags=["user"])


@router.get("/me", response_model=Union[OrganizerResponse, UserResponse])
def read_users_me(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """Get current user's profile information"""
    if current_user.user_type == "organiser":
        organiser = db.query(Organiser).filter(Organiser.user_id == current_user.user_id).first()
        if not organiser:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Organiser record not found for this user")

        # The ORM object for a user doesn't contain the organiser-specific fields directly,
        # so we must construct the response model instance manually with all required fields.
        return OrganizerResponse(
            user_id=current_user.user_id,
            email=current_user.email,
            login=current_user.login,
            first_name=current_user.first_name,
            last_name=current_user.last_name,
            user_type=current_user.user_type,
            is_active=current_user.is_active,
            organiser_id=organiser.organiser_id,
            company_name=organiser.company_name,
            is_verified=organiser.is_verified,
        )

    # For customers and admins, returning the ORM object works because the fixed
    # UserResponse schema can now be populated correctly.
    return current_user


@router.put("/update-profile", response_model=UserResponse)
def update_user_profile(
    user_update: UserProfileUpdate, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)
):
    """Update current user's profile information"""
    try:
        if user_update.first_name is not None:
            current_user.first_name = user_update.first_name
        if user_update.last_name is not None:
            current_user.last_name = user_update.last_name
        if user_update.login is not None and user_update.login != current_user.login:
            existing_login = db.query(User).filter(User.login == user_update.login).first()
            if existing_login:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Login already taken",
                )
            current_user.login = user_update.login

        db.commit()
        db.refresh(current_user)

        return current_user

    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="Profile update failed due to database error"
        )


@router.get("/{user_id}", response_model=UserResponse)
def get_user_by_id(user_id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    user = db.query(User).filter(User.user_id == user_id).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found",
        )

    response = UserResponse.from_orm(user)

    # Remove login if requester is not an admin or the user themselves
    is_admin = current_user.user_type == "administrator"
    is_same_user = current_user.user_id == user.user_id

    if not (is_admin or is_same_user):
        response.login = None

    return response
