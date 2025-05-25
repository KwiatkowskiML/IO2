"""
test_events_tickets_cart.py - Events, Tickets and Shopping Cart Tests
--------------------------------------------------------------------
Tests for event management, ticket types, tickets, and shopping cart functionality.

Environment Variables:
- API_BASE_URL: Base URL for API (default: http://localhost:8080/api)
- API_TIMEOUT: Request timeout in seconds (default: 10)
- ADMIN_SECRET_KEY: Admin secret key for registration

Run with: pytest test_events_tickets_cart.py -v
"""

import pytest

from helper import (
    APIClient, TokenManager, TestDataGenerator, UserManager, EventManager, CartManager,
    TicketManager,
    print_test_config
)


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


class TestEvents:
    """Test event management functionality"""

    @pytest.fixture(autouse=True)
    def setup(self, user_manager, event_manager):
        """Setup required users for event tests"""
        self.test_env = prepare_test_env(user_manager, event_manager, None)
        self.event_manager = event_manager

    def test_get_events_list_public(self, api_client):
        """Test getting list of events (public endpoint)"""
        response = api_client.get("/events")

        events = response.json()
        assert isinstance(events, list)

    def test_get_events_with_filters(self, event_manager):
        """Test getting events with filters"""
        # Test without filters
        events = event_manager.get_events()
        assert isinstance(events, list)

        # Test with filters (if supported)
        filtered_events = event_manager.get_events({"limit": 10})
        assert isinstance(filtered_events, list)

    def test_create_event_as_organizer(self, event_manager, test_data):
        """Test creating an event as organizer"""
        created_event = event_manager.create_event()

        assert created_event["name"] is not None
        assert created_event["description"] is not None
        assert "event_id" in created_event or "id" in created_event

    # TODO:
    # def test_create_event_unauthorized(self, api_client, token_manager, test_data):
    #     """Test that customers cannot create events"""
    #     event_data = test_data.event_data()
    #
    #     api_client.post(
    #         "/events/",
    #         headers={
    #             **token_manager.get_auth_header("customer"),
    #             "Content-Type": "application/json"
    #         },
    #         json_data=event_data,
    #         expected_status=403
    #     )

    # TODO:
    # def test_create_event_without_auth(self, api_client, test_data):
    #     """Test that creating events requires authentication"""
    #     event_data = test_data.event_data()
    #
    #     api_client.post(
    #         "/events/",
    #         headers={"Content-Type": "application/json"},
    #         json_data=event_data,
    #         expected_status=401
    #     )

    def test_update_event(self, event_manager, test_data):
        """Test updating an event"""
        # First create an event
        created_event = event_manager.create_event()
        event_id = created_event.get("event_id")
        assert event_id is not None

        update_data = {
            "name": "Updated Event Name",
            "description": "Updated description"
        }

        updated_event = event_manager.update_event(event_id, update_data)
        assert updated_event["name"] == update_data["name"]

    def test_admin_authorize_event(self, event_manager, token_manager):
        """Test admin authorizing an event"""
        # Create an event first
        created_event = event_manager.create_event()
        event_id = created_event.get("event_id")
        assert event_id is not None

        authorized = event_manager.authorize_event(event_id)
        assert authorized is True

    def test_delete_event(self, event_manager):
        """Test deleting/canceling an event"""
        # Create an event first
        created_event = event_manager.create_event()
        event_id = created_event.get("event_id")
        assert event_id is not None

        deleted = event_manager.delete_event(event_id)
        assert deleted is True

    # TODO: delete without auth


class TestTicketTypes:
    """Test ticket type management functionality"""

    @pytest.fixture(autouse=True)
    def setup(self, user_manager, event_manager):
        """Setup required users and events for ticket tests"""
        self.test_env = prepare_test_env(user_manager, event_manager, None)
        self.event_manager = event_manager

        # Create a test event
        try:
            self.test_event = event_manager.create_event()
        except Exception as e:
            print(f"Warning: Could not create test event: {e}")
            self.test_event = {"event_id": 1, "id": 1}

    def test_get_ticket_types_list_public(self, api_client):
        """Test getting list of ticket types (public endpoint)"""
        response = api_client.get("/ticket-types/")

        ticket_types = response.json()
        assert isinstance(ticket_types, list)

    def test_get_ticket_types_with_filters(self, event_manager):
        """Test getting ticket types with filters"""
        # Test without filters
        ticket_types = event_manager.get_ticket_types()
        assert isinstance(ticket_types, list)

        # Test with event filter
        event_id = self.test_event.get("event_id")
        assert event_id is not None
        filtered_types = event_manager.get_ticket_types({"event_id": event_id})
        assert isinstance(filtered_types, list)

        # Test with price filters
        price_filtered = event_manager.get_ticket_types({"min_price": 10, "max_price": 200})
        assert isinstance(price_filtered, list)

    def test_create_ticket_type_as_organizer(self, event_manager):
        """Test creating a ticket type as organizer"""
        event_id = self.test_event.get("event_id") or self.test_event.get("id") or 1

        created_ticket_type = event_manager.create_ticket_type(event_id)

        assert created_ticket_type["description"] is not None
        assert created_ticket_type["price"] is not None
        assert created_ticket_type["event_id"] == event_id

    # TODO:
    # def test_create_ticket_type_unauthorized(self, api_client, token_manager, test_data):
    #     """Test that customers cannot create ticket types"""
    #     ticket_data = test_data.ticket_type_data()
    #
    #     api_client.post(
    #         "/ticket-types/",
    #         headers={
    #             **token_manager.get_auth_header("customer"),
    #             "Content-Type": "application/json"
    #         },
    #         json_data=ticket_data,
    #         expected_status=403
    #     )

    # TODO:
    # def test_create_ticket_type_without_auth(self, api_client, test_data):
    #     """Test that creating ticket types requires authentication"""
    #     ticket_data = test_data.ticket_type_data()
    #
    #     api_client.post(
    #         "/ticket-types/",
    #         headers={"Content-Type": "application/json"},
    #         json_data=ticket_data,
    #         expected_status=401
    #     )

    def test_delete_ticket_type(self, event_manager):
        """Test deleting a ticket type"""
        # Create a ticket type first
        event_id = self.test_event.get("event_id")
        assert event_id is not None
        created_ticket_type = event_manager.create_ticket_type(event_id)
        type_id = created_ticket_type.get("type_id")
        assert type_id is not None

        deleted = event_manager.delete_ticket_type(type_id)
        assert deleted is True

    def test_ticket_type_validation(self, api_client, token_manager):
        """Test ticket type creation with invalid data"""
        invalid_ticket_data = {
            "event_id": 99999,  # Non-existent event
            "description": "",  # Empty description
            "price": -10,  # Negative price
            "max_count": 0,  # Zero max count
        }

        api_client.post(
            "/ticket-types/",
            headers={
                **token_manager.get_auth_header("organizer"),
                "Content-Type": "application/json"
            },
            json_data=invalid_ticket_data,
            expected_status=404
        )


class TestTickets:
    """Test ticket management functionality"""

    @pytest.fixture(autouse=True)
    def setup(self, user_manager, event_manager, ticket_manager):
        """Setup test environment"""
        self.test_env = prepare_test_env(user_manager, event_manager, None)
        self.ticket_manager = ticket_manager

    def test_list_tickets(self, ticket_manager):
        """Test listing tickets"""
        tickets = ticket_manager.list_tickets()
        assert isinstance(tickets, list)

    def test_list_tickets_with_filters(self, ticket_manager):
        """Test listing tickets with filters"""
        # Test with various filters
        filtered_tickets = ticket_manager.list_tickets({"user_id": 1})
        assert isinstance(filtered_tickets, list)

        event_tickets = ticket_manager.list_tickets({"event_id": 1})
        assert isinstance(event_tickets, list)

    def test_download_ticket(self, ticket_manager):
        """Test downloading ticket PDF"""
        ticket_pdf = ticket_manager.download_ticket(1)
        assert "pdf_data" in ticket_pdf
        assert "filename" in ticket_pdf

    # TODO:
    # def test_resell_ticket(self, ticket_manager):
    #     """Test putting ticket up for resale"""
    #     resold_ticket = ticket_manager.resell_ticket(
    #         1,
    #         150.00,
    #         "Selling due to scheduling conflict"
    #     )
    #     assert "ticket_id" in resold_ticket
    #
    # def test_cancel_resell(self, ticket_manager):
    #     """Test canceling ticket resale"""
    #     cancelled = ticket_manager.cancel_resell(1)
    #     assert "ticket_id" in cancelled


class TestShoppingCart:
    """Test shopping cart functionality"""

    @pytest.fixture(autouse=True)
    def setup(self, user_manager, event_manager, cart_manager):
        """Setup required users, events, and tickets for cart tests"""
        self.test_env = prepare_test_env(user_manager, event_manager, cart_manager)
        self.cart_manager = cart_manager
        self.event_manager = event_manager

        # Create test event and ticket type
        try:
            self.test_event = event_manager.create_event()
            event_id = self.test_event.get("event_id") or self.test_event.get("id") or 1
            self.test_ticket_type = event_manager.create_ticket_type(event_id)
        except Exception as e:
            print(f"Warning: Could not create test event/ticket: {e}")
            self.test_ticket_type = {"type_id": 1, "id": 1}

    def test_get_cart_items_empty(self, cart_manager):
        """Test getting empty cart"""
        cart_items = cart_manager.get_cart_items()
        assert isinstance(cart_items, list)

    def test_checkout_empty_cart(self, api_client, token_manager):
        """Test checkout with empty cart"""
        api_client.post(
            "/cart/checkout",
            headers=token_manager.get_auth_header("customer"),
            expected_status=404
        )

    def test_add_item_to_cart(self, cart_manager):
        """Test adding item to cart"""
        ticket_type_id = self.test_ticket_type.get("type_id")
        assert ticket_type_id is not None

        cart_item = cart_manager.add_item_to_cart(ticket_type_id=ticket_type_id, quantity=2)
        assert cart_item is not None
        assert "ticket_type" in cart_item or "quantity" in cart_item

    def test_get_cart_items_with_data(self, cart_manager):
        """Test getting cart items after adding"""
        ticket_type_id = self.test_ticket_type.get("type_id")

        cart_manager.add_item_to_cart(ticket_type_id=ticket_type_id, quantity=1)

        cart_items = cart_manager.get_cart_items()
        assert isinstance(cart_items, list)

    def test_remove_item_from_cart(self, cart_manager):
        """Test removing item from cart"""
        removed = cart_manager.remove_item_from_cart(1)
        assert isinstance(removed, bool)

    def test_add_to_cart_unauthorized(self, api_client):
        """Test that adding to cart requires customer authentication"""
        api_client.post(
            "/cart/items?ticket_type_id=1&quantity=1",
            expected_status=401
        )

    def test_add_multiple_items_to_cart(self, cart_manager):
        """Test adding multiple items to cart"""
        ticket_type_id = self.test_ticket_type.get("type_id")
        assert ticket_type_id is not None

        cart_item = cart_manager.add_item_to_cart(ticket_type_id=ticket_type_id, quantity=3)
        assert cart_item is not None

        cart_items = cart_manager.get_cart_items()
        assert isinstance(cart_items, list)

    def test_checkout_cart(self, cart_manager):
        """Test checkout process"""
        ticket_type_id = self.test_ticket_type.get("type_id")
        cart_manager.add_item_to_cart(ticket_type_id=ticket_type_id, quantity=1)

        checkout_result = cart_manager.checkout()
        assert isinstance(checkout_result, bool)


class TestEventTicketIntegration:
    """Test integration between events and ticket types"""

    @pytest.fixture(autouse=True)
    def setup(self, user_manager, event_manager):
        """Setup required users for integration tests"""
        self.test_env = prepare_test_env(user_manager, event_manager, None)
        self.event_manager = event_manager

    def test_event_with_multiple_ticket_types(self, event_manager):
        """Test creating an event with multiple ticket types"""
        event = event_manager.create_event()
        event_id = event.get("event_id")

        ticket_types = []
        for i in range(3):
            ticket_type = event_manager.create_ticket_type(event_id)
            ticket_types.append(ticket_type)

        for ticket_type in ticket_types:
            assert ticket_type["event_id"] == event_id

    def test_get_tickets_for_event(self, event_manager):
        """Test getting ticket types for a specific event"""
        event = event_manager.create_event()
        event_id = event.get("event_id")
        event_manager.create_ticket_type(event_id)

        event_tickets = event_manager.get_ticket_types({"event_id": event_id})
        assert isinstance(event_tickets, list)

        for ticket in event_tickets:
            if ticket:
                assert ticket.get("event_id") == event_id

    def test_ticket_type_price_filtering(self, event_manager):
        """Test filtering ticket types by price range"""
        # Create event and ticket types with different prices
        event = event_manager.create_event()
        event_id = event.get("event_id") or event.get("id") or 1

        for _ in range(2):
            event_manager.create_ticket_type(event_id)

        cheap_tickets = event_manager.get_ticket_types({"max_price": 100})
        expensive_tickets = event_manager.get_ticket_types({"min_price": 100})
        mid_range = event_manager.get_ticket_types({"min_price": 50, "max_price": 200})

        assert isinstance(cheap_tickets, list)
        assert isinstance(expensive_tickets, list)
        assert isinstance(mid_range, list)


class TestCartEventIntegration:
    """Test integration between shopping cart and events/tickets"""

    @pytest.fixture(autouse=True)
    def setup(self, user_manager, event_manager, cart_manager):
        """Setup complete test environment"""
        self.test_env = prepare_test_env(user_manager, event_manager, cart_manager)
        self.cart_manager = cart_manager
        self.event_manager = event_manager

        try:
            self.event = event_manager.create_event()
            event_id = self.event.get("event_id")

            self.ticket_types = []
            for i in range(2):
                ticket_type = event_manager.create_ticket_type(event_id)
                self.ticket_types.append(ticket_type)
        except Exception as e:
            print(f"Warning: Could not create test data: {e}")
            self.ticket_types = [{"type_id": 1, "id": 1}, {"type_id": 2, "id": 2}]

    def test_complete_purchase_flow(self, cart_manager):
        """Test complete flow: create event -> create tickets -> add to cart -> checkout"""
        # Add different ticket types to cart
        items_added = 0
        for i, ticket_type in enumerate(self.ticket_types):
            ticket_type_id = ticket_type.get("type_id")
            cart_manager.add_item_to_cart(ticket_type_id=ticket_type_id, quantity=1)
            items_added += 1

        cart_items = cart_manager.get_cart_items()
        assert isinstance(cart_items, list)

        checkout_result = cart_manager.checkout()
        assert checkout_result is not None

    def test_cart_item_validation(self, api_client, token_manager):
        """Test adding invalid items to cart"""
        # Try to add non-existent ticket type
        api_client.post(
            "/cart/items?ticket_type_id=99999&quantity=1",
            headers=token_manager.get_auth_header("customer"),
            expected_status=404  # Should fail
        )

        api_client.post(
            "/cart/items?ticket_type_id=1&quantity=-1",
            headers=token_manager.get_auth_header("customer"),
            expected_status=400  # Should fail validation
        )

    def test_concurrent_cart_operations(self, cart_manager):
        """Test concurrent cart operations"""
        import concurrent.futures

        ticket_type_id = self.ticket_types[0].get("type_id")
        results = []

        def add_to_cart():
            try:
                return cart_manager.add_item_to_cart(ticket_type_id=ticket_type_id, quantity=1)
            except Exception as e:
                return str(e)

        with concurrent.futures.ThreadPoolExecutor(max_workers=3) as executor:
            futures = [executor.submit(add_to_cart) for _ in range(3)]
            results = [future.result() for future in futures]

        successful = sum(1 for r in results if not isinstance(r, str))
        assert successful == 3, f"Expected 3 successful adds, got {successful} with results: {results}"


class TestDataConsistency:
    """Test data consistency across events, tickets, and cart operations"""

    @pytest.fixture(autouse=True)
    def setup(self, user_manager, event_manager):
        """Setup test environment"""
        self.test_env = prepare_test_env(user_manager, event_manager, None)
        self.event_manager = event_manager

    def test_event_ticket_relationship(self, api_client, event_manager):
        """Test that ticket types are properly linked to events"""
        event = event_manager.create_event()
        event_id = event.get("event_id") or event.get("id") or 1

        ticket_type = event_manager.create_ticket_type(event_id)
        assert ticket_type["event_id"] == event_id

        events_response = api_client.get("/events")
        events = events_response.json()

        event_ids = [e.get("event_id") for e in events if e]
        assert event_id in event_ids, f"Event ID {event_id} not found in events list"

    def test_ticket_availability_tracking(self, event_manager, cart_manager):
        """Test that ticket availability is properly tracked"""
        event = event_manager.create_event()
        event_id = event.get("event_id")

        ticket_type = event_manager.create_ticket_type(event_id)
        initial_max_count = ticket_type.get("max_count")
        assert initial_max_count is not None, "Ticket type max count should not be None"
        ticket_type_id = ticket_type.get("type_id")

        cart_manager.add_item_to_cart(ticket_type_id=ticket_type_id, quantity=1)

    def test_cross_component_data_integrity(self, event_manager, cart_manager):
        """Test data integrity across all components"""

        # 1. Create event
        event = event_manager.create_event()
        event_id = event.get("event_id")

        # 2. Create ticket type
        ticket_type = event_manager.create_ticket_type(event_id)
        ticket_type_id = ticket_type.get("type_id")

        cart_item = cart_manager.add_item_to_cart(ticket_type_id=ticket_type_id)
        assert ticket_type["event_id"] == event_id
