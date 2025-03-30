from typing import Optional
from datetime import datetime

from pydantic import BaseModel


class CartItem(BaseModel):
    ticket_type_id: str
    event_id: str


class CartItemDetails(CartItem):
    id: str
    added_at: datetime
    price: float
    currency: str


class ShoppingCartResponse(BaseModel):
    id: str
    user_id: str
    items: list[CartItemDetails] = []
    total: float
    currency: str


class ResellTicketRequest(BaseModel):
    ticket_id: str
    price: Optional[float] = None


class PaymentResponse(BaseModel):
    success: bool
    transaction_id: Optional[str] = None
    error_message: Optional[str] = None
