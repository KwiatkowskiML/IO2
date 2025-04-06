from typing import List

from fastapi import APIRouter, Path, Depends

from common.schemas.ticket import TicketDetails, TicketPDF, ResellTicketRequest
from common.schemas.payment import  PaymentResponse
from common.security import get_current_user
from common.filters.ticket_filter import TicketFilter

router = APIRouter(prefix="/tickets", tags=["tickets"])

@router.get("", response_model=List[TicketDetails])
async def get_tickets(
    filters: TicketFilter = Depends(),
    current_user=Depends(get_current_user)
) -> List[TicketDetails]:
    return [TicketDetails(
        ticket_id=1,
        ticket_type_id=1,
        seat="A1",
        owner_id=1,
    )]

@router.get("/{ticket_id}/download", response_model=TicketPDF)
async def download_ticket(
    ticket_id: int = Path(..., title="ticket ID"),
    current_user=Depends(get_current_user)
) -> TicketPDF:
    return TicketPDF(pdf_data="base64_encoded_pdf_data", filename="ticket.pdf")

@router.post("/{ticket_id}/resell", response_model=TicketDetails)
async def resell_ticket(
    resell_data: ResellTicketRequest,
    current_user=Depends(get_current_user)
) -> TicketDetails:
    return TicketDetails(
        ticket_id=1,
        ticket_type_id=1,
        seat="A1",
        owner_id=1,
        resell_price=10.0
    )

@router.delete("/{ticket_id}/resell", response_model=TicketDetails)
async def cancel_resell(
    ticket_id: int = Path(..., title="ticket ID"),
    current_user=Depends(get_current_user)
) -> TicketDetails:
    return TicketDetails(
        ticket_id=1,
        ticket_type_id=1,
        seat="A1",
        owner_id=1,
        resell_price=None
    )