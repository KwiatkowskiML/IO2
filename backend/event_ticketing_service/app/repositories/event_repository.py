"""
Fixed event_repository.py - Eliminates duplicate validation logic
"""

from typing import List

from sqlalchemy.orm import Session, joinedload, selectinload

from app.database import get_db
from app.models.events import EventModel
from app.models.ticket import TicketModel
from app.models.ticket_type import TicketTypeModel
from fastapi import HTTPException, status, Depends
from app.models.location import LocationModel
from app.filters.events_filter import EventsFilter
from app.repositories.ticket_repository import get_ticket_repository
from app.schemas.event import EventBase, EventUpdate
from app.schemas.ticket import TicketType



class EventRepository:
    """Service layer for event operations, ensuring single responsibility and testability."""

    def __init__(self, db: Session):
        self.db = db

    def get_event(self, event_id: int) -> EventModel:
        event = (
            self.db.query(EventModel)
            .options(joinedload(EventModel.location), selectinload(EventModel.ticket_types))
            .filter(EventModel.event_id == event_id)
            .first()
        )
        if not event:
            raise HTTPException(status.HTTP_404_NOT_FOUND, detail="Event not found")
        return event

    def create_event(self, data: EventBase, organizer_id: int) -> EventModel:
        location = self.db.query(LocationModel).filter(
            LocationModel.location_id == data.location_id).first()
        if not location:
            raise HTTPException(status.HTTP_404_NOT_FOUND,
                                detail=f"Location '{data.location_id}' not found")

        event = EventModel(
            organizer_id=organizer_id,
            location_id=location.location_id,
            name=data.name,
            description=data.description,
            start_date=data.start_date,
            end_date=data.end_date,
            minimum_age=data.minimum_age,
            status="pending",
        )
        self.db.add(event)
        self.db.commit()
        self.db.refresh(event)

        # Create standard ticket type
        ticket_type = TicketType(
            event_id=event.event_id,
            description="Standard Ticket",
            max_count=data.total_tickets,
            price=data.standard_ticket_price,
            currency="USD",
            available_from=data.ticket_sales_start,
        )
        ticket_repo = get_ticket_repository(self.db)
        ticket_repo.create_ticket_type(ticket_type)

        # After commit, re-query the event to get eager-loaded relationships for the response model.
        return self.get_event(event.event_id)

    def _validate_event_status_change(self, event: EventModel, required_status: str,
                                      action: str) -> None:
        if event.status != required_status:
            raise HTTPException(
                status.HTTP_400_BAD_REQUEST,
                detail=f"Event must be in {required_status} status to {action}. Current status: {event.status}"
            )

    def authorize_event(self, event_id: int) -> None:
        """Authorize a pending event"""
        event = self.get_event(event_id)
        self._validate_event_status_change(event, "pending", "authorize")
        event.status = "created"
        self.db.commit()

    def reject_event(self, event_id: int) -> None:
        """Reject a pending event"""
        event = self.get_event(event_id)
        self._validate_event_status_change(event, "pending", "reject")
        event.status = "rejected"
        self.db.commit()

    def get_events(self, filters: EventsFilter) -> List[EventModel]:
        query = self.db.query(EventModel).options(
            joinedload(EventModel.location), selectinload(EventModel.ticket_types)
        )

        if filters.location:
            # Add explicit join when filtering on location name
            query = query.join(LocationModel)

        if filters.name:
            query = query.filter(EventModel.name.ilike(f"%{filters.name}%"))
        if filters.location:
            query = query.filter(LocationModel.name == filters.location)
        if filters.start_date_from:
            query = query.filter(EventModel.start_date >= filters.start_date_from)
        if filters.start_date_to:
            query = query.filter(EventModel.end_date <= filters.start_date_to)
        if filters.organizer_id:
            query = query.filter(EventModel.organizer_id == filters.organizer_id)
        if filters.minimum_age:
            query = query.filter(EventModel.minimum_age >= filters.minimum_age)
        if filters.status:
            query = query.filter(EventModel.status == filters.status)

        # TODO: add price filters (join ticket_types) and availability checks

        return query.all()

    def update_event(self, event_id: int, data: EventUpdate, organizer_id: int) -> EventModel:
        event = self.get_event(event_id)
        if event.organizer_id != organizer_id:
            raise HTTPException(status.HTTP_403_FORBIDDEN,
                                detail="Not authorized to update this event")
        updates = data.dict(exclude_unset=True)
        for field, value in updates.items():
            if value is not None:
                setattr(event, field, value)
        self.db.commit()
        # Re-fetch with eager loading for the response
        return self.get_event(event_id)

    def cancel_event(self, event_id: int, organizer_id: int) -> None:
        event = self.get_event(event_id)
        if event.organizer_id != organizer_id:
            raise HTTPException(status.HTTP_403_FORBIDDEN,
                                detail="Not authorized to cancel this event")

        # Check if any tickets for this event have been sold
        sold_tickets_count = (
            self.db.query(TicketModel.ticket_id)
            .join(TicketTypeModel, TicketModel.type_id == TicketTypeModel.type_id)
            .filter(TicketTypeModel.event_id == event_id)
            .filter(TicketModel.owner_id.isnot(None))
            .count()
        )

        if sold_tickets_count > 0:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Cannot cancel event. There are {sold_tickets_count} sold tickets that must be refunded first."
            )

        event.status = "cancelled"
        self.db.commit()


# Dependency to get the EventRepository instance
def get_event_repository(db: Session = Depends(get_db)) -> EventRepository:
    return EventRepository(db)