from typing import Optional
from pydantic import BaseModel

# TicketType is a model representing a type of ticket for an event.
class TicketType(BaseModel):
    type_id: int
    event_id: int
    description: Optional[str] = None
    max_count: int
    price: float
    currency: str = "PLN"
    available_from: Optional[str] = None

# TicketBase is a base model for ticket-related operations.
class TicketBase(BaseModel):
    ticket_id: int
    ticket_type_id: int
    seat: Optional[str] = None

# TicketDetails is a model representing detailed information about a ticket.
class TicketDetails(TicketBase):
    owner_id: Optional[int] = None
    resell_price: Optional[float] = None

class TicketPDF(BaseModel):
    pdf_data: str
    filename: str

class ResellTicketRequest(BaseModel):
    ticket_id: int
    price: Optional[float] = None
