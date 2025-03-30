from typing import Optional

from pydantic import BaseModel


class TicketBase(BaseModel):
    event_id: str
    ticket_type_id: str
    seat: Optional[str] = None


class TicketDetails(TicketBase):
    id: str
    owner_id: str
    is_on_sale: bool
    price: float
    currency: str

    class Config:
        orm_mode = True


class TicketPDF(BaseModel):
    pdf_data: str
    filename: str


class ResellTicketRequest(BaseModel):
    ticket_id: str
    price: Optional[float] = None
