from typing import Optional

from common.security import get_current_user
from fastapi import Path, Depends, APIRouter
from user_service.app.schemas.cart import PaymentResponse
from common.schemas.ticket import TicketDetails

router = APIRouter(prefix="/tickets", tags=["tickets"])


@router.get("/")
def home():
    return {"message": "Hello World - tickets"}


@router.get("/get")
async def get_resale_tickets(
    event_id: Optional[str] = None, max_price: Optional[float] = None, current_user=Depends(get_current_user)
) -> list[TicketDetails]:
    return []


@router.post("/{ticket_id}/buy")
async def buy_resale_ticket(
    ticket_id: str = Path(..., title="resale ticket ID"), current_user=Depends(get_current_user)
) -> PaymentResponse:
    return PaymentResponse(success=True, transaction_id="123456789", error_message=None)
