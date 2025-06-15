from datetime import datetime

from app.models.base import Base
from sqlalchemy.orm import relationship
from sqlalchemy import Column, String, Boolean, Integer, DateTime


class User(Base):
    __tablename__ = "users"

    user_id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True)
    login = Column(String, unique=True, index=True)
    password_hash = Column(String)
    first_name = Column(String)
    last_name = Column(String)
    creation_date = Column(DateTime, default=datetime.utcnow)
    is_active = Column(Boolean, default=True)
    user_type = Column(String)  # 'customer', 'organizer', 'administrator'

    email_verification_token = Column(String, nullable=True, unique=True, index=True)

    # Define relationships
    customer = relationship("Customer", back_populates="user", uselist=False)
    organizer = relationship("Organizer", back_populates="user", uselist=False)
    administrator = relationship("Administrator", back_populates="user", uselist=False)

    def set_email_verification_token(self):
        """Generates and sets a new email verification token."""
        from app.security import generate_email_verification_token  # Local import for security functions
        self.email_verification_token = generate_email_verification_token()

    def clear_email_verification_token(self):
        """Clears the email verification token."""
        self.email_verification_token = None
