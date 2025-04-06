from typing import List

from fastapi import Path, Depends, APIRouter

from common.security import get_current_user
from common.schemas.payment import PaymentResponse
from common.schemas.ticket import TicketBase

router = APIRouter(prefix="/cart", tags=["cart"])

@router.get("/items", response_model=List[TicketBase])
async def get_shopping_cart(
    #current_user=Depends(get_current_user)
):
    return [TicketBase(
        ticket_id=1,
        ticket_type_id=1
    )]

@router.post("/items")
async def add_to_cart():
    return "ok"

@router.delete("/items/{item_id}")
async def remove_from_cart():
    return "ok"

@router.post("/checkout")
async def checkout_cart():
    return "ok"
