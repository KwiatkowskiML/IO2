from typing import List

from sqlalchemy.orm import Session
from app.models.events import EventModel
from fastapi import HTTPException, status
from app.models.location import LocationModel
from app.filters.events_filter import EventsFilter
from app.schemas.event import EventBase, EventUpdate


class EventRepository:
    """Service layer for event operations, ensuring single responsibility and testability."""

    def __init__(self, db: Session):
        self.db = db

    def get_event(self, event_id: int) -> EventModel:
        event = self.db.get(EventModel, event_id)
        if not event:
            raise HTTPException(status.HTTP_404_NOT_FOUND, detail="Event not found")
        return event

    def create_event(self, data: EventBase, organizer_id: int) -> EventModel:
        # Validate location exists
        location = self.db.query(LocationModel).filter(LocationModel.location_id == data.location_id).first()
        if not location:
            raise HTTPException(status.HTTP_404_NOT_FOUND, detail=f"Location '{data.location_id}' not found")

        event = EventModel(
            organiser_id=organizer_id,
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
        return event

    def authorize_event(self, event_id: int) -> None:
        event = self.get_event(event_id)
        event.status = "created"
        self.db.commit()

    def get_events(self, filters: EventsFilter) -> List[EventModel]:
        query = self.db.query(EventModel).join(LocationModel)
        if filters.name:
            query = query.filter(EventModel.name.ilike(f"%{filters.name}%"))
        if filters.location:
            query = query.filter(LocationModel.name == filters.location)
        if filters.start_date_from:
            query = query.filter(EventModel.start_date >= filters.start_date_from)
        if filters.start_date_to:
            query = query.filter(EventModel.end_date <= filters.start_date_to)
        if filters.organizer_id:
            query = query.filter(EventModel.organiser_id == filters.organizer_id)
        if filters.minimum_age:
            query = query.filter(EventModel.minimum_age >= filters.minimum_age)
        if filters.limit

        # TODO: add price filters (join ticket_types) and availability checks

        return query.all()

    def update_event(self, event_id: int, data: EventUpdate, organizer_id: int) -> EventModel:
        event = self.get_event(event_id)
        if event.organiser_id != organizer_id:
            raise HTTPException(status.HTTP_403_FORBIDDEN, detail="Not authorized to update this event")
        updates = data.dict(exclude_unset=True)
        for field, value in updates.items():
            if value is not None:
                setattr(event, field, value)
        self.db.commit()
        self.db.refresh(event)
        return event

    def cancel_event(self, event_id: int, organizer_id: int) -> None:
        event = self.get_event(event_id)
        if event.organiser_id != organizer_id:
            raise HTTPException(status.HTTP_403_FORBIDDEN, detail="Not authorized to cancel this event")
        event.status = "cancelled"
        self.db.commit()
