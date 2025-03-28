from enum import Enum
from datetime import datetime

from sqlalchemy import Enum as SQLAlchemyEnum
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy import Column, String, Boolean, Integer, DateTime

Base = declarative_base()


class UserRole(str, Enum):
    CUSTOMER = "customer"
    ORGANIZER = "organizer"
    ADMINISTRATOR = "administrator"


class UserStatus(str, Enum):
    ACTIVE = "active"
    BANNED = "banned"
    VERIFICATION_PENDING = "verification_pending"


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True)
    login = Column(String, unique=True, index=True)
    password_hash = Column(String)
    first_name = Column(String)
    last_name = Column(String)
    creation_date = Column(DateTime, default=datetime.utcnow)
    is_active = Column(Boolean, default=True)
    role = Column(SQLAlchemyEnum(UserRole))
    status = Column(SQLAlchemyEnum(UserStatus), default=UserStatus.ACTIVE)

    # This column will be used for password reset tokens or email verification
    token = Column(String, nullable=True)
    token_expiry = Column(DateTime, nullable=True)

    # For organizer-specific data
    company_name = Column(String, nullable=True)
    is_verified = Column(Boolean, default=False)
