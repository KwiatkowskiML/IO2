from typing import List, Optional
from fastapi import APIRouter, Depends, Query, HTTPException, status, Header
from sqlalchemy.orm import Session

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
        event_id: Optional[int] = Query(None, description="Filter by event ID"),
        min_price: Optional[float] = Query(None, ge=0, description="Minimum resale price"),
        max_price: Optional[float] = Query(None, ge=0, description="Maximum resale price"),
        db: Session = Depends(get_db)
):
    """Get all tickets available for resale"""
    # Query tickets with resell_price set
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

    # Apply filters
    if event_id:
        query = query.filter(EventModel.event_id == event_id)
    if min_price is not None:
        query = query.filter(TicketModel.resell_price >= min_price)
    if max_price is not None:
        query = query.filter(TicketModel.resell_price <= max_price)

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

    ticket = ticket_repo.buy_resale_ticket(purchase_request.ticket_id, buyer_id)
    return TicketDetails.model_validate(ticket)


@router.get("/my-listings", response_model=List[ResaleTicketListing])
async def get_my_resale_listings(
        authorization: str = Header(..., description="Bearer token"),
        db: Session = Depends(get_db)
):
    """Get all tickets I have listed for resale"""
    user = get_user_from_token(authorization)
    user_id = user["user_id"]

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

    results = query.all()

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
