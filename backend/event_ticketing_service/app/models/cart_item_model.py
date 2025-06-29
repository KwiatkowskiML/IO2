from app.database import Base
from sqlalchemy.orm import relationship
from sqlalchemy import Column, Integer, UniqueConstraint, ForeignKey


class CartItemModel(Base):
    __tablename__ = "cart_items"

    cart_item_id = Column(Integer, primary_key=True, index=True)
    cart_id = Column(Integer, ForeignKey("shopping_carts.cart_id", ondelete="CASCADE"), nullable=False)
    ticket_type_id = Column(Integer, ForeignKey("ticket_types.type_id", ondelete="CASCADE"), nullable=True)
    quantity = Column(Integer, nullable=False, default=1)

    cart = relationship("ShoppingCartModel", back_populates="items")
    ticket_type = relationship("TicketTypeModel")
