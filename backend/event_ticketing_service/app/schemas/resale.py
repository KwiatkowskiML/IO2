from typing import Optional
from datetime import datetime
from pydantic import BaseModel, ConfigDict


class ResaleTicketListing(BaseModel):
    """Schema for a ticket listed on the resale marketplace"""
    ticket_id: int
    original_price: float
    resell_price: float
    event_name: str
    event_date: datetime
    venue_name: str
    ticket_type_description: Optional[str] = None
    seat: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)


class BuyResaleTicketRequest(BaseModel):
    """Request to purchase a resale ticket"""
    ticket_id: int