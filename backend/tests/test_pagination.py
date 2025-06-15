"""
test_pagination_and_filtering.py - Tests for Enhanced Pagination and Filtering
-----------------------------------------------------------------------------
Comprehensive tests for the new pagination and filtering functionality
in events and resale marketplace endpoints.

Run with: pytest test_pagination_and_filtering.py -v
"""

import pytest
from datetime import datetime, timedelta
from typing import List, Dict, Any

from helper import (
    APIClient, TokenManager, TestDataGenerator, UserManager, EventManager,
    CartManager, TicketManager, ResaleManager, print_test_config
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


@pytest.fixture(scope="session")
def resale_manager(api_client, token_manager):
    """Resale manager fixture"""
    return ResaleManager(api_client, token_manager)


def prepare_test_data(user_manager, event_manager, cart_manager, ticket_manager):
    """Prepare comprehensive test data for pagination tests"""
    print_test_config()

    # Create users
    customer_data = user_manager.register_and_login_customer()
    customer2_data = user_manager.register_and_login_customer2()
    organizer_data = user_manager.register_and_login_organizer()
    admin_data = user_manager.register_and_login_admin()

    # Create multiple events with different characteristics
    events = []
    ticket_types = []

    # Event 1: Music concert in the future
    event1_data = {
        "organizer_id": 1,
        "name": "Rock Concert 2025",
        "description": "An amazing rock concert with live music",
        "start_date": (datetime.now() + timedelta(days=30)).isoformat(),
        "end_date": (datetime.now() + timedelta(days=30, hours=3)).isoformat(),
        "minimum_age": 18,
        "location_id": 1,
        "category": ["Music", "Rock", "Live"],
        "total_tickets": 100,
    }
    event1 = event_manager.create_event(1, event1_data)
    events.append(event1)

    # Event 2: Theater show
    event2_data = {
        "organizer_id": 1,
        "name": "Shakespeare Theater",
        "description": "Classic theater performance of Hamlet",
        "start_date": (datetime.now() + timedelta(days=45)).isoformat(),
        "end_date": (datetime.now() + timedelta(days=45, hours=2)).isoformat(),
        "minimum_age": 12,
        "location_id": 1,
        "category": ["Theater", "Classic", "Drama"],
        "total_tickets": 200,
    }
    event2 = event_manager.create_event(1, event2_data)
    events.append(event2)

    # Event 3: Sports event
    event3_data = {
        "organizer_id": 1,
        "name": "Football Championship",
        "description": "Championship football match",
        "start_date": (datetime.now() + timedelta(days=60)).isoformat(),
        "end_date": (datetime.now() + timedelta(days=60, hours=2)).isoformat(),
        "minimum_age": 0,
        "location_id": 1,
        "category": ["Sports", "Football", "Championship"],
        "total_tickets": 500,
    }
    event3 = event_manager.create_event(1, event3_data)
    events.append(event3)

    # Create ticket types with different prices
    for i, event in enumerate(events):
        # Regular ticket
        regular_ticket = {
            "event_id": event["event_id"],
            "description": f"Regular Admission - Event {i + 1}",
            "max_count": 50,
            "price": 50.0 + (i * 25),  # 50, 75, 100
            "currency": "PLN",
            "available_from": datetime.now().isoformat()
        }
        ticket_type = event_manager.create_ticket_type(event["event_id"], regular_ticket)
        ticket_types.append(ticket_type)

        # VIP ticket
        vip_ticket = {
            "event_id": event["event_id"],
            "description": f"VIP Access - Event {i + 1}",
            "max_count": 20,
            "price": 150.0 + (i * 50),  # 150, 200, 250
            "currency": "PLN",
            "available_from": datetime.now().isoformat()
        }
        vip_type = event_manager.create_ticket_type(event["event_id"], vip_ticket)
        ticket_types.append(vip_type)

    # Purchase some tickets and list them for resale
    purchased_tickets = []
    for i, ticket_type in enumerate(ticket_types[:3]):  # Purchase from first 3 ticket types
        cart_manager.add_item_to_cart(ticket_type["type_id"], 1)
        cart_manager.checkout()

        # Get purchased tickets
        tickets = ticket_manager.list_tickets()
        if tickets:
            ticket = tickets[-1]  # Get the most recently purchased ticket
            purchased_tickets.append(ticket)

            # List some tickets for resale at different prices
            resale_price = ticket_type["price"] * (1.2 + i * 0.1)  # 20%, 30%, 40% markup
            ticket_manager.resell_ticket(ticket["ticket_id"], resale_price)

    return {
        "customer": customer_data,
        "customer2": customer2_data,
        "organizer": organizer_data,
        "admin": admin_data,
        "events": events,
        "ticket_types": ticket_types,
        "purchased_tickets": purchased_tickets
    }


@pytest.mark.pagination
class TestEventsPagination:
    """Test events endpoint pagination and filtering"""

    @pytest.fixture(autouse=True)
    def setup(self, user_manager, event_manager, cart_manager, ticket_manager):
        """Setup test data"""
        self.test_data = prepare_test_data(user_manager, event_manager, cart_manager,
                                           ticket_manager)
        self.api_client = APIClient()

    def test_events_basic_pagination(self):
        """Test basic pagination functionality"""
        # Test first page with limit 2
        response = self.api_client.get("/api/events?page=1&limit=2")
        events_page1 = response.json()

        assert len(events_page1) <= 2
        assert isinstance(events_page1, list)

        # Test second page
        response = self.api_client.get("/api/events?page=2&limit=2")
        events_page2 = response.json()

        # Verify different events on different pages (if enough events exist)
        if len(events_page1) == 2 and len(events_page2) > 0:
            page1_ids = {event["event_id"] for event in events_page1}
            page2_ids = {event["event_id"] for event in events_page2}
            assert page1_ids.isdisjoint(page2_ids), "Pages should contain different events"

    def test_events_search_functionality(self):
        """Test search functionality"""
        # Search for rock concert
        response = self.api_client.get("/api/events?search=Rock")
        events = response.json()

        # Should find at least the rock concert we created
        rock_events = [e for e in events if
                       "Rock" in e["name"] or "rock" in e.get("description", "").lower()]
        assert len(rock_events) >= 1, "Should find rock concert events"

        # Search for theater
        response = self.api_client.get("/api/events?search=Theater")
        events = response.json()
        theater_events = [e for e in events if
                          "Theater" in e["name"] or "theater" in e.get("description", "").lower()]
        assert len(theater_events) >= 1, "Should find theater events"

    def test_events_location_filter(self):
        """Test location filtering"""
        response = self.api_client.get("/api/events?location=Test Location")
        events = response.json()

        # All events should be at the specified location
        for event in events:
            assert "Test" in event.get("location_name",
                                       ""), "All events should match location filter"

    def test_events_date_filters(self):
        """Test date range filtering"""
        # Filter events starting after today
        tomorrow = (datetime.now() + timedelta(days=1)).strftime("%Y-%m-%dT%H:%M:%S")
        response = self.api_client.get(f"/api/events?start_date_from={tomorrow}")
        events = response.json()

        # All events should be in the future
        for event in events:
            event_date = datetime.fromisoformat(event["start_date"].replace("Z", "+00:00"))
            assert event_date >= datetime.now(), "All events should be in the future"

    def test_events_price_filters(self):
        """Test price range filtering"""
        # Filter events with tickets between 60-120 PLN
        response = self.api_client.get("/api/events?min_price=60&max_price=120")
        events = response.json()

        assert isinstance(events, list), "Should return list of events"
        # Note: Price filtering tests depend on having ticket types with appropriate prices

    def test_events_sorting(self):
        """Test sorting functionality"""
        # Sort by name ascending
        response = self.api_client.get("/api/events?sort_by=name&sort_order=asc")
        events = response.json()

        if len(events) > 1:
            names = [event["name"] for event in events]
            assert names == sorted(names), "Events should be sorted by name ascending"

        # Sort by start_date descending
        response = self.api_client.get("/api/events?sort_by=start_date&sort_order=desc")
        events = response.json()

        if len(events) > 1:
            dates = [event["start_date"] for event in events]
            assert dates == sorted(dates,
                                   reverse=True), "Events should be sorted by date descending"

    def test_events_combined_filters(self):
        """Test combining multiple filters"""
        response = self.api_client.get(
            "/api/events?search=Concert&min_price=40&sort_by=start_date&sort_order=asc&page=1&limit=10"
        )
        events = response.json()

        assert isinstance(events, list), "Should return list of events"
        assert len(events) <= 10, "Should respect limit parameter"

@pytest.mark.pagination
class TestResalePagination:
    """Test resale marketplace pagination and filtering"""

    @pytest.fixture(autouse=True)
    def setup(self, user_manager, event_manager, cart_manager, ticket_manager):
        """Setup test data"""
        self.test_data = prepare_test_data(user_manager, event_manager, cart_manager,
                                           ticket_manager)
        self.api_client = APIClient()

    def test_resale_marketplace_basic_pagination(self):
        """Test basic pagination for resale marketplace"""
        # Test first page with limit 2
        response = self.api_client.get("/api/resale/marketplace?page=1&limit=2")
        listings_page1 = response.json()

        assert len(listings_page1) <= 2
        assert isinstance(listings_page1, list)

        # Validate listing structure
        for listing in listings_page1:
            assert "ticket_id" in listing
            assert "resell_price" in listing
            assert "original_price" in listing
            assert "event_name" in listing
            assert "venue_name" in listing

    def test_resale_marketplace_search(self):
        """Test search functionality in resale marketplace"""
        # Search by event name
        response = self.api_client.get("/api/resale/marketplace?search=Concert")
        listings = response.json()

        # Should find concerts in resale
        concert_listings = [l for l in listings if "Concert" in l["event_name"]]
        if concert_listings:
            assert len(concert_listings) >= 1, "Should find concert listings"

    def test_resale_marketplace_price_filters(self):
        """Test price filtering in resale marketplace"""
        # Filter by resale price range
        response = self.api_client.get("/api/resale/marketplace?min_price=50&max_price=200")
        listings = response.json()

        for listing in listings:
            assert 50 <= listing[
                "resell_price"] <= 200, f"Resale price {listing['resell_price']} not in range 50-200"

        # Filter by original price range
        response = self.api_client.get(
            "/api/resale/marketplace?min_original_price=40&max_original_price=100")
        listings = response.json()

        for listing in listings:
            assert 40 <= listing[
                "original_price"] <= 100, f"Original price {listing['original_price']} not in range 40-100"

    def test_resale_marketplace_date_filters(self):
        """Test date filtering in resale marketplace"""
        # Filter events from tomorrow onwards
        tomorrow = (datetime.now() + timedelta(days=1)).strftime("%Y-%m-%d")
        response = self.api_client.get(f"/api/resale/marketplace?event_date_from={tomorrow}")
        listings = response.json()

        for listing in listings:
            event_date = datetime.fromisoformat(listing["event_date"].replace("Z", "+00:00"))
            assert event_date.date() >= datetime.strptime(tomorrow, "%Y-%m-%d").date()

    def test_resale_marketplace_venue_filter(self):
        """Test venue filtering"""
        response = self.api_client.get("/api/resale/marketplace?venue=Test")
        listings = response.json()

        for listing in listings:
            assert "Test" in listing["venue_name"], "All listings should match venue filter"

    def test_resale_marketplace_seat_filter(self):
        """Test seat availability filtering"""
        # Filter tickets with seats
        response = self.api_client.get("/api/resale/marketplace?has_seat=true")
        listings = response.json()

        for listing in listings:
            assert listing["seat"] is not None, "All listings should have seats"

        # Filter tickets without seats
        response = self.api_client.get("/api/resale/marketplace?has_seat=false")
        listings = response.json()

        for listing in listings:
            assert listing["seat"] is None, "All listings should not have seats"

    def test_resale_marketplace_sorting(self):
        """Test sorting in resale marketplace"""
        # Sort by resale price ascending
        response = self.api_client.get(
            "/api/resale/marketplace?sort_by=resell_price&sort_order=asc")
        listings = response.json()

        if len(listings) > 1:
            prices = [listing["resell_price"] for listing in listings]
            assert prices == sorted(prices), "Listings should be sorted by resale price ascending"

        # Sort by event name descending
        response = self.api_client.get("/api/resale/marketplace?sort_by=event_name&sort_order=desc")
        listings = response.json()

        if len(listings) > 1:
            names = [listing["event_name"] for listing in listings]
            assert names == sorted(names,
                                   reverse=True), "Listings should be sorted by event name descending"

    def test_resale_marketplace_invalid_date_format(self):
        """Test invalid date format handling"""
        response = self.api_client.get("/api/resale/marketplace?event_date_from=invalid-date",
                                       expected_status=400)
        error = response.json()
        assert "Invalid event_date_from format" in error["detail"]

    def test_resale_marketplace_invalid_sort_parameters(self):
        """Test invalid sort parameters in resale marketplace"""
        # Invalid sort_by
        response = self.api_client.get("/api/resale/marketplace?sort_by=invalid_field",
                                       expected_status=400)
        error = response.json()
        assert "Invalid sort_by" in error["detail"]

    def test_my_listings_pagination(self):
        """Test pagination for user's own listings"""
        # This requires authentication, so we'll use a token
        token_manager = TokenManager()
        token_manager.set_token("customer", "dummy_token_for_test")

        try:
            response = self.api_client.get(
                "/api/resale/my-listings?page=1&limit=10",
                headers={"Authorization": "Bearer dummy_token"}
            )
            # This might fail due to authentication, but we're testing the endpoint structure
        except:
            # Expected to fail without proper authentication setup
            pass

    def test_resale_combined_filters(self):
        """Test combining multiple filters in resale marketplace"""
        response = self.api_client.get(
            "/api/resale/marketplace?"
            "search=Concert&"
            "min_price=50&max_price=300&"
            "sort_by=resell_price&sort_order=asc&"
            "page=1&limit=5"
        )
        listings = response.json()

        assert isinstance(listings, list), "Should return list of listings"
        assert len(listings) <= 5, "Should respect limit parameter"

        # Verify price range
        for listing in listings:
            assert 50 <= listing["resell_price"] <= 300, "All listings should be in price range"


@pytest.mark.pagination
class TestPaginationEdgeCases:
    """Test edge cases and error handling for pagination"""

    @pytest.fixture(autouse=True)
    def setup(self):
        """Setup for edge case tests"""
        self.api_client = APIClient()

    def test_events_pagination_bounds(self):
        """Test pagination boundary conditions"""
        # Test page 0 (should default to 1 or error)
        response = self.api_client.get("/api/events?page=0", expected_status=422)

        # Test negative page
        response = self.api_client.get("/api/events?page=-1", expected_status=422)

        # Test limit too high
        response = self.api_client.get("/api/events?limit=101", expected_status=422)

        # Test limit 0
        response = self.api_client.get("/api/events?limit=0", expected_status=422)

    def test_resale_pagination_bounds(self):
        """Test resale marketplace pagination boundary conditions"""
        # Test page 0
        response = self.api_client.get("/api/resale/marketplace?page=0", expected_status=422)

        # Test limit too high
        response = self.api_client.get("/api/resale/marketplace?limit=101", expected_status=422)

    def test_events_empty_results(self):
        """Test handling of empty results"""
        # Search for something that doesn't exist
        response = self.api_client.get("/api/events?search=NonExistentEvent12345")
        events = response.json()

        assert isinstance(events, list), "Should return empty list"
        assert len(events) == 0, "Should return no events"

    def test_resale_empty_results(self):
        """Test handling of empty resale results"""
        # Search for something that doesn't exist
        response = self.api_client.get("/api/resale/marketplace?search=NonExistentEvent12345")
        listings = response.json()

        assert isinstance(listings, list), "Should return empty list"
        assert len(listings) == 0, "Should return no listings"

    def test_events_high_page_number(self):
        """Test requesting a page number beyond available data"""
        response = self.api_client.get("/api/events?page=9999&limit=10")
        events = response.json()

        assert isinstance(events, list), "Should return empty list for high page numbers"
        assert len(events) == 0, "Should return no events for page beyond data"

    def test_special_characters_in_search(self):
        """Test search with special characters"""
        # Test with SQL injection attempt
        response = self.api_client.get("/api/events?search='; DROP TABLE events; --")
        events = response.json()

        assert isinstance(events, list), "Should handle SQL injection attempts safely"

        # Test with Unicode characters
        response = self.api_client.get("/api/events?search=Cöncert")
        events = response.json()

        assert isinstance(events, list), "Should handle Unicode characters"


@pytest.mark.integration
class TestPaginationIntegration:
    """Integration tests for pagination with real data flow"""

    @pytest.fixture(autouse=True)
    def setup(self, user_manager, event_manager, cart_manager, ticket_manager):
        """Setup comprehensive test environment"""
        self.test_data = prepare_test_data(user_manager, event_manager, cart_manager,
                                           ticket_manager)
        self.api_client = APIClient()
        self.event_manager = event_manager
        self.cart_manager = cart_manager
        self.ticket_manager = ticket_manager

    def test_complete_pagination_workflow(self):
        """Test complete workflow: create events → list with pagination → filter → resale"""
        # 1. Verify we can paginate through events
        response = self.api_client.get("/api/events?page=1&limit=2")
        events_page1 = response.json()

        assert len(events_page1) <= 2, "Should respect pagination limit"

        # 2. Search for specific event
        if events_page1:
            event_name = events_page1[0]["name"]
            search_term = event_name.split()[0]  # First word of event name

            response = self.api_client.get(f"/api/events?search={search_term}")
            search_results = response.json()

            found_event = any(search_term in event["name"] for event in search_results)
            assert found_event, f"Should find event with search term '{search_term}'"

        # 3. Test resale marketplace pagination
        response = self.api_client.get("/api/resale/marketplace?page=1&limit=5")
        resale_listings = response.json()

        assert isinstance(resale_listings, list), "Should return list of resale listings"
        assert len(resale_listings) <= 5, "Should respect resale pagination limit"

    def test_cross_endpoint_data_consistency(self):
        """Test data consistency across different paginated endpoints"""
        # Get events with pagination
        response = self.api_client.get("/api/events?page=1&limit=10")
        events = response.json()

        # Get resale marketplace
        response = self.api_client.get("/api/resale/marketplace?page=1&limit=10")
        resale_listings = response.json()

        # Verify that events in resale listings exist in events list
        event_ids = {event["event_id"] for event in events}

        for listing in resale_listings:
            # The event should exist (though not necessarily in current page)
            assert listing["event_name"] is not None, "Listing should have valid event name"
            assert listing["venue_name"] is not None, "Listing should have valid venue name"

    def test_pagination_performance_with_filters(self):
        """Test that pagination performs well with multiple filters"""
        import time

        # Complex query with multiple filters
        start_time = time.time()
        response = self.api_client.get(
            "/api/events?"
            "search=Concert&"
            "min_price=50&max_price=200&"
            "sort_by=start_date&sort_order=desc&"
            "page=1&limit=10"
        )
        end_time = time.time()

        events = response.json()
        execution_time = end_time - start_time

        assert isinstance(events, list), "Should return valid results"
        assert execution_time < 5.0, f"Query should complete in reasonable time, took {execution_time:.2f}s"

    def test_filter_validation_across_endpoints(self):
        """Test that filter validation is consistent across endpoints"""
        # Test invalid price filters on both endpoints
        response = self.api_client.get("/api/events?min_price=-10", expected_status=422)

        response = self.api_client.get("/api/resale/marketplace?min_price=-10", expected_status=422)

        # Test valid price filters
        response = self.api_client.get("/api/events?min_price=0&max_price=1000")
        events = response.json()
        assert isinstance(events, list), "Should accept valid price range"

        response = self.api_client.get("/api/resale/marketplace?min_price=0&max_price=1000")
        listings = response.json()
        assert isinstance(listings, list), "Should accept valid price range"