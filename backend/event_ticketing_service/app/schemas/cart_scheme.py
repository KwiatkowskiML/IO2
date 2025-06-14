from pydantic import BaseModel, ConfigDict
from typing import Optional

from app.schemas.ticket import TicketType

class CartItemWithDetails(BaseModel):
    ticket_type: Optional[TicketType] = None
    quantity: int

    model_config = ConfigDict(from_attributes=True)