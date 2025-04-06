from typing import List
from fastapi import Path, Depends, APIRouter

from common.security import get_current_user
from common.schemas.payment import PaymentResponse
from common.schemas.ticket import TicketBase, TicketDetails

router = APIRouter(prefix="/cart", tags=["cart"])

@router.get("/items", response_model=List[TicketBase])
async def get_shopping_cart(
    #current_user=Depends(get_current_user)
):
    return [TicketBase(
        ticket_id=1,
        ticket_type_id=1
    )]

@router.post("/items", response_model=bool)
async def add_to_cart(
    item: TicketDetails,
    #current_user=Depends(get_current_user)
):
    return True

@router.delete("/items/{ticket_id}", response_model=bool)
async def remove_from_cart(
    ticket_id: int = Path(..., title="Ticket ID", ge=1),
    #current_user=Depends(get_current_user)
):
    return True

@router.post("/checkout", response_model=bool)
async def checkout_cart(
    #current_user=Depends(get_current_user)
):
    return True
