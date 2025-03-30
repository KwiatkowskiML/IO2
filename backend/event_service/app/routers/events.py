from fastapi import APIRouter, Depends, Path, Query
from typing import Optional, List
from datetime import datetime
from common.security import get_current_user
from common.schemas.event import EventCreate, EventDetails, EventUpdate, NotificationRequest

router = APIRouter(prefix="/events", tags=["events"])

@router.post("/", response_model=EventDetails)
async def create_event(
    event_data: EventCreate,
    current_user=Depends(get_current_user)
):
    """Create a new event (requires authentication)"""
    return EventDetails(
        id="event_123",
        organizer_id=current_user.user_id,
        status="active",
        total_tickets=100,
        available_tickets=100,
        **event_data.dict()
    )

@router.get("/", response_model=List[EventDetails])
async def get_events(
    location: Optional[str] = Query(None),
    start_date: Optional[datetime] = Query(None),
    end_date: Optional[datetime] = Query(None)
):
    """Get events with optional filtering"""
    # Example mock response
    return [
        EventDetails(
            id="event_123",
            name="Sample Event",
            location="Warsaw",
            start_date=datetime.now(),
            end_date=datetime.now(),
            organizer_id="org_123",
            status="active",
            total_tickets=100,
            available_tickets=80
        )
    ]

@router.put("/{event_id}", response_model=EventDetails)
async def update_event(
    event_id: str = Path(..., title="Event ID"),
    update_data: EventUpdate = None,
    current_user=Depends(get_current_user)
):
    """Update an event (requires organizer authentication)"""
    return EventDetails(
        id=event_id,
        organizer_id=current_user.user_id,
        status="active",
        total_tickets=100,
        available_tickets=80,
        name=update_data.name if update_data else "Updated Event",
        location=update_data.location if update_data else "Warsaw",
        start_date=datetime.now(),
        end_date=datetime.now()
    )

@router.delete("/{event_id}", response_model=EventDetails)
async def cancel_event(
    event_id: str = Path(..., title="Event ID"),
    current_user=Depends(get_current_user)
):
    """Cancel an event (requires organizer authentication)"""
    return EventDetails(
        id=event_id,
        organizer_id=current_user.user_id,
        status="cancelled",
        total_tickets=100,
        available_tickets=80,
        name="Cancelled Event",
        location="Warsaw",
        start_date=datetime.now(),
        end_date=datetime.now()
    )

@router.post("/{event_id}/notify")
async def notify_participants(
    event_id: str = Path(..., title="Event ID"),
    notification: NotificationRequest = None,
    current_user=Depends(get_current_user)
):
    """Notify participants of an event (requires organizer authentication)"""
    return {
        "success": True,
        "event_id": event_id,
        "message": notification.message if notification else "Default notification",
        "recipients_affected": 150
    }