from typing import Optional
from datetime import datetime

from fastapi import Query
from pydantic import BaseModel


class EventsFilter(BaseModel):
    """Filter for querying events."""

    name: Optional[str] = Query(None, title="Event Name", description="Partial match for event name")
    location: Optional[str] = Query(None, title="Location", description="Event location (exact match)")
    start_date_from: Optional[datetime] = Query(
        None, title="Start Date From", description="Events starting after this date"
    )
    start_date_to: Optional[datetime] = Query(
        None, title="Start Date To", description="Events starting before this date"
    )
    min_price: Optional[float] = Query(None, ge=0, title="Minimum Price", description="Minimum ticket price available")
    max_price: Optional[float] = Query(None, ge=0, title="Maximum Price", description="Maximum ticket price available")
    organizer_id: Optional[int] = Query(None, title="Organizer ID", description="Filter by specific organizer")
    minimum_age: Optional[int] = Query(
        None, ge=0, title="Minimum Age", description="Minimum required age for attendees"
    )
    has_available_tickets: Optional[bool] = Query(
        None, title="Has Available Tickets", description="Events with remaining tickets"
    )
    status: Optional[str] = Query(
        None, title="Event Status", description="Filter by event status (pending, created, rejected, cancelled)"
    )