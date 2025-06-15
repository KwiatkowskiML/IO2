from pydantic import BaseModel, ConfigDict
from typing import Optional

from app.schemas.ticket import TicketType

class CartItemWithDetails(BaseModel):
    cart_item_id: int
    ticket_type: Optional[TicketType] = None
    quantity: int

    model_config = ConfigDict(from_attributes=True)