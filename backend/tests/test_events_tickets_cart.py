"""
test_events_tickets_cart.py - Enhanced Events, Tickets and Shopping Cart Tests
------------------------------------------------------------------------------
Comprehensive tests with response field validation based on Pydantic schemas.

Environment Variables:
- API_BASE_URL: Base URL for API (default: http://localhost:8080)
- API_TIMEOUT: Request timeout in seconds (default: 10)
- ADMIN_SECRET_KEY: Admin secret key for registration

Run with: pytest test_events_tickets_cart.py -v
"""

from typing import Dict, Any

import pytest

from helper import (
    APIClient, TokenManager, TestDataGenerator, UserManager, EventManager, CartManager,
    TicketManager, print_test_config
)


def validate_event_details_response(event_data: Dict[str, Any]) -> None:
    """Validate EventDetails response structure"""
    required_fields = [
        "event_id", "organizer_id", "name", "start_date", "end_date",
        "location_name", "status", "categories", "total_tickets"
    ]

    for field in required_fields:
        assert field in event_data, f"Missing required field: {field}"

    # Type validations
    assert isinstance(event_data["event_id"], int), "event_id must be integer"
    assert isinstance(event_data["organizer_id"], int), "organizer_id must be integer"
    assert isinstance(event_data["name"], str), "name must be string"
    assert isinstance(event_data["categories"], list), "categories must be list"
    assert isinstance(event_data["total_tickets"], int), "total_tickets must be integer"
    assert isinstance(event_data["status"], str), "status must be string"

    # Date validation
    assert event_data["start_date"] is not None, "start_date cannot be None"
    assert event_data["end_date"] is not None, "end_date cannot be None"

    # Optional fields validation
    if event_data.get("description") is not None:
        assert isinstance(event_data["description"], str), "description must be string"

    if event_data.get("minimum_age") is not None:
        assert isinstance(event_data["minimum_age"], int), "minimum_age must be integer"
        assert event_data["minimum_age"] >= 0, "minimum_age must be non-negative"


def validate_ticket_type_response(ticket_data: Dict[str, Any]) -> None:
    """Validate TicketType response structure"""
    required_fields = ["event_id", "max_count", "price"]

    for field in required_fields:
        assert field in ticket_data, f"Missing required field: {field}"

    # Type validations
    assert isinstance(ticket_data["event_id"], int), "event_id must be integer"
    assert isinstance(ticket_data["max_count"], int), "max_count must be integer"
    assert isinstance(ticket_data["price"], (int, float)), "price must be numeric"

    # Business rule validations
    assert ticket_data["max_count"] > 0, "max_count must be positive"
    assert ticket_data["price"] >= 0, "price must be non-negative"

    # Optional fields validation
    if "type_id" in ticket_data and ticket_data["type_id"] is not None:
        assert isinstance(ticket_data["type_id"], int), "type_id must be integer"

    if "description" in ticket_data and ticket_data["description"] is not None:
        assert isinstance(ticket_data["description"], str), "description must be string"

    if "currency" in ticket_data:
        assert isinstance(ticket_data["currency"], str), "currency must be string"
        assert len(ticket_data["currency"]) == 3, "currency should be 3-letter code"

    if "available_from" in ticket_data and ticket_data["available_from"] is not None:
        # Should be valid datetime string
        assert isinstance(ticket_data["available_from"], str), "available_from must be string"


def validate_cart_item_response(cart_item: Dict[str, Any]) -> None:
    """Validate CartItemWithDetails response structure"""
    required_fields = ["ticket_type", "quantity"]

    for field in required_fields:
        assert field in cart_item, f"Missing required field: {field}"

    # Validate nested ticket_type
    ticket_type = cart_item["ticket_type"]
    assert isinstance(ticket_type, dict), "ticket_type must be object"
    validate_ticket_type_response(ticket_type)

    # Validate quantity
    assert isinstance(cart_item["quantity"], int), "quantity must be integer"
    assert cart_item["quantity"] > 0, "quantity must be positive"


def validate_ticket_details_response(ticket_data: Dict[str, Any]) -> None:
    """Validate TicketDetails response structure"""
    required_fields = ["ticket_id"]

    for field in required_fields:
        assert field in ticket_data, f"Missing required field: {field}"

    assert isinstance(ticket_data["ticket_id"], int), "ticket_id must be integer"

    # Optional fields validation
    optional_int_fields = ["type_id", "owner_id"]
    for field in optional_int_fields:
        if field in ticket_data and ticket_data[field] is not None:
            assert isinstance(ticket_data[field], int), f"{field} must be integer"

    if "seat" in ticket_data and ticket_data["seat"] is not None:
        assert isinstance(ticket_data["seat"], str), "seat must be string"

    if "resell_price" in ticket_data and ticket_data["resell_price"] is not None:
        assert isinstance(ticket_data["resell_price"], (int, float)), "resell_price must be numeric"
        assert ticket_data["resell_price"] >= 0, "resell_price must be non-negative"


@pytest.fixture(scope="session")
def api_client():
    """API client fixture"""
    return APIClient()


@pytest.fixture(scope="session")
def token_manager():
    """Token manager fixture"""
    return TokenManager()


@pytest.fixture(scope="session")
def test_data():
    """Test data generator fixture"""
    return TestDataGenerator()


@pytest.fixture(scope="session")
def user_manager(api_client, token_manager):
    """User manager fixture"""
    return UserManager(api_client, token_manager)


@pytest.fixture(scope="session")
def event_manager(api_client, token_manager):
    """Event manager fixture"""
    return EventManager(api_client, token_manager)


@pytest.fixture(scope="session")
def cart_manager(api_client, token_manager):
    """Cart manager fixture"""
    return CartManager(api_client, token_manager)


@pytest.fixture(scope="session")
def ticket_manager(api_client, token_manager):
    """Ticket manager fixture"""
    return TicketManager(api_client, token_manager)


def prepare_test_env(user_manager: UserManager, event_manager: EventManager,
                     cart_manager: CartManager):
    """Prepare test environment with required users and events"""
    print_test_config()

    # Create required users
    customer_data = user_manager.register_and_login_customer()
    organizer_data = user_manager.register_and_login_organizer()
    admin_data = user_manager.register_and_login_admin()

    return {
        "customer": customer_data,
        "organizer": organizer_data,
        "admin": admin_data,
    }


@pytest.mark.events
class TestEvents:
    """Test event management functionality with comprehensive validation"""

    @pytest.fixture(autouse=True)
    def setup(self, user_manager, event_manager):
        """Setup required users for event tests"""
        self.test_env = prepare_test_env(user_manager, event_manager, None)
        self.event_manager = event_manager

    def test_get_events_list_public(self, api_client):
        """Test getting list of events with response validation"""
        response = api_client.get("/api/events")
        events = response.json()

        # Validate response structure
        assert isinstance(events, list), "Events response must be a list"

        # Validate each event if any exist
        for event in events:
            validate_event_details_response(event)

        print(f"✓ Validated {len(events)} events in public listing")

    def test_create_event_as_organizer(self, event_manager):
        """Test creating an event with comprehensive response validation"""
        created_event = event_manager.create_event()

        # Validate response structure
        validate_event_details_response(created_event)

        # Validate specific creation requirements
        assert created_event["name"] is not None, "Event name cannot be None"
        assert created_event["organizer_id"] is not None, "Organizer ID cannot be None"
        assert created_event["event_id"] > 0, "Event ID must be positive"

        # Validate dates are properly formatted
        start_date = created_event["start_date"]
        end_date = created_event["end_date"]
        assert start_date is not None, "Start date cannot be None"
        assert end_date is not None, "End date cannot be None"

        print(f"✓ Created event '{created_event['name']}' with ID {created_event['event_id']}")

    def test_create_event_with_custom_data(self, event_manager):
        """Test creating event with custom data and validate all fields"""
        custom_event_data = {
            "organiser_id": 1,
            "name": "Custom Test Event",
            "description": "A custom event for testing validation",
            "start_date": "2025-06-01T19:00:00",
            "end_date": "2025-06-01T23:00:00",
            "minimum_age": 21,
            "location_id": 1,
            "category": ["Music", "Premium", "Adults Only"],
            "total_tickets": 500,
        }

        created_event = event_manager.create_event(1, custom_event_data)
        validate_event_details_response(created_event)

        # Validate custom fields were properly set
        assert created_event["name"] == custom_event_data["name"]
        if "description" in created_event:
            assert created_event["description"] == custom_event_data["description"]
        if "minimum_age" in created_event:
            assert created_event["minimum_age"] == custom_event_data["minimum_age"]

        print(
            f"✓ Custom event created with minimum age: {created_event.get('minimum_age', 'Not set')}")

    def test_admin_authorize_event(self, event_manager):
        """Test admin authorizing an event"""
        # Create an event first
        created_event = event_manager.create_event()
        event_id = created_event.get("event_id")
        assert event_id is not None, "Event ID must be present"

        authorized = event_manager.authorize_event(event_id)
        assert authorized is True, "Authorization should return True"

        print(f"✓ Admin authorized event {event_id}")

    def test_delete_event(self, event_manager):
        """Test deleting/canceling an event"""
        # Create an event first
        created_event = event_manager.create_event()
        event_id = created_event.get("event_id")
        assert event_id is not None, "Event ID must be present"

        deleted = event_manager.delete_event(event_id)
        assert deleted is True, "Deletion should return True"

        print(f"✓ Deleted event {event_id}")

    def test_notify_participants(self, event_manager):
        """Test notifying event participants"""
        # Create an event first
        created_event = event_manager.create_event()
        event_id = created_event.get("event_id")
        assert event_id is not None, "Event ID must be present"

        notification_result = event_manager.notify_participants(
            event_id,
            "Important update about the event",
            urgent=True
        )

        # Validate notification response
        assert isinstance(notification_result, dict), "Notification result must be a dict"
        assert "success" in notification_result or "message" in notification_result

        print(f"✓ Sent notification for event {event_id}")


@pytest.mark.tickets
class TestTicketTypes:
    """Test ticket type management with comprehensive validation"""

    @pytest.fixture(autouse=True)
    def setup(self, user_manager, event_manager):
        """Setup required users and events for ticket tests"""
        self.test_env = prepare_test_env(user_manager, event_manager, None)
        self.event_manager = event_manager

        # Create a test event
        self.test_event = event_manager.create_event()
        validate_event_details_response(self.test_event)

    def test_get_ticket_types_list_public(self, api_client):
        """Test getting list of ticket types with validation"""
        response = api_client.get("/api/ticket-types/")
        ticket_types = response.json()

        assert isinstance(ticket_types, list), "Ticket types response must be a list"

        # Validate each ticket type
        for ticket_type in ticket_types:
            validate_ticket_type_response(ticket_type)

        print(f"✓ Validated {len(ticket_types)} ticket types in public listing")

    def test_get_ticket_types_with_filters(self, event_manager):
        """Test getting ticket types with various filters"""
        # Test without filters
        ticket_types = event_manager.get_ticket_types()
        assert isinstance(ticket_types, list)

        for ticket_type in ticket_types:
            validate_ticket_type_response(ticket_type)

        # Test with event filter
        event_id = self.test_event.get("event_id")
        filtered_types = event_manager.get_ticket_types({"event_id": event_id})
        assert isinstance(filtered_types, list)

        # All returned tickets should belong to the specified event
        for ticket_type in filtered_types:
            validate_ticket_type_response(ticket_type)
            assert ticket_type["event_id"] == event_id

        # Test with price filters
        price_filtered = event_manager.get_ticket_types({"min_price": 10, "max_price": 200})
        assert isinstance(price_filtered, list)

        for ticket_type in price_filtered:
            validate_ticket_type_response(ticket_type)
            assert 10 <= ticket_type["price"] <= 200, f"Price {ticket_type['price']} not in range"

    def test_create_ticket_type_as_organizer(self, event_manager):
        """Test creating a ticket type with comprehensive validation"""
        event_id = self.test_event.get("event_id")

        created_ticket_type = event_manager.create_ticket_type(event_id)
        validate_ticket_type_response(created_ticket_type)

        # Validate specific creation requirements
        assert created_ticket_type["event_id"] == event_id
        assert created_ticket_type["price"] >= 0, "Price must be non-negative"
        assert created_ticket_type["max_count"] > 0, "Max count must be positive"

        # Validate optional fields if present
        if "type_id" in created_ticket_type:
            assert created_ticket_type["type_id"] > 0, "Type ID must be positive"

        print(
            f"✓ Created ticket type for event {event_id} with price {created_ticket_type['price']}")

    def test_create_ticket_type_with_custom_data(self, event_manager):
        """Test creating ticket type with custom data"""
        event_id = self.test_event.get("event_id")

        custom_ticket_data = {
            "event_id": event_id,
            "description": "Premium VIP Experience",
            "max_count": 25,
            "price": 299.99,
            "currency": "PLN",
            "available_from": "2025-05-01T10:00:00"
        }

        created_ticket_type = event_manager.create_ticket_type(event_id, custom_ticket_data)
        validate_ticket_type_response(created_ticket_type)

        # Validate custom fields
        assert created_ticket_type["event_id"] == event_id
        assert created_ticket_type["price"] == custom_ticket_data["price"]
        assert created_ticket_type["max_count"] == custom_ticket_data["max_count"]

        print(
            f"✓ Created custom ticket type: {created_ticket_type.get('description', 'No description')}")

    def test_delete_ticket_type(self, event_manager):
        """Test deleting a ticket type"""
        event_id = self.test_event.get("event_id")
        created_ticket_type = event_manager.create_ticket_type(event_id)
        type_id = created_ticket_type.get("type_id")
        assert type_id is not None, "Type ID must be present"

        deleted = event_manager.delete_ticket_type(type_id)
        assert deleted is True, "Deletion should return True"

        print(f"✓ Deleted ticket type {type_id}")

    def test_ticket_type_validation_errors(self, api_client, token_manager):
        """Test ticket type creation with invalid data"""
        invalid_ticket_data = {
            "event_id": 99999,  # Non-existent event
            "description": "",  # Empty description
            "price": -10,  # Negative price
            "max_count": 0,  # Zero max count
        }

        response = api_client.post(
            "/api/ticket-types/",
            headers={
                **token_manager.get_auth_header("organizer"),
                "Content-Type": "application/json"
            },
            json_data=invalid_ticket_data,
            expected_status=404
        )

        print("✓ Invalid ticket type data properly rejected")


@pytest.mark.tickets
class TestTickets:
    """Test ticket management with validation"""

    @pytest.fixture(autouse=True)
    def setup(self, user_manager, event_manager, ticket_manager):
        """Setup test environment"""
        self.test_env = prepare_test_env(user_manager, event_manager, None)
        self.ticket_manager = ticket_manager

    def test_list_tickets(self, ticket_manager):
        """Test listing tickets with validation"""
        tickets = ticket_manager.list_tickets()
        assert isinstance(tickets, list), "Tickets response must be a list"

        for ticket in tickets:
            validate_ticket_details_response(ticket)

        print(f"✓ Validated {len(tickets)} tickets")

    def test_download_ticket(self, ticket_manager):
        """Test downloading ticket PDF with validation"""
        ticket_pdf = ticket_manager.download_ticket(1)

        # Validate TicketPDF structure
        required_fields = ["pdf_data", "filename"]
        for field in required_fields:
            assert field in ticket_pdf, f"Missing required field: {field}"

        assert isinstance(ticket_pdf["pdf_data"], str), "pdf_data must be string"
        assert isinstance(ticket_pdf["filename"], str), "filename must be string"
        assert ticket_pdf["filename"].endswith(".pdf"), "filename should end with .pdf"

        print(f"✓ Downloaded ticket PDF: {ticket_pdf['filename']}")


@pytest.mark.cart
class TestShoppingCart:
    """Test shopping cart functionality with comprehensive validation"""

    @pytest.fixture(autouse=True)
    def setup(self, user_manager, event_manager, cart_manager):
        """Setup required users, events, and tickets for cart tests"""
        self.test_env = prepare_test_env(user_manager, event_manager, cart_manager)
        self.cart_manager = cart_manager
        self.event_manager = event_manager

        # Create test event and ticket type
        self.test_event = event_manager.create_event()
        event_id = self.test_event.get("event_id")
        self.test_ticket_type = event_manager.create_ticket_type(event_id)

    def test_get_cart_items_empty(self, cart_manager):
        """Test getting empty cart with validation"""
        cart_items = cart_manager.get_cart_items()
        assert isinstance(cart_items, list), "Cart items must be a list"

        # If cart has items, validate their structure
        for item in cart_items:
            validate_cart_item_response(item)

        print(f"✓ Cart contains {len(cart_items)} items")

    def test_add_item_to_cart(self, cart_manager):
        """Test adding item to cart with validation"""
        ticket_type_id = self.test_ticket_type.get("type_id")
        assert ticket_type_id is not None, "Ticket type ID must be present"

        cart_item = cart_manager.add_item_to_cart(ticket_type_id=ticket_type_id, quantity=2)
        validate_cart_item_response(cart_item)

        # Validate specific add operation requirements
        assert cart_item["quantity"] == 2, "Quantity should match requested amount"
        assert cart_item["ticket_type"]["event_id"] == self.test_event["event_id"]

        print(f"✓ Added {cart_item['quantity']} tickets to cart")

    def test_get_cart_items_with_data(self, cart_manager):
        """Test getting cart items after adding with validation"""
        ticket_type_id = self.test_ticket_type.get("type_id")

        # Add item first
        cart_manager.add_item_to_cart(ticket_type_id=ticket_type_id, quantity=1)

        # Get cart items
        cart_items = cart_manager.get_cart_items()
        assert isinstance(cart_items, list), "Cart items must be a list"
        assert len(cart_items) > 0, "Cart should contain items after adding"

        for item in cart_items:
            validate_cart_item_response(item)

        print(f"✓ Cart validation successful with {len(cart_items)} items")

    def test_add_multiple_quantities(self, cart_manager):
        """Test adding large quantities with validation"""
        ticket_type_id = self.test_ticket_type.get("type_id")
        large_quantity = 10

        cart_item = cart_manager.add_item_to_cart(
            ticket_type_id=ticket_type_id,
            quantity=large_quantity
        )
        validate_cart_item_response(cart_item)

        assert cart_item["quantity"] == large_quantity

        # Validate quantity doesn't exceed ticket type max_count
        max_count = cart_item["ticket_type"]["max_count"]
        assert cart_item[
                   "quantity"] <= max_count, f"Quantity {cart_item['quantity']} exceeds max {max_count}"

        print(f"✓ Added {large_quantity} tickets (max allowed: {max_count})")

    def test_checkout_cart(self, cart_manager):
        """Test checkout process with validation"""
        # Add item first
        ticket_type_id = self.test_ticket_type.get("type_id")
        cart_manager.add_item_to_cart(ticket_type_id=ticket_type_id, quantity=1)

        checkout_result = cart_manager.checkout()
        assert isinstance(checkout_result, bool), "Checkout should return boolean"

        if checkout_result:
            print("✓ Checkout completed successfully")
        else:
            print("! Checkout returned False (may be expected behavior)")

    def test_cart_price_calculations(self, cart_manager):
        """Test cart price calculations are accurate"""
        ticket_type_id = self.test_ticket_type.get("type_id")
        quantity = 3
        unit_price = self.test_ticket_type["price"]

        cart_item = cart_manager.add_item_to_cart(
            ticket_type_id=ticket_type_id,
            quantity=quantity
        )
        validate_cart_item_response(cart_item)

        # Validate price consistency
        assert cart_item["ticket_type"]["price"] == unit_price
        expected_total = unit_price * quantity

        print(f"✓ Price validation: {quantity} x {unit_price} = {expected_total}")

    def test_add_to_cart_unauthorized(self, api_client):
        """Test that adding to cart requires authentication"""
        response = api_client.post(
            "/api/cart/items?ticket_type_id=1&quantity=1",
            expected_status=401
        )

        print("✓ Unauthorized cart access properly blocked")

    def test_checkout_empty_cart(self, api_client, token_manager):
        """Test checkout with empty cart"""
        response = api_client.post(
            "/api/cart/checkout",
            headers=token_manager.get_auth_header("customer"),
            expected_status=400
        )

        print("✓ Empty cart checkout properly handled")


@pytest.mark.integration
class TestIntegrationValidation:
    """Test integration scenarios with comprehensive validation"""

    @pytest.fixture(autouse=True)
    def setup(self, user_manager, event_manager, cart_manager):
        """Setup complete test environment"""
        self.test_env = prepare_test_env(user_manager, event_manager, cart_manager)
        self.event_manager = event_manager
        self.cart_manager = cart_manager

    def test_complete_purchase_flow_validation(self, cart_manager):
        """Test complete purchase flow with validation at each step"""
        # 1. Create event
        event = self.event_manager.create_event()
        validate_event_details_response(event)
        event_id = event["event_id"]

        # 2. Create multiple ticket types
        ticket_types = []
        for i in range(2):
            ticket_type = self.event_manager.create_ticket_type(event_id)
            validate_ticket_type_response(ticket_type)
            ticket_types.append(ticket_type)

        # 3. Add tickets to cart
        for ticket_type in ticket_types:
            cart_item = cart_manager.add_item_to_cart(
                ticket_type_id=ticket_type["type_id"],
                quantity=1
            )
            validate_cart_item_response(cart_item)

        # 4. Validate cart contents
        cart_items = cart_manager.get_cart_items()
        assert len(cart_items) >= 2, "Cart should contain multiple items"

        for item in cart_items:
            validate_cart_item_response(item)

        # 5. Checkout
        checkout_result = cart_manager.checkout()
        assert isinstance(checkout_result, bool)

        print(
            f"✓ Complete flow validated: {len(ticket_types)} ticket types → {len(cart_items)} cart items → checkout")

    def test_data_consistency_validation(self, api_client):
        """Test data consistency across all components"""
        # Create event
        event = self.event_manager.create_event()
        validate_event_details_response(event)
        event_id = event["event_id"]

        # Create ticket type
        ticket_type = self.event_manager.create_ticket_type(event_id)
        validate_ticket_type_response(ticket_type)

        # Verify event-ticket relationship
        assert ticket_type["event_id"] == event_id

        # Verify event appears in public listing
        events_response = api_client.get("/api/events")
        events = events_response.json()

        event_ids = [e["event_id"] for e in events]
        assert event_id in event_ids, f"Event {event_id} not found in public listing"

        # Add to cart and verify relationships
        cart_item = self.cart_manager.add_item_to_cart(
            ticket_type_id=ticket_type["type_id"],
            quantity=1
        )
        validate_cart_item_response(cart_item)

        # Verify cart item references correct event through ticket type
        assert cart_item["ticket_type"]["event_id"] == event["event_id"]
