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
