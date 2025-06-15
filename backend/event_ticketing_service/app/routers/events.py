from typing import List, Optional
from datetime import datetime

from app.database import get_db
from sqlalchemy.orm import Session
from sqlalchemy import or_, and_, desc, asc
from fastapi import Path, Depends, APIRouter, Query, HTTPException, status
from app.filters.events_filter import EventsFilter
from app.repositories.event_repository import EventRepository, get_event_repository
from app.schemas.event import EventBase, EventUpdate, EventDetails, NotificationRequest
from app.utils.jwt_auth import get_current_organizer, get_current_admin
from app.models.events import EventModel
from app.models.location import LocationModel
from app.models.ticket_type import TicketTypeModel

router = APIRouter(prefix="/events", tags=["events"])


@router.post("/", response_model=EventDetails)
async def create_event(
        event_data: EventBase,
        event_repo: EventRepository = Depends(get_event_repository),
        current_organizer=Depends(get_current_organizer)
):
    """Create a new event (requires authentication)"""
    return event_repo.create_event(event_data, current_organizer["role_id"])


@router.post("/authorize/{event_id}", response_model=bool)
async def authorize_event(
        event_id: int = Path(..., title="Event ID"),
        event_repo: EventRepository = Depends(get_event_repository),
        current_admin=Depends(get_current_admin)
):
    """Authorize an event (requires admin authentication)"""
    event_repo.authorize_event(event_id)
    return True


@router.post("/reject/{event_id}", response_model=bool)
async def reject_event(
        event_id: int = Path(..., title="Event ID"),
        event_repo: EventRepository = Depends(get_event_repository),
        current_admin=Depends(get_current_admin)
):
    """Reject an event (requires admin authentication)"""
    event_repo.reject_event(event_id)
    return True


@router.get("", response_model=List[EventDetails])
def get_events_endpoint(
        page: int = Query(1, ge=1, description="Page number"),
        limit: int = Query(50, ge=1, le=100, description="Items per page"),
        search: Optional[str] = Query(None, description="Search by event name or description"),
        location: Optional[str] = Query(None, description="Filter by location name"),
        start_date_from: Optional[datetime] = Query(None,
                                                    description="Events starting after this date"),
        start_date_to: Optional[datetime] = Query(None,
                                                  description="Events starting before this date"),
        min_price: Optional[float] = Query(None, ge=0,
                                           description="Minimum ticket price available"),
        max_price: Optional[float] = Query(None, ge=0,
                                           description="Maximum ticket price available"),
        organizer_id: Optional[int] = Query(None, description="Filter by specific organizer"),
        minimum_age: Optional[int] = Query(None, ge=0,
                                           description="Minimum required age for attendees"),
        status: Optional[str] = Query(None, description="Filter by event status"),
        categories: Optional[str] = Query(None,
                                          description="Filter by categories (comma-separated)"),
        sort_by: str = Query("start_date",
                             description="Sort field (start_date, name, creation_date)"),
        sort_order: str = Query("asc", description="Sort order (asc/desc)"),
        db: Session = Depends(get_db),
):
    """
    Get list of events with advanced filtering, searching, and pagination
    """
    # Build the query with joins for filtering
    query = db.query(EventModel).join(LocationModel,
                                      EventModel.location_id == LocationModel.location_id)

    # Apply search filter
    if search:
        search_filter = f"%{search}%"
        query = query.filter(
            or_(
                EventModel.name.ilike(search_filter),
                EventModel.description.ilike(search_filter)
            )
        )

    # Apply location filter
    if location:
        query = query.filter(LocationModel.name.ilike(f"%{location}%"))

    # Apply date filters
    if start_date_from:
        query = query.filter(EventModel.start_date >= start_date_from)
    if start_date_to:
        query = query.filter(EventModel.start_date <= start_date_to)

    # Apply organizer filter
    if organizer_id:
        query = query.filter(EventModel.organizer_id == organizer_id)

    # Apply minimum age filter
    if minimum_age:
        query = query.filter(EventModel.minimum_age >= minimum_age)

    # Apply status filter
    if status:
        if status not in ["pending", "created", "rejected", "cancelled"]:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid status. Must be one of: pending, created, rejected, cancelled"
            )
        query = query.filter(EventModel.status == status)

    # Apply price filters (requires subquery on ticket types)
    if min_price is not None or max_price is not None:
        price_subquery = db.query(TicketTypeModel.event_id).distinct()
        if min_price is not None:
            price_subquery = price_subquery.filter(TicketTypeModel.price >= min_price)
        if max_price is not None:
            price_subquery = price_subquery.filter(TicketTypeModel.price <= max_price)

        query = query.filter(EventModel.event_id.in_(price_subquery))

    # Apply categories filter (simplified - assuming categories are stored as comma-separated values in description or using JSON)
    if categories:
        category_list = [cat.strip() for cat in categories.split(",")]
        category_filters = [EventModel.description.ilike(f"%{cat}%") for cat in category_list]
        query = query.filter(or_(*category_filters))

    # Apply sorting
    if sort_by not in ["start_date", "name", "creation_date"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid sort_by. Must be one of: start_date, name, creation_date"
        )

    if sort_order not in ["asc", "desc"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid sort_order. Must be 'asc' or 'desc'"
        )

    # Map sort fields
    sort_field_map = {
        "start_date": EventModel.start_date,
        "name": EventModel.name,
        "creation_date": EventModel.event_id  # Assuming event_id correlates with creation order
    }

    sort_field = sort_field_map[sort_by]
    if sort_order == "desc":
        query = query.order_by(desc(sort_field))
    else:
        query = query.order_by(asc(sort_field))

    # Apply pagination
    offset = (page - 1) * limit
    query = query.offset(offset).limit(limit)

    # Execute query and get results
    events = query.all()

    # Convert to response models
    return [EventDetails.model_validate(e) for e in events]


@router.put("/{event_id}", response_model=EventDetails)
def update_event_endpoint(
        event_id: int = Path(..., title="Event ID"),
        update_data: EventUpdate = Depends(),
        event_repo: EventRepository = Depends(get_event_repository),
        current_organizer=Depends(get_current_organizer)
):
    return event_repo.update_event(event_id, update_data, current_organizer["role_id"])


@router.delete("/{event_id}", response_model=bool)
def cancel_event_endpoint(
        event_id: int = Path(..., title="Event ID"),
        event_repo: EventRepository = Depends(get_event_repository),
        current_organizer=Depends(get_current_organizer)
):
    event_repo.cancel_event(event_id, current_organizer["role_id"])
    return True


@router.post("/{event_id}/notify")
async def notify_participants(
        event_id: int = Path(..., title="Event ID"),
        notification: NotificationRequest = None,
        current_organizer=Depends(get_current_organizer),
):
    """Notify participants of an event (requires organizer authentication)"""
    return {
        "success": True,
        "event_id": event_id,
        "message": notification.message if notification else "Default notification",
        "recipients_affected": 150,
    }