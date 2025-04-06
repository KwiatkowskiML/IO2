from datetime import datetime
from typing import Optional

from pydantic import BaseModel

class EventBase(BaseModel):
    name: str
    location: str
    start_date: datetime
    end_date: datetime
    description: Optional[str] = None

class EventCreate(EventBase):
    pass

class EventDetails(EventBase):
    id: int
    organizer_id: int
    status: str
    total_tickets: int
    available_tickets: int

class EventUpdate(BaseModel):
    name: Optional[str] = None
    location: Optional[str] = None
    start_date: Optional[datetime] = None
    end_date: Optional[datetime] = None
    description: Optional[str] = None

class NotificationRequest(BaseModel):
    message: str
    urgent: bool = False