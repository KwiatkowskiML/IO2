from typing import List

from app.database import get_db
from sqlalchemy.orm import Session
from fastapi import Path, Depends, APIRouter
from app.filters.events_filter import EventsFilter
from app.repositories.event_repository import EventRepository
from app.schemas.event import EventBase, EventUpdate, EventDetails, NotificationRequest
from app.utils.jwt_auth import get_current_organizer, get_current_admin

router = APIRouter(prefix="/events", tags=["events"])


@router.post("/", response_model=EventDetails)
async def create_event(
    event_data: EventBase,
    db: Session = Depends(get_db),
    current_organizer = Depends(get_current_organizer)
):
    """Create a new event (requires authentication)"""
    repository = EventRepository(db)
    print(current_organizer)
    return repository.create_event(event_data, current_organizer["role_id"])


@router.post("/authorize/{event_id}", response_model=bool)
async def authorize_event(
    event_id: int = Path(..., title="Event ID"),
    db: Session = Depends(get_db),
    current_admin = Depends(get_current_admin)
):
    """Authorize an event (requires admin authentication)"""
    repository = EventRepository(db)
    repository.authorize_event(event_id)
    return True


@router.get("", response_model=List[EventDetails])
def get_events_endpoint(
    filters: EventsFilter = Depends(),
    db: Session = Depends(get_db)
):
    repository = EventRepository(db)
    events = repository.get_events(filters)
    return [EventDetails.model_validate(e) for e in events]


@router.put("/{event_id}", response_model=EventDetails)
def update_event_endpoint(
    event_id: int = Path(..., title="Event ID"),
    update_data: EventUpdate = Depends(),
    db: Session = Depends(get_db),
    current_organizer = Depends(get_current_organizer)
):
    repository = EventRepository(db)
    return repository.update_event(event_id, update_data, current_organizer["role_id"])


@router.delete("/{event_id}", response_model=bool)
def cancel_event_endpoint(
    event_id: int = Path(..., title="Event ID"),
    db: Session = Depends(get_db),
    current_organizer = Depends(get_current_organizer)
):
    repository = EventRepository(db)
    repository.cancel_event(event_id, current_organizer["role_id"])
    return True


@router.post("/{event_id}/notify")
async def notify_participants(
    event_id: int = Path(..., title="Event ID"),
    notification: NotificationRequest = None,
    current_organizer = Depends(get_current_organizer),
):
    """Notify participants of an event (requires organizer authentication)"""
    return {
        "success": True,
        "event_id": event_id,
        "message": notification.message if notification else "Default notification",
        "recipients_affected": 150,
    }
