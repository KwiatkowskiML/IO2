from typing import List

from app.schemas.ticket import TicketType
from fastapi import Path, Depends, APIRouter
from app.filters.ticket_type_filter import TicketTypeFilter

router = APIRouter(prefix="/ticket-types", tags=["ticket_types"])


@router.get("/", response_model=List[TicketType])
def get_ticket_types(ticket_type_filter: TicketTypeFilter = Depends()):
    return [
        TicketType(
            type_id=1,
            event_id=1,
            description="VIP Access",
            max_count=100,
            price=199.99,
            currency="PLN",
            available_from="2025-04-01T10:00:00",
        )
    ]


@router.post("/", response_model=TicketType)
def create_ticket_type(
    ticket: TicketType,
):
    return ticket


@router.delete("/{ticket_id}", response_model=bool)
def delete_ticket_type(
    ticket_id: int = Path(..., title="Ticket ID", ge=1, description="Must be a positive integer"),
):
    return True
