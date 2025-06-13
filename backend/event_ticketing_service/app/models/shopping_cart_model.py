from app.database import Base
from sqlalchemy.orm import relationship
from sqlalchemy import Column, Integer


class ShoppingCartModel(Base):
    __tablename__ = "shopping_carts"

    cart_id = Column(Integer, primary_key=True, index=True)
    customer_id = Column(Integer, nullable=False, unique=True)

    items = relationship("CartItemModel", back_populates="cart", cascade="all, delete-orphan")