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

        # Return all items in the cart with eager loading of both ticket_type and ticket
        cart_items = (
            self.db.query(CartItemModel)
            .filter(CartItemModel.cart_id == cart.cart_id)
            .options(
                selectinload(CartItemModel.ticket_type),  # For regular ticket types
                joinedload(CartItemModel.ticket)  # For individual resale tickets
                .joinedload(TicketModel.ticket_type)  # Load ticket type for resale tickets
            )
            .all()
        )
        
        # For cart items with individual tickets (resale), we need to populate the ticket_type relationship
        for item in cart_items:
            if item.ticket_id and not item.ticket_type_id:
                # This is a resale ticket, use the ticket's ticket_type
                if item.ticket and item.ticket.ticket_type:
                    item.ticket_type = item.ticket.ticket_type
        
        return cart_items

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

    def add_resale_ticket_to_cart(self, customer_id: int, ticket_id: int) -> CartItemModel:
        """Add a resale ticket to the cart using ticket_id"""
        # Verify the ticket exists and load its ticket_type
        ticket = (
            self.db.query(TicketModel)
            .options(joinedload(TicketModel.ticket_type))
            .filter(TicketModel.ticket_id == ticket_id)
            .first()
        )
        if not ticket:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Ticket with ID {ticket_id} not found",
            )

        # Additional validation should be done in the route handler
        # Here we just add it to the cart

        # Get or create the shopping cart for the customer
        cart = self.get_or_create_cart(customer_id)

        # Check if this specific ticket is already in the cart
        existing_cart_item = (
            self.db.query(CartItemModel)
            .filter(CartItemModel.cart_id == cart.cart_id, CartItemModel.ticket_id == ticket_id)
            .first()
        )

        if existing_cart_item:
            # Resale tickets can't have quantity > 1, so we don't increase quantity
            logger.info(f"Resale ticket_id {ticket_id} is already in cart_id {cart.cart_id}")
            # Make sure the ticket_type relationship is populated
            existing_cart_item.ticket_type = ticket.ticket_type
            return existing_cart_item
        else:
            # Add the resale ticket to cart
            cart_item = CartItemModel(
                cart_id=cart.cart_id,
                ticket_id=ticket_id,
                quantity=1,  # Resale tickets always have quantity 1
            )
            self.db.add(cart_item)
            logger.info(f"Added resale ticket_id {ticket_id} to cart_id {cart.cart_id}")

        self.db.commit()
        self.db.refresh(cart_item)
        
        # Manually set the ticket_type relationship for the response
        # Since this is a resale ticket, use the ticket's ticket_type
        cart_item.ticket_type = ticket.ticket_type
        
        return cart_item

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

        # Get all items in the cart with eager loading of related data for both regular and resale tickets
        cart_items = (
            self.db.query(CartItemModel)
            .filter(CartItemModel.cart_id == cart.cart_id)
            .options(
                # For regular ticket types
                joinedload(CartItemModel.ticket_type)
                .joinedload(TicketTypeModel.event)
                .joinedload(EventModel.location),
                # For resale tickets
                joinedload(CartItemModel.ticket)
                .joinedload(TicketModel.ticket_type)
                .joinedload(TicketTypeModel.event)
                .joinedload(EventModel.location)
            )
            .all()
        )

        if not cart_items:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Shopping cart is empty")

        processed_tickets_info: List[Dict[str, Any]] = []

        try:
            for item in cart_items:
                # Determine if this is a regular ticket type or a resale ticket
                if item.ticket_type_id:
                    # Regular ticket type purchase
                    self._process_regular_ticket_item(item, customer_id, processed_tickets_info)
                elif item.ticket_id:
                    # Resale ticket purchase
                    self._process_resale_ticket_item(item, customer_id, processed_tickets_info)
                else:
                    logger.error(f"Cart item {item.cart_item_id} has neither ticket_type_id nor ticket_id")
                    raise HTTPException(
                        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                        detail="Invalid cart item found"
                    )

            # Clear the cart items after successful checkout
            for item in cart_items:
                self.db.delete(item)
            self.db.commit()

            # Send confirmation emails
            for info in processed_tickets_info:
                if 'ticket_model' in info:
                    self.db.refresh(info["ticket_model"])
                    ticket_id_str = str(info["ticket_model"].ticket_id)
                else:
                    ticket_id_str = str(info["ticket_id"])
                    
                email_sent = send_ticket_email(
                    to_email=user_email,
                    user_name=user_name,
                    event_name=info["event_name"],
                    ticket_id=ticket_id_str,
                    event_date=info["event_date"],
                    event_time=info["event_time"],
                    venue=info["venue_name"],
                    seat=info["seat"],
                )
                if not email_sent:
                    logger.error(f"Failed to send confirmation email for ticket {ticket_id_str} to {user_email}")

            logger.info(f"Checkout successful for user_id {customer_id}. {len(processed_tickets_info)} ticket(s) processed.")
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

    def _process_regular_ticket_item(self, item: CartItemModel, customer_id: int, processed_tickets_info: List[Dict[str, Any]]):
        """Process a regular ticket type purchase"""
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

        # Create new tickets
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

    def _process_resale_ticket_item(self, item: CartItemModel, customer_id: int, processed_tickets_info: List[Dict[str, Any]]):
        """Process a resale ticket purchase"""
        ticket = item.ticket
        ticket_type = ticket.ticket_type
        event = ticket_type.event
        location = event.location

        # Basic validation
        if not all([ticket, ticket_type, event, location]):
            logger.error(f"Incomplete data for resale cart_item_id {item.cart_item_id}. "
                         f"Ticket: {bool(ticket)}, TicketType: {bool(ticket_type)}, Event: {bool(event)}, Location: {bool(location)}")
            raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Error processing resale ticket details.")

        # Validate that the ticket is available for resale
        if ticket.resell_price is None:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Ticket {ticket.ticket_id} is not available for resale"
            )

        if ticket.owner_id == customer_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="You cannot buy your own ticket"
            )

        # Transfer ownership of the resale ticket
        ticket.owner_id = customer_id
        ticket.resell_price = None  # Clear resale price since it's no longer for sale

        processed_tickets_info.append({
            "ticket_id": ticket.ticket_id,
            "event_name": event.name,
            "event_date": event.start_date.strftime("%B %d, %Y"),
            "event_time": event.start_date.strftime("%I:%M %p"),
            "venue_name": location.name,
            "seat": ticket.seat,
        })

# Dependency to get the CartRepository instance
def get_cart_repository(db: Session = Depends(get_db)) -> CartRepository:
    return CartRepository(db)
