from typing import List

from fastapi import Path, APIRouter
from app.schemas.ticket import TicketBase, TicketDetails

router = APIRouter(prefix="/cart", tags=["cart"])


@router.get("/items", response_model=List[TicketBase])
async def get_shopping_cart():
    return [TicketBase(ticket_id=1, ticket_type_id=1)]


@router.post("/items", response_model=bool)
async def add_to_cart(
    item: TicketDetails,
):
    return True


@router.delete("/items/{ticket_id}", response_model=bool)
async def remove_from_cart(
    ticket_id: int = Path(..., title="Ticket ID", ge=1),
):
    return True


@router.post("/checkout", response_model=bool)
async def checkout_cart():
    return True
