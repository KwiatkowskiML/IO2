from typing import Optional

from fastapi import Query
from pydantic import BaseModel


class TicketTypeFilter(BaseModel):
    """Filter for ticket types."""

    type_id: Optional[int] = Query(None, title="Ticket Type ID")
    event_id: Optional[int] = Query(None, title="Event ID")
    min_price: Optional[float] = Query(None, ge=0, title="Minimum Price")
    max_price: Optional[float] = Query(None, ge=0, title="Maximum Price")
