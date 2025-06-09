from datetime import datetime
from typing import Any, List, Optional

from app.models.events import EventModel
from pydantic import BaseModel, ConfigDict, model_validator


# EventBase is the base model for creating and handling events
class EventBase(BaseModel):
    organiser_id: int
    name: str
    description: Optional[str] = None
    start_date: datetime
    end_date: datetime
    minimum_age: Optional[int] = None
    location_id: int
    category: List[str]
    total_tickets: int


# EventBase is the base model for creating and handling events
class EventDetails(BaseModel):
    event_id: int
    organiser_id: int
    name: str
    description: str | None = None
    start_date: datetime
    end_date: datetime
    minimum_age: int | None = None
    location_name: str
    status: str
    categories: list[str] = []

    # Calculated fields
    total_tickets: int = 0

    model_config = ConfigDict(from_attributes=True)

    @model_validator(mode="before")
    @classmethod
    def convert_location(cls, data: Any) -> Any:
        """Convert Location relationship to location_name"""
        if isinstance(data, EventModel):
            return {
                **data.__dict__,
                "location_name": data.location.name if data.location else None,
                "total_tickets": sum(tt.max_count for tt in data.ticket_types),
            }
        return data


# EventUpdate is used for updating existing events
class EventUpdate(BaseModel):
    name: Optional[str] = None
    location_id: Optional[int] = None
    start_date: Optional[datetime] = None
    end_date: Optional[datetime] = None
    description: Optional[str] = None


class NotificationRequest(BaseModel):
    message: str
    urgent: bool = False
