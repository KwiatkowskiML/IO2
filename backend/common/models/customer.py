from backend.common.models.base import Base
from sqlalchemy.orm import relationship
from sqlalchemy import Column, Integer, ForeignKey


class Customer(Base):
    __tablename__ = "customers"

    customer_id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.user_id"), unique=True)
    user = relationship("User")
