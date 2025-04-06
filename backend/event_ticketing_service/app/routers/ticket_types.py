from fastapi import APIRouter, Path, Depends

from common.schemas.ticket import TicketDetails, TicketPDF, ResellTicketRequest
from common.schemas.payment import  PaymentResponse
from common.security import get_current_user

router = APIRouter(prefix="/ticket-types", tags=["ticket_types"])

@router.post("/")
def create_ticket_type():
    pass
