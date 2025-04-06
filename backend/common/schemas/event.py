from datetime import datetime
from typing import Optional, List

from pydantic import BaseModel

# EventBase is the base model for creating and handling events
class EventBase(BaseModel):
    organizer_id: int
    name: str
    description: Optional[str] = None
    start: datetime
    end: datetime
    minimum_age: Optional[int] = None
    location: str
    category: List[str]
    total_tickets: int

# Details of the event, including its status and available tickets
class EventDetails(EventBase):
    id: int
    status: str
    available_tickets: int

# EventUpdate is used for updating existing events
class EventUpdate(BaseModel):
    name: Optional[str] = None
    location: Optional[str] = None
    start: Optional[datetime] = None
    end: Optional[datetime] = None
    description: Optional[str] = None

class NotificationRequest(BaseModel):
    message: str
    urgent: bool = False