from enum import Enum
from typing import Optional
from datetime import datetime

from pydantic import Field, EmailStr, BaseModel, validator


class UserRole(str, Enum):
    CUSTOMER = "customer"
    ORGANIZER = "organizer"
    ADMINISTRATOR = "administrator"


class UserStatus(str, Enum):
    ACTIVE = "active"
    BANNED = "banned"
    VERIFICATION_PENDING = "verification_pending"


class UserBase(BaseModel):
    email: EmailStr
    login: str


class UserCreate(UserBase):
    password: str = Field(..., min_length=8)
    first_name: str
    last_name: str

    @validator("password")
    def password_complexity(cls, v):
        if not any(char.isdigit() for char in v):
            raise ValueError("Password must contain at least one digit")
        if not any(char.isupper() for char in v):
            raise ValueError("Password must contain at least one uppercase letter")
        return v


class OrganizerCreate(UserCreate):
    company_name: str


class AdminCreate(UserCreate):
    admin_secret_key: str


class UserLogin(BaseModel):
    email: EmailStr
    password: str


class Token(BaseModel):
    token: str
    message: str


class TokenData(BaseModel):
    email: Optional[str] = None
    role: Optional[str] = None
    exp: Optional[datetime] = None


class UserResponse(UserBase):
    id: int
    first_name: str
    last_name: str
    creation_date: datetime
    is_active: bool
    role: UserRole
    status: UserStatus

    class Config:
        orm_mode = True


class OrganizerResponse(UserResponse):
    company_name: str
    is_verified: bool

    class Config:
        orm_mode = True


class VerificationRequest(BaseModel):
    organizer_id: int
    approve: bool


class PasswordReset(BaseModel):
    email: EmailStr


class PasswordResetConfirm(BaseModel):
    token: str
    new_password: str = Field(..., min_length=8)

    @validator("new_password")
    def password_complexity(cls, v):
        if not any(char.isdigit() for char in v):
            raise ValueError("Password must contain at least one digit")
        if not any(char.isupper() for char in v):
            raise ValueError("Password must contain at least one uppercase letter")
        return v
