from typing import List

from app.database import get_db
from sqlalchemy.orm import Session
from fastapi import Path, Depends, APIRouter, Header, HTTPException, status
from app.filters.ticket_filter import TicketFilter
from app.repositories.ticket_repository import TicketRepository
from app.schemas.ticket import TicketPDF, TicketDetails, ResellTicketRequest
from app.utils.jwt_auth import get_user_from_token

router = APIRouter(prefix="/tickets", tags=["tickets"])


@router.get("/", response_model=List[TicketDetails])
def list_tickets_endpoint(
        filters: TicketFilter = Depends(),
        db: Session = Depends(get_db),
        user: dict = Depends(get_user_from_token)):
    repository = TicketRepository(db)

    if filters.owner_id is None:
        filters.owner_id = user["user_id"]

    tickets = repository.list_tickets(filters)
    return [TicketDetails(**ticket_dict) for ticket_dict in tickets]

@router.get("/{ticket_id}/download", response_model=TicketPDF)
async def download_ticket(
    ticket_id: int = Path(..., title="ticket ID"),
) -> TicketPDF:
    # TODO
    return TicketPDF(pdf_data="base64_encoded_pdf_data", filename="ticket.pdf")


@router.post("/{ticket_id}/resell", response_model=TicketDetails)
async def resell_ticket(
        ticket_id: int = Path(..., title="ticket ID"),
        resell_data: ResellTicketRequest = None,
        authorization: str = Header(..., description="Bearer token"),
        db: Session = Depends(get_db)
) -> TicketDetails:
    """List a ticket for resale"""
    user = get_user_from_token(authorization)
    user_id = user["user_id"]

    resell_data.ticket_id = ticket_id

    repository = TicketRepository(db)
    return TicketDetails.model_validate(repository.resell_ticket(resell_data, user_id))


@router.delete("/{ticket_id}/resell", response_model=TicketDetails)
async def cancel_resell(
        ticket_id: int = Path(..., title="ticket ID"),
        authorization: str = Header(..., description="Bearer token"),
        db: Session = Depends(get_db)
) -> TicketDetails:
    """Remove a ticket from resale"""
    user = get_user_from_token(authorization)
    user_id = user["user_id"]

    repository = TicketRepository(db)
    return TicketDetails.model_validate(repository.cancel_resell(ticket_id, user_id))
