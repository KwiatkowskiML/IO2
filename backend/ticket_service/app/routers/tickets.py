from fastapi import APIRouter

from common.schemas.ticket import TicketDetails, TicketPDF

router = APIRouter(prefix="/tickets", tags=["tickets"])

@router.post("/purchase")
async def purchase_ticket():
    """
    Purchase a new ticket for an event
    """
    pass

@router.get("/{ticket_id}")
async def get_ticket_details(
    ticket_id: str = Path(..., title="ticket ID"), current_user=Depends(get_current_user)
) -> TicketDetails:
    return TicketDetails(
        id="123",
        owner_id="123",
        is_on_sale=True,
        price=40.0,
        currency="PLN",
        event_id="123",
        ticket_type_id="123",
        seat="A1",
    )

@router.get("/{ticket_id}/download")
async def download_ticket(
    ticket_id: str = Path(..., title="ticket ID"), current_user=Depends(get_current_user)
) -> TicketPDF:
    return TicketPDF(pdf_data="base64_encoded_pdf_data", filename="ticket.pdf")

@router.post("/tickets/{ticket_id}/resell")
async def resell_ticket(resell_data: ResellTicketRequest, current_user=Depends(get_current_user)) -> TicketDetails:
    return TicketDetails(
        id="123",
        owner_id="123",
        is_on_sale=True,
        price=40.0,
        currency="PLN",
        event_id="123",
        ticket_type_id="123",
        seat="A1",
    )