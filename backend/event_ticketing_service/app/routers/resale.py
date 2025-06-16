from typing import List, Optional
from fastapi import APIRouter, Depends, Query, HTTPException, status, Header
from sqlalchemy.orm import Session
from sqlalchemy import or_, and_, desc, asc

from app.database import get_db
from app.models.ticket import TicketModel
from app.models.ticket_type import TicketTypeModel
from app.models.events import EventModel
from app.models.location import LocationModel
from app.repositories.ticket_repository import TicketRepository, get_ticket_repository
from app.schemas.resale import ResaleTicketListing, BuyResaleTicketRequest
from app.schemas.ticket import TicketDetails
from app.utils.jwt_auth import get_user_from_token

router = APIRouter(prefix="/resale", tags=["resale"])


@router.get("/marketplace", response_model=List[ResaleTicketListing])
async def get_resale_marketplace(
        page: int = Query(1, ge=1, description="Page number"),
        limit: int = Query(50, ge=1, le=100, description="Items per page"),
        search: Optional[str] = Query(None, description="Search by event name or venue"),
        event_id: Optional[int] = Query(None, description="Filter by event ID"),
        venue: Optional[str] = Query(None, description="Filter by venue name"),
        min_price: Optional[float] = Query(None, ge=0, description="Minimum resale price"),
        max_price: Optional[float] = Query(None, ge=0, description="Maximum resale price"),
        min_original_price: Optional[float] = Query(None, ge=0, description="Minimum original price"),
        max_original_price: Optional[float] = Query(None, ge=0, description="Maximum original price"),
        event_date_from: Optional[str] = Query(None, description="Events from this date (YYYY-MM-DD)"),
        event_date_to: Optional[str] = Query(None, description="Events until this date (YYYY-MM-DD)"),
        has_seat: Optional[bool] = Query(None, description="Filter by tickets with assigned seats"),
        sort_by: str = Query("event_date", description="Sort field (event_date, resell_price, original_price, event_name)"),
        sort_order: str = Query("asc", description="Sort order (asc/desc)"),
        db: Session = Depends(get_db)
):
    """
    Get all tickets available for resale with advanced filtering, searching, and pagination
    """
    # Build the base query
    query = (
        db.query(
            TicketModel.ticket_id,
            TicketModel.resell_price,
            TicketModel.seat,
            TicketTypeModel.price.label("original_price"),
            TicketTypeModel.description.label("ticket_type_description"),
            EventModel.name.label("event_name"),
            EventModel.start_date.label("event_date"),
            LocationModel.name.label("venue_name")
        )
        .join(TicketTypeModel, TicketModel.type_id == TicketTypeModel.type_id)
        .join(EventModel, TicketTypeModel.event_id == EventModel.event_id)
        .join(LocationModel, EventModel.location_id == LocationModel.location_id)
        .filter(TicketModel.resell_price.isnot(None))
    )

    # Apply search filter
    if search:
        search_filter = f"%{search}%"
        query = query.filter(
            or_(
                EventModel.name.ilike(search_filter),
                LocationModel.name.ilike(search_filter),
                TicketTypeModel.description.ilike(search_filter)
            )
        )

    # Apply event filter
    if event_id:
        query = query.filter(EventModel.event_id == event_id)

    # Apply venue filter
    if venue:
        query = query.filter(LocationModel.name.ilike(f"%{venue}%"))

    # Apply resale price filters
    if min_price is not None:
        query = query.filter(TicketModel.resell_price >= min_price)
    if max_price is not None:
        query = query.filter(TicketModel.resell_price <= max_price)

    # Apply original price filters
    if min_original_price is not None:
        query = query.filter(TicketTypeModel.price >= min_original_price)
    if max_original_price is not None:
        query = query.filter(TicketTypeModel.price <= max_original_price)

    # Apply date filters
    if event_date_from:
        try:
            from datetime import datetime
            date_from = datetime.strptime(event_date_from, "%Y-%m-%d")
            query = query.filter(EventModel.start_date >= date_from)
        except ValueError:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid event_date_from format. Use YYYY-MM-DD"
            )

    if event_date_to:
        try:
            from datetime import datetime
            date_to = datetime.strptime(event_date_to, "%Y-%m-%d")
            # Add 23:59:59 to include the entire day
            date_to = date_to.replace(hour=23, minute=59, second=59)
            query = query.filter(EventModel.start_date <= date_to)
        except ValueError:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid event_date_to format. Use YYYY-MM-DD"
            )

    # Apply seat filter
    if has_seat is not None:
        if has_seat:
            query = query.filter(TicketModel.seat.isnot(None))
        else:
            query = query.filter(TicketModel.seat.is_(None))

    # Apply sorting
    if sort_by not in ["event_date", "resell_price", "original_price", "event_name"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid sort_by. Must be one of: event_date, resell_price, original_price, event_name"
        )

    if sort_order not in ["asc", "desc"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid sort_order. Must be 'asc' or 'desc'"
        )

    # Map sort fields
    sort_field_map = {
        "event_date": EventModel.start_date,
        "resell_price": TicketModel.resell_price,
        "original_price": TicketTypeModel.price,
        "event_name": EventModel.name
    }

    sort_field = sort_field_map[sort_by]
    if sort_order == "desc":
        query = query.order_by(desc(sort_field))
    else:
        query = query.order_by(asc(sort_field))

    # Apply pagination
    offset = (page - 1) * limit
    query = query.offset(offset).limit(limit)

    # Execute query
    results = query.all()

    # Convert to response model
    listings = []
    for r in results:
        listings.append(ResaleTicketListing(
            ticket_id=r.ticket_id,
            original_price=float(r.original_price),
            resell_price=float(r.resell_price),
            event_name=r.event_name,
            event_date=r.event_date,
            venue_name=r.venue_name,
            ticket_type_description=r.ticket_type_description,
            seat=r.seat
        ))

    return listings


@router.post("/purchase", response_model=TicketDetails)
async def purchase_resale_ticket(
        purchase_request: BuyResaleTicketRequest,
        authorization: str = Header(..., description="Bearer token"),
        ticket_repo: TicketRepository = Depends(get_ticket_repository)
):
    """Purchase a ticket from the resale marketplace"""
    user = get_user_from_token(authorization)
    buyer_id = user["user_id"]
    buyer_email = user["email"]
    buyer_name = user["name"]

    ticket = ticket_repo.buy_resale_ticket(purchase_request.ticket_id, buyer_id, buyer_email, buyer_name)
    return TicketDetails.model_validate(ticket)


@router.get("/my-listings", response_model=List[ResaleTicketListing])
async def get_my_resale_listings(
        page: int = Query(1, ge=1, description="Page number"),
        limit: int = Query(50, ge=1, le=100, description="Items per page"),
        search: Optional[str] = Query(None, description="Search by event name or venue"),
        min_price: Optional[float] = Query(None, ge=0, description="Minimum resale price"),
        max_price: Optional[float] = Query(None, ge=0, description="Maximum resale price"),
        sort_by: str = Query("event_date", description="Sort field (event_date, resell_price, original_price, event_name)"),
        sort_order: str = Query("asc", description="Sort order (asc/desc)"),
        authorization: str = Header(..., description="Bearer token"),
        db: Session = Depends(get_db)
):
    """
    Get all tickets I have listed for resale with pagination and filtering
    """
    user = get_user_from_token(authorization)
    user_id = user["user_id"]

    # Build the base query
    query = (
        db.query(
            TicketModel.ticket_id,
            TicketModel.resell_price,
            TicketModel.seat,
            TicketTypeModel.price.label("original_price"),
            TicketTypeModel.description.label("ticket_type_description"),
            EventModel.name.label("event_name"),
            EventModel.start_date.label("event_date"),
            LocationModel.name.label("venue_name")
        )
        .join(TicketTypeModel, TicketModel.type_id == TicketTypeModel.type_id)
        .join(EventModel, TicketTypeModel.event_id == EventModel.event_id)
        .join(LocationModel, EventModel.location_id == LocationModel.location_id)
        .filter(TicketModel.owner_id == user_id)
        .filter(TicketModel.resell_price.isnot(None))
    )

    # Apply search filter
    if search:
        search_filter = f"%{search}%"
        query = query.filter(
            or_(
                EventModel.name.ilike(search_filter),
                LocationModel.name.ilike(search_filter)
            )
        )

    # Apply price filters
    if min_price is not None:
        query = query.filter(TicketModel.resell_price >= min_price)
    if max_price is not None:
        query = query.filter(TicketModel.resell_price <= max_price)

    # Apply sorting
    if sort_by not in ["event_date", "resell_price", "original_price", "event_name"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid sort_by. Must be one of: event_date, resell_price, original_price, event_name"
        )

    if sort_order not in ["asc", "desc"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid sort_order. Must be 'asc' or 'desc'"
        )

    # Map sort fields
    sort_field_map = {
        "event_date": EventModel.start_date,
        "resell_price": TicketModel.resell_price,
        "original_price": TicketTypeModel.price,
        "event_name": EventModel.name
    }

    sort_field = sort_field_map[sort_by]
    if sort_order == "desc":
        query = query.order_by(desc(sort_field))
    else:
        query = query.order_by(asc(sort_field))

    # Apply pagination
    offset = (page - 1) * limit
    query = query.offset(offset).limit(limit)

    # Execute query
    results = query.all()

    # Convert to response model
    listings = []
    for r in results:
        listings.append(ResaleTicketListing(
            ticket_id=r.ticket_id,
            original_price=float(r.original_price),
            resell_price=float(r.resell_price),
            event_name=r.event_name,
            event_date=r.event_date,
            venue_name=r.venue_name,
            ticket_type_description=r.ticket_type_description,
            seat=r.seat
        ))

    return listings