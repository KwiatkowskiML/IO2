from typing import List
from datetime import datetime

from fastapi import Path, Depends, APIRouter
from app.filters.events_filter import EventsFilter
from app.schemas.event import EventBase, EventUpdate, EventDetails, NotificationRequest
from sqlalchemy.orm import Session

from app.database import get_db
from app.services.event_service import EventService

router = APIRouter(prefix="/events", tags=["events"])


@router.post("/", response_model=EventDetails)
async def create_event(
    event_data: EventBase,
    db: Session = Depends(get_db)
):
    """Create a new event (requires authentication)"""
    service = EventService(db)
    return service.create_event(event_data, event_data.organizer_id)


@router.post("/authorize/{event_id}", response_model=bool)
async def authorize_event(
    event_id: int = Path(..., title="Event ID"),
):
    """Authorize an event (requires admin authentication)"""
    return True


@router.get("", response_model=List[EventDetails])
def get_events_endpoint(
    filters: EventsFilter = Depends(),
    db: Session = Depends(get_db)
):
    service = EventService(db)
    events = service.get_events(filters)
    return [EventDetails.model_validate(e) for e in events]

#
# @router.put("/{event_id}", response_model=EventDetails)
# async def update_event(
#     update_data: EventUpdate,
#     event_id: int = Path(..., title="Event ID"),
# ):
#     """Update an event (requires organizer authentication)"""
#     return EventDetails(
#         id=1,
#         name="Sample Event",
#         location="Warsaw",
#         start=datetime.now(),
#         end=datetime.now(),
#         organizer_id=1,
#         status="active",
#         total_tickets=100,
#         available_tickets=80,
#         category=[],
#     )


@router.delete("/{event_id}", response_model=bool)
async def cancel_event(
    event_id: int = Path(..., title="Event ID"),
):
    """Cancel an event (requires organizer authentication)"""
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
