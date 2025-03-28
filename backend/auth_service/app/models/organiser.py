from app.models.base import Base
from sqlalchemy.orm import relationship
from sqlalchemy import Column, String, Boolean, Integer, ForeignKey


class Organiser(Base):
    __tablename__ = "organisers"

    organiser_id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.user_id"), unique=True)
    company_name = Column(String)
    is_verified = Column(Boolean, default=False)
    user = relationship("User")
