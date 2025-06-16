import logging
from datetime import timedelta

from sqlalchemy.orm import Session
from fastapi import HTTPException, status, Depends

from app.models import User, Customer
from app.database import get_db
from app.security import create_access_token, ACCESS_TOKEN_EXPIRE_MINUTES

logger = logging.getLogger(__name__)


class AuthRepository:
    def __init__(self, db: Session):
        self.db = db

    def get_user_by_email_verification_token(self, token: str) -> User | None:
        return self.db.query(User).filter(User.email_verification_token == token).first()

    def activate_user(self, user: User) -> User:
        user.is_active = True
        user.clear_email_verification_token()
        self.db.commit()
        self.db.refresh(user)
        return user

    def get_customer_by_user_id(self, user_id: int) -> Customer | None:
        return self.db.query(Customer).filter(Customer.user_id == user_id).first()

    def verify_email_and_generate_token(self, verification_token: str) -> dict:
        """
        Verifies a user's email address using the token, activates the user,
        and generates an access token.
        """
        user_to_verify = self.get_user_by_email_verification_token(verification_token)

        if not user_to_verify:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid or already used verification token."
            )

        if user_to_verify.is_active:
            # Allow proceeding to token generation if already active and token matches
            pass

        # Activate user and clear token
        user_to_verify.is_active = True
        user_to_verify.clear_email_verification_token()
        self.db.commit()
        self.db.refresh(user_to_verify)

        # Automatically log the user in by creating an access token
        access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
        customer_record = self.db.query(Customer).filter(Customer.user_id == user_to_verify.user_id).first()
        if not customer_record:
            logger.error(f"Customer record not found for verified user_id {user_to_verify.user_id}.")
            raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                                detail="Account activated, but an error occurred retrieving profile details for login. Please try logging in manually.")

        access_token = create_access_token(
            data={
                "sub": user_to_verify.email,
                "role": user_to_verify.user_type,
                "user_id": user_to_verify.user_id,
                "role_id": customer_record.customer_id,
                "name": user_to_verify.first_name,
            },
            expires_delta=access_token_expires,
        )
        return {"token": access_token, "message": "Account activated successfully. You are now logged in."}


# Dependency to get the AuthRepository instance
def get_auth_repository(db: Session = Depends(get_db)) -> AuthRepository:
    return AuthRepository(db)