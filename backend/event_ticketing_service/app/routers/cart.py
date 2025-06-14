import logging
from typing import List

from app.database import get_db
from sqlalchemy.orm import Session
from app.models.events import EventModel
from app.models.ticket import TicketModel
from app.repositories.cart_repository import CartRepository, get_cart_repository
from app.repositories.ticket_repository import TicketRepository, get_ticket_repository
from app.schemas.cart_scheme import CartItemWithDetails
from app.schemas.ticket import TicketDetails, TicketType
from app.models.location import LocationModel
from app.services.email import send_ticket_email
from app.models.ticket_type import TicketTypeModel
from app.utils.jwt_auth import get_user_from_token 
from fastapi import Path, Depends, APIRouter, HTTPException, status, Query

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
    user: dict = Depends(get_user_from_token),
    cart_repo: CartRepository = Depends(get_cart_repository)
):
    """Get items in the user's shopping cart"""
    logger.info(f"Get shopping cart of {user}")
    user_id = user["user_id"]
    logger.info(f"Get shopping cart for user_id {user_id}")

    cart_items_models = cart_repo.get_cart_items_details(customer_id=user_id)

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
    response_model=CartItemWithDetails,
)
async def add_to_cart(
    ticket_id: int = Query(None, description="ID of the resale ticket to add"),
    ticket_type_id: int = Query(None, description="ID of the ticket type to add"),
    quantity: int = Query(1, description="Quantity of tickets to add"),
    user: dict = Depends(get_user_from_token),
    ticket_repo: TicketRepository = Depends(get_ticket_repository),
    cart_repo: CartRepository = Depends(get_cart_repository)
):
    """Add a ticket to the user's shopping cart"""
    user_id = user["user_id"]

    # Verify the ticket type exists
    ticket_type = ticket_repo.get_ticket_type_by_id(ticket_type_id)
    if not ticket_type:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Ticket type with ID {ticket_type_id} not found",
        )
    logger.info(f"Add item {ticket_type} to cart of {user}")

    try:
        cart_item_model = cart_repo.add_item_from_detailed_sell(
            customer_id=user_id,
            ticket_type_id=ticket_type_id,
            quantity=quantity
        )

        if not cart_item_model.ticket_type:
            # This should ideally not happen if add_item works correctly and ticket_type exists
            logger.error(
                f"Ticket type details not found for cart_item_id {cart_item_model.cart_item_id} after adding to cart.")
            raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                                detail="Error retrieving ticket type details after adding to cart.")

        return CartItemWithDetails(
            ticket_type=TicketType.model_validate(cart_item_model.ticket_type),
            quantity=cart_item_model.quantity
        )
    except HTTPException as e:
        # Re-raise HTTPExceptions from the repository (e.g., not found, bad request)
        raise e
    except Exception as e:
        logger.error(f"Error adding item to cart for user {user_id}: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Could not add item to cart.",
        )


@router.delete(
    "/items/{cart_item_id}",
    response_model=bool,
)
async def remove_from_cart(
    cart_item_id: int = Path(..., title="Cart Item ID", ge=1),
    user: dict = Depends(get_user_from_token),
    cart_repo = Depends(get_cart_repository)
):
    """Remove a ticket from the user's shopping cart"""
    logger.info(f"Remove {cart_item_id} from cart of {user}")
    return cart_repo.remove_item(customer_id=user["user_id"], cart_item_id=cart_item_id)

@router.post(
    "/checkout",
    response_model=bool,
)
async def checkout_cart(
    user: dict = Depends(get_user_from_token),
    cart_repo: CartRepository = Depends(get_cart_repository)
):
    user_id = user["user_id"]
    user_email = user["email"]
    user_name = user["name"]

    logger.info(f"Processing checkout for user {user_id} ({user_email})")
    return cart_repo.checkout(
        customer_id=user_id,
        user_email=user_email,
        user_name=user_name,
    )
