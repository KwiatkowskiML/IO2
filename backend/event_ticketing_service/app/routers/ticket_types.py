from typing import List

from app.schemas.ticket import TicketType
from fastapi import Path, Depends, APIRouter
from app.filters.ticket_type_filter import TicketTypeFilter
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.ticket_type import TicketTypeModel

router = APIRouter(prefix="/ticket-types", tags=["ticket_types"])

@router.get("/", response_model=List[TicketType])
def get_ticket_types(
    filters: TicketTypeFilter = Depends(),
    db: Session = Depends(get_db),
):
    """
    Retrieve ticket types, optionally filtering by:
    - event_id
    - min_price
    - max_price
    """
    query = db.query(TicketTypeModel)

    # 1) Filter by specific ticket type ID
    if filters.ticket_type_id is not None:
        query = query.filter(TicketTypeModel.type_id == filters.ticket_type_id)

    # 2) Filter by event ID
    if filters.event_id is not None:
        query = query.filter(TicketTypeModel.event_id == filters.event_id)

    # 3) Price range filters
    if filters.min_price is not None:
        query = query.filter(TicketTypeModel.price >= filters.min_price)
    if filters.max_price is not None:
        query = query.filter(TicketTypeModel.price <= filters.max_price)

    # Execute and serialize
    types = query.all()
    return [TicketType.model_validate(t) for t in types]

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
