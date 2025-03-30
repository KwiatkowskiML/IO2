from typing import Optional

from common.security import get_current_user
from fastapi import Path, Depends, APIRouter
from common.schemas.ticket import TicketPDF, TicketDetails

router = APIRouter(prefix="/user", tags=["user"])


@router.get("/")
def home():
    return {"message": "Hello World - Users"}


@router.get("/tickets")
async def get_user_tickets(
    current_user=Depends(get_current_user), event_id: Optional[str] = None, is_on_sale: Optional[bool] = None
) -> list[TicketDetails]:
    return list[TicketDetails]()


@router.delete("/tickets/{ticket_id}/resell")
async def cancel_resell(
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
