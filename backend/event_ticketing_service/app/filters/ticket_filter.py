from typing import Optional

from fastapi import Query
from pydantic import BaseModel


class TicketFilter(BaseModel):
    """Filter for querying tickets."""

    event_id: Optional[int] = Query(None, title="Event ID", description="Filter by associated event")
    ticket_type_id: Optional[int] = Query(None, title="Ticket Type ID", description="Filter by ticket type")
    is_on_resale: Optional[bool] = Query(None, title="Is On Resale", description="Filter tickets that are on resale")
