import logging
from typing import List, Dict, Any
from fastapi import Depends
from fastapi import HTTPException, status
from sqlalchemy import func
from sqlalchemy.orm import Session, joinedload, selectinload

from app.models.shopping_cart_model import ShoppingCartModel
from app.models.cart_item_model import CartItemModel
from app.models.ticket_type import TicketTypeModel
from app.models.ticket import TicketModel
from app.models.events import EventModel
from app.services.email import send_ticket_email
from app.database import get_db

logger = logging.getLogger(__name__)

class CartRepository:
    def __init__(self, db: Session):
        self.db = db

    def get_or_create_cart(self, customer_id: int) -> ShoppingCartModel:
        # get shopping cart if there is one
        cart = self.db.query(ShoppingCartModel).filter(ShoppingCartModel.customer_id == customer_id).first()

        # if there is no cart, create one
        if not cart:
            cart = ShoppingCartModel(customer_id=customer_id)
            self.db.add(cart)
            self.db.commit()
            self.db.refresh(cart)
            logger.info(f"Created new cart_id {cart.cart_id} for customer_id {customer_id}")

        return cart

    def get_cart_items_details(self, customer_id: int) -> List[CartItemModel]:
        # Get the shopping cart for the customer
        cart = self.db.query(ShoppingCartModel).filter(ShoppingCartModel.customer_id == customer_id).first()
        if not cart:
            return []

        # return all items in the cart with eager loading of ticket_type
        return (
            self.db.query(CartItemModel)
            .filter(CartItemModel.cart_id == cart.cart_id)
            .options(selectinload(CartItemModel.ticket_type)) # Eager load ticket_type
            .all()
        )

    def add_item_from_detailed_sell(self, customer_id: int, ticket_type_id: int, quantity: int = 1) -> CartItemModel:
        if quantity < 1:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Quantity must be at least 1")

        # Verify the ticket type exists
        ticket_type = self.db.query(TicketTypeModel).filter(TicketTypeModel.type_id == ticket_type_id).first()
        if not ticket_type:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Ticket type with ID {ticket_type_id} not found",
            )

        # Get or create the shopping cart for the customer
        cart = self.get_or_create_cart(customer_id)

        existing_cart_item = (
            self.db.query(CartItemModel)
            .filter(CartItemModel.cart_id == cart.cart_id, CartItemModel.ticket_type_id == ticket_type_id)
            .first()
        )

        # If the item already exists in the cart, update the quantity
        if existing_cart_item:
            existing_cart_item.quantity += quantity
            logger.info(f"Updated quantity for ticket_type_id {ticket_type_id} in cart_id {cart.cart_id}. New quantity: {existing_cart_item.quantity}")
        else:
            existing_cart_item = CartItemModel(
                cart_id=cart.cart_id,
                ticket_type_id=ticket_type_id,
                quantity=quantity,
            )
            self.db.add(existing_cart_item)
            logger.info(f"Added ticket_type_id {ticket_type_id} with quantity {quantity} to cart_id {cart.cart_id}")

        self.db.commit()
        self.db.refresh(existing_cart_item)
        return existing_cart_item

    def remove_item(self, customer_id: int, cart_item_id: int) -> bool:
        # Get the shopping cart for the customer
        cart = self.db.query(ShoppingCartModel).filter(ShoppingCartModel.customer_id == customer_id).first()
        if not cart:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Shopping cart not found")

        # Find the cart item to remove
        cart_item_to_remove = (
            self.db.query(CartItemModel)
            .filter(CartItemModel.cart_item_id == cart_item_id, CartItemModel.cart_id == cart.cart_id)
            .first()
        )

        if not cart_item_to_remove:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Item with ID {cart_item_id} not found in your cart",
            )

        self.db.delete(cart_item_to_remove)
        self.db.commit()
        logger.info(f"Removed cart_item_id {cart_item_id} from cart_id {cart.cart_id} of customer_id {customer_id}")
        return True


    # TODO: Stripe integration for payment processing
    def checkout(self, customer_id: int, user_email: str, user_name: str) -> bool:
        # Get or create the shopping cart for the customer to handle cases where the user has never had a cart.
        cart = self.get_or_create_cart(customer_id)

        # Get all items in the cart with eager loading of related data
        cart_items = (
            self.db.query(CartItemModel)
            .filter(CartItemModel.cart_id == cart.cart_id)
            .options(
                joinedload(CartItemModel.ticket_type)
                .joinedload(TicketTypeModel.event)
                .joinedload(EventModel.location)
            ) # Eager load related data
            .all()
        )

        if not cart_items:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Shopping cart is empty")

        processed_tickets_info: List[Dict[str, Any]] = []

        try:
            for item in cart_items:
                ticket_type = item.ticket_type
                event = ticket_type.event
                location = event.location

                # Basic validation
                if not all([ticket_type, event, location]):
                    logger.error(f"Incomplete data for cart_item_id {item.cart_item_id}. "
                                 f"TicketType: {bool(ticket_type)}, Event: {bool(event)}, Location: {bool(location)}")
                    raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Error processing cart item details.")

                # Check if there are enough tickets available
                existing_tickets_count = (
                    self.db.query(func.count(TicketModel.ticket_id))
                    .filter(TicketModel.type_id == ticket_type.type_id)
                    .scalar()  # Gets the single count value
                )

                if existing_tickets_count + item.quantity > ticket_type.max_count:
                    available_tickets = ticket_type.max_count - existing_tickets_count
                    logger.warning(
                        f"Not enough tickets for event '{event.name}', type '{ticket_type.description if hasattr(ticket_type, 'description') else ticket_type.type_id}'. "
                        f"Requested: {item.quantity}, Available: {available_tickets if available_tickets >= 0 else 0}, "
                        f"Existing: {existing_tickets_count}, Max: {ticket_type.max_count}"
                    )
                    raise HTTPException(
                        status_code=status.HTTP_400_BAD_REQUEST,
                        detail=f"Not enough tickets available for '{event.name} - {ticket_type.description if hasattr(ticket_type, 'description') else 'selected type'}'. "
                               f"Only {available_tickets if available_tickets >= 0 else 0} left."
                    )

                for _ in range(item.quantity):
                    new_ticket = TicketModel(
                        type_id=ticket_type.type_id,
                        owner_id=customer_id,
                        seat=None,
                        resell_price=None,
                    )
                    self.db.add(new_ticket)
                    processed_tickets_info.append({
                        "ticket_model": new_ticket,
                        "event_name": event.name,
                        "event_date": event.start_date.strftime("%B %d, %Y"),
                        "event_time": event.start_date.strftime("%I:%M %p"),
                        "venue_name": location.name,
                        "seat": new_ticket.seat,
                    })

            # Clear the cart items after successful checkout
            for item in cart_items:
                self.db.delete(item)
            self.db.commit()

            # Refresh tickets to get their IDs and send emails
            for info in processed_tickets_info:
                self.db.refresh(info["ticket_model"])
                email_sent = send_ticket_email(
                    to_email=user_email,
                    user_name=user_name,
                    event_name=info["event_name"],
                    ticket_id=str(info["ticket_model"].ticket_id),
                    event_date=info["event_date"],
                    event_time=info["event_time"],
                    venue=info["venue_name"],
                    seat=info["seat"],
                )
                if not email_sent:
                    logger.error(f"Failed to send confirmation email for ticket {info['ticket_model'].ticket_id} to {user_email}")

            logger.info(f"Checkout successful for user_id {customer_id}. {len(processed_tickets_info)} ticket(s) created.")
            return True

        except HTTPException: # Re-raise HTTPExceptions from this function or called ones
            self.db.rollback()
            raise
        except Exception as e:
            self.db.rollback()
            logger.error(f"Error during checkout for user_id {customer_id}: {str(e)}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Checkout failed due to an internal error.",
            )

# Dependency to get the CartRepository instance
def get_cart_repository(db: Session = Depends(get_db)) -> CartRepository:
    return CartRepository(db)
