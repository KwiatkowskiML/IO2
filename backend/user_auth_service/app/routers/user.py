from app.models import User
from app.database import get_db
from sqlalchemy.orm import Session
from app.security import get_current_user
from sqlalchemy.exc import IntegrityError
from app.schemas.user import UserResponse, UserProfileUpdate
from fastapi import Depends, APIRouter, HTTPException, status

router = APIRouter(prefix="/user", tags=["user"])


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

        return get_current_user()

    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="Profile update failed due to database error"
        )


@router.get("/profile/{user_id}", response_model=UserResponse)
def get_user_by_id(user_id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    user = db.query(User).filter(User.user_id == user_id).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found",
        )

    response = UserResponse(
        user_id=user.user_id,
        email=user.email,
        login=user.login,
        first_name=user.first_name,
        last_name=user.last_name,
    )

    # Remove login if requester is not an admin or the user themselves
    is_admin = current_user.user_type == "administrator"
    is_same_user = current_user.user_id == user.user_id

    if not (is_admin or is_same_user):
        response.login = None

    return response


@router.get("/me", response_model=UserResponse)
def read_users_me(current_user: User = Depends(get_current_user)):
    """Get current user information"""
    return current_user
