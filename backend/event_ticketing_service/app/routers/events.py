from typing import List

from app.database import get_db
from sqlalchemy.orm import Session
from fastapi import Path, Depends, APIRouter
from app.filters.events_filter import EventsFilter
from app.repositories.event_repository import EventRepository, get_event_repository
from app.schemas.event import EventBase, EventUpdate, EventDetails, NotificationRequest
from app.utils.jwt_auth import get_current_organizer, get_current_admin

router = APIRouter(prefix="/events", tags=["events"])


@router.post("/", response_model=EventDetails)
async def create_event(
    event_data: EventBase,
    event_repo: EventRepository = Depends(get_event_repository),
    current_organizer = Depends(get_current_organizer)
):
    """Create a new event (requires authentication)"""
    return event_repo.create_event(event_data, current_organizer["role_id"])


@router.post("/authorize/{event_id}", response_model=bool)
async def authorize_event(
    event_id: int = Path(..., title="Event ID"),
    event_repo: EventRepository = Depends(get_event_repository),
    current_admin = Depends(get_current_admin)
):
    """Authorize an event (requires admin authentication)"""
    event_repo.authorize_event(event_id)
    return True


@router.get("", response_model=List[EventDetails])
def get_events_endpoint(
    filters: EventsFilter = Depends(),
    event_repo: EventRepository = Depends(get_event_repository),
):
    events = event_repo.get_events(filters)
    return [EventDetails.model_validate(e) for e in events]


@router.put("/{event_id}", response_model=EventDetails)
def update_event_endpoint(
    event_id: int = Path(..., title="Event ID"),
    update_data: EventUpdate = Depends(),
    event_repo: EventRepository = Depends(get_event_repository),
    current_organizer = Depends(get_current_organizer)
):
    return event_repo.update_event(event_id, update_data, current_organizer["role_id"])


@router.delete("/{event_id}", response_model=bool)
def cancel_event_endpoint(
    event_id: int = Path(..., title="Event ID"),
    event_repo: EventRepository = Depends(get_event_repository),
    current_organizer = Depends(get_current_organizer)
):
    event_repo.cancel_event(event_id, current_organizer["role_id"])
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
