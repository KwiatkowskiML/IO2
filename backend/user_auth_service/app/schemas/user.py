from typing import Optional

from pydantic import BaseModel


class UserResponse(BaseModel):
    user_id: int
    email: str
    login: Optional[str] = None
    first_name: str
    last_name: str
    user_type: str
    is_active: bool

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


class UserProfileUpdate(BaseModel):
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    login: Optional[str] = None

    class Config:
        orm_mode = True
