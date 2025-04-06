from typing import Optional
from datetime import datetime

from pydantic import Field, EmailStr, BaseModel, field_validator


class UserBase(BaseModel):
    email: EmailStr
    login: str


class UserCreate(UserBase):
    password: str = Field(..., min_length=8)
    first_name: str
    last_name: str

    @field_validator("password")
    @classmethod
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


class UserResponse(BaseModel):
    user_id: int
    email: str
    login: str
    first_name: str
    last_name: str
    creation_date: datetime
    is_active: bool
    user_type: str

    class Config:
        orm_mode = True

    @property
    def id(self) -> int:
        return self.user_id

    @property
    def role(self) -> str:
        return self.user_type

    @property
    def status(self) -> str:
        return "active" if self.is_active else "banned"


class OrganizerResponse(UserResponse):
    organiser_id: int
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

    @field_validator("new_password")
    @classmethod
    def password_complexity(cls, v):
        if not any(char.isdigit() for char in v):
            raise ValueError("Password must contain at least one digit")
        if not any(char.isupper() for char in v):
            raise ValueError("Password must contain at least one uppercase letter")
        return v
