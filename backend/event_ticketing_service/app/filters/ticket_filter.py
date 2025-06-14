from typing import Optional

from fastapi import Query
from pydantic import BaseModel


class TicketFilter(BaseModel):
    """Filter for querying tickets."""

    ticket_id: Optional[int] = Query(None, title="Ticket ID", description="Filter by associated id")
    type_id: Optional[int] = Query(None, title="Ticket Type ID", description="Filter by ticket type")
    owner_id: Optional[int] = Query(None, title="Owner ID", description="Filter by ticket owner")
    is_on_resale: Optional[bool] = Query(None, title="Is On Resale", description="Filter tickets that are on resale")
