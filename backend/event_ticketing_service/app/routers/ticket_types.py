from typing import List

from app.schemas.ticket import TicketType
from fastapi import Path, Depends, APIRouter, status
from fastapi.exceptions import HTTPException
from app.filters.ticket_type_filter import TicketTypeFilter
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.ticket_type import TicketTypeModel
from app.models.events import EventModel

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
    if filters.type_id is not None:
        query = query.filter(TicketTypeModel.type_id == filters.type_id)

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
    db: Session = Depends(get_db),
):
    event = db.get(EventModel, ticket.event_id)
    if not event:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Event with id {ticket.event_id} not found"
        )

    # Create model from request data
    model = TicketTypeModel(
        event_id=ticket.event_id,
        description=ticket.description,
        max_count=ticket.max_count,
        price=ticket.price,
        currency=ticket.currency,
        available_from=ticket.available_from,
    )

    # Persist to database
    db.add(model)
    db.commit()
    db.refresh(model)

    # Return response
    return TicketType.model_validate(model)

@router.delete("/{type_id}", response_model=bool)
def delete_ticket_type(
    type_id: int = Path(..., title="Ticket Type ID", ge=1, description="Must be a positive integer"),
    db: Session = Depends(get_db),
):
    model = db.get(TicketTypeModel, type_id)
    if not model:
        raise HTTPException(status_code=404, detail="Ticket type not found")
    db.delete(model)
    db.commit()
    return True
