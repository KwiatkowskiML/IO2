from typing import List

from fastapi import Path, Depends, APIRouter
from sqlalchemy.orm import Session

from app.filters.ticket_filter import TicketFilter
from app.schemas.ticket import TicketPDF, TicketDetails, ResellTicketRequest
from app.database import get_db
from app.repositories.ticket_repository import TicketRepository

router = APIRouter(prefix="/tickets", tags=["tickets"])


@router.get("/", response_model=List[TicketDetails])
def list_tickets_endpoint(
    filters: TicketFilter = Depends(),
    db: Session = Depends(get_db)
):
    repository = TicketRepository(db)
    tickets = repository.list_tickets(filters)
    return [TicketDetails.model_validate(t) for t in tickets]


@router.get("/{ticket_id}/download", response_model=TicketPDF)
async def download_ticket(
    ticket_id: int = Path(..., title="ticket ID"),
) -> TicketPDF:
    # TODO
    return TicketPDF(pdf_data="base64_encoded_pdf_data", filename="ticket.pdf")


@router.post("/{ticket_id}/resell", response_model=TicketDetails)
async def resell_ticket(
    resell_data: ResellTicketRequest,
    db: Session = Depends(get_db)
) -> TicketDetails:
    # TODO: add authorization
    current_user_id = 101  # Placeholder for current user ID

    repository = TicketRepository(db)
    return repository.resell_ticket(resell_data, current_user_id)


@router.delete("/{ticket_id}/resell", response_model=TicketDetails)
async def cancel_resell(
    ticket_id: int = Path(..., title="ticket ID"),
    db: Session = Depends(get_db)
) -> TicketDetails:
    # TODO: add authorization
    current_user_id = 101  # Placeholder for current user ID

    repository = TicketRepository(db)
    return repository.cancel_resell(ticket_id, current_user_id)

