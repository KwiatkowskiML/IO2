from typing import List

from sqlalchemy.orm import Session, joinedload, selectinload

from app.database import get_db
from app.models.events import EventModel
from fastapi import HTTPException, status, Depends
from app.models.location import LocationModel
from app.filters.events_filter import EventsFilter
from app.schemas.event import EventBase, EventUpdate


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
        # Validate location exists
        location = self.db.query(LocationModel).filter(LocationModel.location_id == data.location_id).first()
        if not location:
            raise HTTPException(status.HTTP_404_NOT_FOUND, detail=f"Location '{data.location_id}' not found")

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
        # After commit, re-query the event to get eager-loaded relationships for the response model.
        return self.get_event(event.event_id)

    def authorize_event(self, event_id: int) -> None:
        event = self.get_event(event_id)
        event.status = "created"
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
            query = query.filter(LocationModel.name.ilike(f"%{filters.location}%"))
        if filters.start_date_from:
            query = query.filter(EventModel.start_date >= filters.start_date_from)
        if filters.start_date_to:
            query = query.filter(EventModel.start_date <= filters.start_date_to)
        if filters.organizer_id:
            query = query.filter(EventModel.organizer_id == filters.organizer_id)
        if filters.minimum_age:
            query = query.filter(EventModel.minimum_age >= filters.minimum_age)

        # Filter by events that have available tickets
        if filters.has_available_tickets:
            # This would require more complex logic to check ticket availability
            # For now, we just return all events
            pass

        return query.all()

    def update_event(self, event_id: int, data: EventUpdate, organizer_id: int) -> EventModel:
        event = self.get_event(event_id)
        if event.organizer_id != organizer_id:
            raise HTTPException(status.HTTP_403_FORBIDDEN, detail="Not authorized to update this event")
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
            raise HTTPException(status.HTTP_403_FORBIDDEN, detail="Not authorized to cancel this event")
        event.status = "cancelled"
        self.db.commit()

# Dependency to get the EventRepository instance
def get_event_repository(db: Session = Depends(get_db)) -> EventRepository:
    return EventRepository(db)
