from typing import List

from fastapi import Path, Depends, APIRouter
from sqlalchemy.orm import Session

from app.filters.ticket_filter import TicketFilter
from app.schemas.ticket import TicketPDF, TicketDetails, ResellTicketRequest
from app.database import get_db
from app.services.ticket_service import TicketService

router = APIRouter(prefix="/tickets", tags=["tickets"])


@router.get("/", response_model=List[TicketDetails])
def list_tickets_endpoint(
    filters: TicketFilter = Depends(),
    db: Session = Depends(get_db)
):
    service = TicketService(db)
    tickets = service.list_tickets(filters)
    return [TicketDetails.model_validate(t) for t in tickets]


@router.get("/{ticket_id}/download", response_model=TicketPDF)
async def download_ticket(
    ticket_id: int = Path(..., title="ticket ID"),
) -> TicketPDF:
    return TicketPDF(pdf_data="base64_encoded_pdf_data", filename="ticket.pdf")


@router.post("/{ticket_id}/resell", response_model=TicketDetails)
async def resell_ticket(
    resell_data: ResellTicketRequest,
) -> TicketDetails:
    return TicketDetails(ticket_id=1, ticket_type_id=1, seat="A1", owner_id=1, resell_price=10.0)


@router.delete("/{ticket_id}/resell", response_model=TicketDetails)
async def cancel_resell(
    ticket_id: int = Path(..., title="ticket ID"),
) -> TicketDetails:
    return TicketDetails(ticket_id=1, ticket_type_id=1, seat="A1", owner_id=1, resell_price=None)
