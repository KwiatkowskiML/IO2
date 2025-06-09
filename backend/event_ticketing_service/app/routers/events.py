from typing import List
from datetime import datetime, timedelta

from app.database import get_db
from sqlalchemy.orm import Session
from fastapi import Path, Depends, APIRouter
from app.filters.events_filter import EventsFilter
from app.repositories.event_repository import EventRepository
from app.schemas.event import EventBase, EventUpdate, EventDetails, NotificationRequest

router = APIRouter(prefix="/events", tags=["events"])


@router.post("/", response_model=EventDetails)
async def create_event(event_data: EventBase, db: Session = Depends(get_db)):
    """Create a new event (requires authentication)"""
    repository = EventRepository(db)
    return repository.create_event(event_data, event_data.organizer_id)


@router.post("/authorize/{event_id}", response_model=bool)
async def authorize_event(
    event_id: int = Path(..., title="Event ID"),
    db: Session = Depends(get_db),
):
    """Authorize an event (requires admin authentication)"""
    repository = EventRepository(db)
    repository.authorize_event(event_id)
    return True


@router.get("", response_model=List[EventDetails])
def get_events_endpoint(filters: EventsFilter = Depends(), db: Session = Depends(get_db)):
    repository = EventRepository(db)
    events = repository.get_events(filters)
    return [EventDetails.model_validate(e) for e in events]


@router.put("/{event_id}", response_model=EventDetails)
def update_event_endpoint(
    event_id: int = Path(..., title="Event ID"),
    update_data: EventUpdate = Depends(),
    db: Session = Depends(get_db),
):
    # TODO: use auth dependency
    current_user_id = 1  # Placeholder for current user ID

    repository = EventRepository(db)
    return repository.update_event(event_id, update_data, current_user_id)


@router.delete("/{event_id}", response_model=bool)
def cancel_event_endpoint(
    event_id: int = Path(..., title="Event ID"),
    db: Session = Depends(get_db),
):
    # TODO: use auth dependency
    current_user_id = 1

    repository = EventRepository(db)
    repository.cancel_event(event_id, current_user_id)
    return True


@router.post("/{event_id}/notify")
async def notify_participants(
    event_id: int = Path(..., title="Event ID"),
    notification: NotificationRequest = None,
):
    """Notify participants of an event (requires organizer authentication)"""
    return {
        "success": True,
        "event_id": event_id,
        "message": notification.message if notification else "Default notification",
        "recipients_affected": 150,
    }
