from datetime import datetime

from common.models.base import Base
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
    user_type = Column(String)  # 'customer', 'organiser', 'administrator'

    # Define relationships
    customer = relationship("Customer", back_populates="user", uselist=False)
    organiser = relationship("Organiser", back_populates="user", uselist=False)
    administrator = relationship("Administrator", back_populates="user", uselist=False)
