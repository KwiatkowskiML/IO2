from typing import Optional
from datetime import datetime

from pydantic import BaseModel, ConfigDict


# TicketType is a model representing a type of ticket for an event.
class TicketType(BaseModel):
    type_id: Optional[int] = None
    event_id: int
    description: Optional[str] = None
    max_count: int
    price: float
    currency: str = "PLN"
    available_from: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)


# TicketBase is a base model for ticket-related operations.
class TicketDetails(BaseModel):
    ticket_id: int
    type_id: Optional[int] = None
    seat: Optional[str] = None
    owner_id: Optional[int] = None
    resell_price: Optional[float] = None

    model_config = ConfigDict(from_attributes=True)


class TicketPDF(BaseModel):
    pdf_data: str
    filename: str


class ResellTicketRequest(BaseModel):
    ticket_id: Optional[int] = None
    price: Optional[float] = None
