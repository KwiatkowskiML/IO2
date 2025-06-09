from typing import List
from datetime import datetime, timedelta

from fastapi import Path, Depends, APIRouter
from app.filters.events_filter import EventsFilter
from app.schemas.event import EventBase, EventUpdate, EventDetails, NotificationRequest

router = APIRouter(prefix="/events", tags=["events"])


@router.post("/", response_model=EventDetails)
async def create_event(
    event_data: EventBase,
):
    """Create a new event (requires authentication)"""
    # Create a valid EventDetails response from the input
    return EventDetails(
        id=1, 
        status="Pending approval", 
        available_tickets=event_data.total_tickets, 
        **event_data.model_dump()
    )


@router.post("/authorize/{event_id}", response_model=bool)
async def authorize_event(
    event_id: int = Path(..., title="Event ID"),
):
    """Authorize an event (requires admin authentication)"""
    return True


@router.get("", response_model=List[EventDetails])
async def get_events(
    event_filter: EventsFilter = Depends(),
):
    """Get events with optional filtering"""
    # Create a fully valid mock response
    return [
        EventDetails(
            id=1,
            name="Sample Event",
            description="This is a fantastic sample event.",
            location="Warsaw",
            start=datetime.now(),
            end=datetime.now() + timedelta(hours=2),
            organiser_id=1,
            status="active",
            total_tickets=100,
            available_tickets=80,
            category=["music", "live"],
            minimum_age=18
        )
    ]


@router.put("/{event_id}", response_model=EventDetails)
async def update_event(
    update_data: EventUpdate,
    event_id: int = Path(..., title="Event ID"),
):
    """Update an event (requires organizer authentication)"""
    # Create a fully valid mock response for an update
    return EventDetails(
        id=event_id,
        name=update_data.name or "Updated Sample Event",
        description=update_data.description or "An updated description.",
        location=update_data.location or "Krakow",
        start=update_data.start or datetime.now(),
        end=update_data.end or datetime.now() + timedelta(hours=3),
        organiser_id=1,
        status="active",
        total_tickets=100,
        available_tickets=80,
        category=["music", "live"],
        minimum_age=18
    )


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
