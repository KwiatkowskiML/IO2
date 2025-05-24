import logging
from typing import List

from app.database import get_db
from sqlalchemy.orm import Session
from app.models.events import EventModel
from app.models.ticket import TicketModel
from app.repositories.cart_repository import CartRepository
from app.schemas.cart_scheme import CartItemWithDetails
from app.schemas.ticket import TicketDetails, TicketType
from app.models.location import LocationModel
from app.services.email import send_ticket_email
from app.models.ticket_type import TicketTypeModel
from app.utils.jwt_auth import get_user_from_token
from fastapi import Path, Header, Depends, APIRouter, HTTPException, status

router = APIRouter(
    prefix="/cart",
    tags=["cart"],
)

logger = logging.getLogger(__name__)


@router.get(
    "/items",
    response_model=List[CartItemWithDetails]
)
async def get_shopping_cart(
    authorization: str = Header(..., description="Bearer token"),
    db: Session = Depends(get_db),
):
    """Get items in the user's shopping cart"""
    # Get user info from JWT token
    user = get_user_from_token(authorization)
    logger.info(f"Get shopping cart of {user}")
    user_id = user["user_id"]
    logger.info(f"Get shopping cart for user_id {user_id}")

    repo = CartRepository(db)
    cart_items_models = repo.get_cart_items_details(customer_id=user_id)

    response_items: List[CartItemWithDetails] = []
    for item_model in cart_items_models:
        if item_model.ticket_type:
            cart_item_detail = CartItemWithDetails(
                ticket_type=TicketType.model_validate(item_model.ticket_type),
                quantity=item_model.quantity
            )
            response_items.append(cart_item_detail)
        else:
            logger.warning(f"Cart item with ID {item_model.cart_item_id} for user {user_id} is missing ticket_type details.")

    return response_items

@router.post(
    "/items",
    response_model=bool,
)
async def add_to_cart(
    item: TicketDetails,
    authorization: str = Header(..., description="Bearer token"),
    db: Session = Depends(get_db),
):
    """Add a ticket to the user's shopping cart"""
    # Get user info from JWT token
    user = get_user_from_token(authorization)

    # Verify the ticket type exists
    ticket_type = db.query(TicketTypeModel).filter(TicketTypeModel.type_id == item.type_id).first()
    if not ticket_type:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Ticket type with ID {item.type_id} not found",
        )
    logger.info(f"Add item {item} to cart of {user}")
    # TODO: add the item to a cart table
    return True


@router.delete(
    "/items/{ticket_id}",
    response_model=bool,
)
async def remove_from_cart(
    ticket_id: int = Path(..., title="Ticket ID", ge=1),
    authorization: str = Header(..., description="Bearer token"),
    db: Session = Depends(get_db),
):
    """Remove a ticket from the user's shopping cart"""
    # Get user info from JWT token
    user = get_user_from_token(authorization)
    logger.info(f"Remove {ticket_id} from cart of {user}")
    # TODO: remove the item from a cart table
    return True


@router.post(
    "/checkout",
    response_model=bool,
)
async def checkout_cart(
    authorization: str = Header(..., description="Bearer token"),
    db: Session = Depends(get_db),
):
    # Get user info from JWT token
    user = get_user_from_token(authorization)
    user_id = user["user_id"]
    user_email = user["email"]
    user_name = user["name"]

    logger.info(f"Processing checkout for user {user_id} ({user_email})")

    try:
        # Get the ticket type
        ticket_type = db.query(TicketTypeModel).filter(TicketTypeModel.type_id == 1).first()

        if not ticket_type:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Ticket type with ID {1} not found",
            )

        # Get event info
        event = db.query(EventModel).filter(EventModel.event_id == ticket_type.event_id).first()

        if not event:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Event not found for ticket type",
            )

        # Get venue info
        location = db.query(LocationModel).filter(LocationModel.location_id == event.location_id).first()

        if not location:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Location not found for event",
            )

        # Create a new ticket record
        new_ticket = TicketModel(
            type_id=ticket_type.type_id,
            owner_id=user_id,
            seat=None,
            resell_price=None,
        )

        db.add(new_ticket)
        db.commit()
        db.refresh(new_ticket)

        # Format date and time
        event_date = event.start_date.strftime("%B %d, %Y")
        event_time = event.start_date.strftime("%I:%M %p")

        # Send confirmation email
        email_sent = send_ticket_email(
            to_email=user_email,
            user_name=user_name,
            event_name=event.name,
            ticket_id=str(new_ticket.ticket_id),
            event_date=event_date,
            event_time=event_time,
            venue=location.name,
            seat=new_ticket.seat,
        )

        if not email_sent:
            logger.error(f"Failed to send confirmation email to {user_email}")
            # We don't fail the purchase if the email fails

        return True

    except Exception as e:
        logger.error(f"Error during checkout: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Checkout failed: {str(e)}",
        )
