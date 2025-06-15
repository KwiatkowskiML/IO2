"""
helper.py - Reusable test components for Resellio API Gateway tests
----------------------------------------------------------------
Shared utilities, fixtures, and base classes for all test modules.
"""

import os
import random
import string
from datetime import datetime
from typing import Dict, Optional, Any, List
from pathlib import Path

import pytest
import requests
from dotenv import load_dotenv

# Load environment variables from .env file in the project root.
# This allows tests to run locally and in CI with the same config as docker-compose.
project_root = Path(__file__).resolve().parent.parent.parent
dotenv_path = project_root / ".env"
if dotenv_path.exists():
    load_dotenv(dotenv_path=dotenv_path)


# Configuration from environment variables
def get_config():
    """Get configuration from environment variables with defaults"""
    return {
        "base_url": os.getenv("API_BASE_URL", "http://localhost:8080").rstrip('/'),
        "timeout": int(os.getenv("API_TIMEOUT", "10")),
        "admin_secret": os.getenv("ADMIN_SECRET_KEY"),
        "initial_admin_email": os.getenv("INITIAL_ADMIN_EMAIL", "admin@resellio.com"),
        "initial_admin_password": os.getenv("INITIAL_ADMIN_PASSWORD", "AdminPassword123!"),
    }


class APIClient:
    """HTTP client for API Gateway testing"""

    def __init__(self, base_url: str = None, timeout: int = None):
        config = get_config()
        self.base_url = base_url or config["base_url"]
        self.timeout = timeout or config["timeout"]
        self.session = requests.Session()

    def request(
            self,
            method: str,
            endpoint: str,
            headers: Optional[Dict[str, str]] = None,
            data: Optional[Dict] = None,
            json_data: Optional[Dict] = None,
            expected_status: int = 200
    ) -> requests.Response:
        """Make HTTP request and return response"""
        url = f"{self.base_url}{endpoint}"

        response = self.session.request(
            method=method.upper(),
            url=url,
            headers=headers,
            data=data,
            json=json_data,
            timeout=self.timeout
        )

        # Assert expected status if provided
        if expected_status is not None:
            assert response.status_code == expected_status, (
                f"Expected status {expected_status}, got {response.status_code}. "
                f"Response: {response.text[:200]}"
            )

        return response

    def get(self, endpoint: str, **kwargs) -> requests.Response:
        """GET request shorthand"""
        return self.request("GET", endpoint, **kwargs)

    def post(self, endpoint: str, **kwargs) -> requests.Response:
        """POST request shorthand"""
        return self.request("POST", endpoint, **kwargs)

    def put(self, endpoint: str, **kwargs) -> requests.Response:
        """PUT request shorthand"""
        return self.request("PUT", endpoint, **kwargs)

    def delete(self, endpoint: str, **kwargs) -> requests.Response:
        """DELETE request shorthand"""
        return self.request("DELETE", endpoint, **kwargs)


class TokenManager:
    """Manages authentication tokens for different user types"""

    def __init__(self):
        self.tokens: Dict[str, Optional[str]] = {
            "customer": None,
            "organizer": None,
            "admin": None,
        }
        self.users: Dict[str, Optional[Dict]] = {
            "customer": None,
            "organizer": None,
            "admin": None,
        }

    def set_token(self, user_type: str, token: str):
        """Store token for user type"""
        self.tokens[user_type] = token

    def set_user(self, user_type: str, user_data: Dict):
        """Store user data for user type"""
        self.users[user_type] = user_data

    def get_auth_header(self, user_type: str) -> Dict[str, str]:
        """Get authorization header for user type"""
        token = self.tokens.get(user_type)
        if not token:
            pytest.fail(f"No token available for {user_type}")
        return {"Authorization": f"Bearer {token}"}

    def get_user(self, user_type: str) -> Dict:
        """Get user data for user type"""
        user = self.users.get(user_type)
        if not user:
            pytest.fail(f"No user data available for {user_type}")
        return user


class TestDataGenerator:
    """Generates test data for users and events"""

    @staticmethod
    def random_string(length: int = 8) -> str:
        """Generate random alphanumeric string"""
        return ''.join(random.choices(string.ascii_lowercase + string.digits, k=length))

    @classmethod
    def get_config(cls):
        """Get test configuration"""
        return get_config()

    @classmethod
    def customer_data(cls) -> Dict[str, str]:
        """Generate customer registration data"""
        suffix = cls.random_string()
        return {
            "email": f"customer_{suffix}@example.com",
            "login": f"customer_{suffix}",
            "password": "Password123",
            "first_name": "Test",
            "last_name": "Customer",
        }

    @classmethod
    def organizer_data(cls) -> Dict[str, str]:
        """Generate organizer registration data"""
        suffix = cls.random_string()
        return {
            "email": f"organizer_{suffix}@example.com",
            "login": f"organizer_{suffix}",
            "password": "Password123",
            "first_name": "Test",
            "last_name": "Organizer",
            "company_name": "Test Events Inc",
        }

    @classmethod
    def admin_data(cls) -> Dict[str, str]:
        """Generate admin registration data"""
        config = get_config()
        suffix = cls.random_string()
        return {
            "email": f"admin_{suffix}@example.com",
            "login": f"admin_{suffix}",
            "password": "Password123",
            "first_name": "Test",
            "last_name": "Admin",
            "admin_secret_key": config["admin_secret"],
        }

    @classmethod
    def initial_admin_data(cls) -> Dict[str, str]:
        """Get initial admin credentials"""
        config = get_config()
        return {
            "email": config["initial_admin_email"],
            "password": config["initial_admin_password"],
            "first_name": "Initial",
            "last_name": "Admin",
        }

    @classmethod
    def event_data(cls, organizer_id: int = 1) -> Dict[str, Any]:
        """Generate event data matching EventBase schema"""
        now = datetime.now()
        end_time = now.replace(hour=23, minute=59)  # Same day, later time

        return {
            "organizer_id": organizer_id,
            "name": f"Test Concert {cls.random_string(4)}",
            "description": "A test concert event for automated testing",
            "start_date": now.isoformat(),
            "end_date": end_time.isoformat(),
            "minimum_age": 18,
            "location_id": 1,  # Assuming location with ID 1 exists
            "category": ["Music", "Live", "Entertainment"],
            "total_tickets": 100,
        }

    @classmethod
    def event_update_data(cls) -> Dict[str, Any]:
        """Generate event update data matching EventUpdate schema"""
        return {
            "name": f"Updated Event {cls.random_string(4)}",
            "description": "Updated event description",
            "location_id": 2,
            "minimum_age": 21,
        }

    @classmethod
    def notification_data(cls, urgent: bool = False) -> Dict[str, Any]:
        """Generate notification data matching NotificationRequest schema"""
        return {
            "message": f"Important update about the event - {cls.random_string(6)}",
            "urgent": urgent
        }

    @classmethod
    def ticket_type_data(cls, event_id: int = 1) -> Dict[str, Any]:
        """Generate ticket type data"""
        return {
            "event_id": event_id,
            "description": f"VIP Access {cls.random_string(3)}",
            "max_count": 50,
            "price": 149.99,
            "currency": "PLN",
            "available_from": "2025-04-15T10:00:00",
        }

    @classmethod
    def cart_item_data(cls, ticket_type_id: int = 1, quantity: int = 1) -> Dict[str, Any]:
        """Generate cart item data"""
        return {
            "ticket_type_id": ticket_type_id,
            "quantity": quantity,
        }


class UserManager:
    """Manages user registration and authentication"""

    def __init__(self, api_client: APIClient, token_manager: TokenManager):
        self.api_client = api_client
        self.token_manager = token_manager
        self.data_generator = TestDataGenerator()

    def login_initial_admin(self) -> str:
        """Login as the initial hardcoded admin"""
        config = get_config()
        initial_admin_data = {
            "email": config["initial_admin_email"],
            "password": config["initial_admin_password"],
        }

        response = self.api_client.post(
            "/api/auth/token",
            headers={"Content-Type": "application/x-www-form-urlencoded"},
            data={
                "username": initial_admin_data["email"],
                "password": initial_admin_data["password"],
            }
        )

        # Extract and store token
        token = response.json().get("token")
        if token:
            self.token_manager.set_token("admin", token)
            self.token_manager.set_user("admin", initial_admin_data)

        return token

    def register_admin_with_auth(self) -> Dict[str, str]:
        """Register a new admin using existing admin authentication"""
        # Ensure we have admin token
        if not self.token_manager.tokens.get("admin"):
            self.login_initial_admin()

        user_data = self.data_generator.admin_data()

        # Register admin with admin authentication
        response = self.api_client.post(
            "/api/auth/register/admin",
            headers={
                **self.token_manager.get_auth_header("admin"),
                "Content-Type": "application/json"
            },
            json_data=user_data,
            expected_status=201
        )

        # Don't automatically set the token, let the caller decide
        return user_data

    def register_and_login_customer(self) -> Dict[str, str]:
        """Register and login a customer user"""
        customer_user_data = self.data_generator.customer_data()

        # Register customer
        registration_response = self.api_client.post(
            "/api/auth/register/customer",
            headers={"Content-Type": "application/json"},
            json_data=customer_user_data,
            expected_status=201
        )
        registration_response_data = registration_response.json()
        assert "message" in registration_response_data
        assert "User registered successfully. Please check your email to activate your account." in registration_response_data["message"]
        assert "token" not in registration_response_data, "Token should not be returned at initial customer registration"

        customer_user_id = registration_response_data["user_id"]

        if not self.token_manager.tokens.get("admin"):
            self.register_and_login_admin()

        admin_auth_header = self.token_manager.get_auth_header("admin")

        # Admin verifies the customer registration
        approve_response = self.api_client.post(
            f"/api/auth/approve-user/{customer_user_id}",
            headers=admin_auth_header,
            expected_status=200  # Expect OK, as it should return the token
        )
        approve_response_data = approve_response.json()
        assert "token" in approve_response_data, "Token not found in admin approval response"

        customer_token = approve_response_data["token"]

        if customer_token:
            self.token_manager.set_token("customer", customer_token)
            self.token_manager.set_user("customer", customer_user_data)
        else:
            pytest.fail("Failed to retrieve token for customer after admin approval.")

        return customer_user_data

    def register_and_login_customer2(self) -> Dict[str, str]:
        """Register and login a second customer user for testing purposes"""
        customer_user_data = self.data_generator.customer_data()

        # Register customer
        registration_response = self.api_client.post(
            "/api/auth/register/customer",
            headers={"Content-Type": "application/json"},
            json_data=customer_user_data,
            expected_status=201
        )
        registration_response_data = registration_response.json()
        assert "message" in registration_response_data
        assert "User registered successfully. Please check your email to activate your account." in \
               registration_response_data["message"]
        assert "token" not in registration_response_data, "Token should not be returned at initial customer registration"

        customer_user_id = registration_response_data["user_id"]

        if not self.token_manager.tokens.get("admin"):
            self.register_and_login_admin()

        admin_auth_header = self.token_manager.get_auth_header("admin")

        # Admin verifies the customer registration
        approve_response = self.api_client.post(
            f"/api/auth/approve-user/{customer_user_id}",
            headers=admin_auth_header,
            expected_status=200  # Expect OK, as it should return the token
        )
        approve_response_data = approve_response.json()
        assert "token" in approve_response_data, "Token not found in admin approval response"

        customer_token = approve_response_data["token"]

        # Extract and store token
        if customer_token:
            self.token_manager.set_token("customer", customer_token)
            self.token_manager.set_user("customer", customer_user_data)
        else:
            pytest.fail("Failed to retrieve token for customer after admin approval.")

        return customer_user_data

    def register_organizer(self) -> Dict[str, str]:
        """Register an organizer user (returns unverified organizer)"""
        user_data = self.data_generator.organizer_data()

        # Register organizer
        response = self.api_client.post(
            "/api/auth/register/organizer",
            headers={"Content-Type": "application/json"},
            json_data=user_data,
            expected_status=201
        )

        # Extract token (organizer gets token but is unverified)
        token = response.json().get("token")
        if token:
            self.token_manager.set_token("organizer_unverified", token)
            self.token_manager.set_user("organizer", user_data)

        return user_data

    def register_and_login_organizer(self) -> Dict[str, str]:
        """Register organizer and get them verified by admin"""
        # First register organizer
        organizer_data = self.register_organizer()

        # Login as initial admin if not exists
        if not self.token_manager.tokens.get("admin"):
            self.login_initial_admin()

        # Get pending organizers and verify the one we just created
        pending_organizers = self.get_pending_organizers()
        if pending_organizers:
            # Find our organizer by email
            organizer_record = None
            for org in pending_organizers:
                if org["email"] == organizer_data["email"]:
                    organizer_record = org
                    break

            if organizer_record:
                # Verify the organizer
                self.verify_organizer_by_admin(organizer_record["organizer_id"], True)

                # Now login the verified organizer
                login_token = self.login_user(organizer_data, "organizer")
                if login_token:
                    self.token_manager.set_token("organizer", login_token)

        return organizer_data

    def register_and_login_admin(self) -> Dict[str, str]:
        """Register and login an admin user (deprecated - use login_initial_admin instead)"""
        # This method now just calls login_initial_admin for compatibility
        self.login_initial_admin()
        return self.data_generator.initial_admin_data()

    def login_user(self, user_data: Dict[str, str], user_type: str) -> str:
        """Login user with credentials and return token"""
        response = self.api_client.post(
            "/api/auth/token",
            headers={"Content-Type": "application/x-www-form-urlencoded"},
            data={
                "username": user_data["email"],
                "password": user_data["password"],
            }
        )

        token = response.json().get("token")
        if token:
            self.token_manager.set_token(user_type, token)

        return token

    def verify_organizer_by_admin(self, organizer_id: int, approve: bool = True) -> Dict:
        """Admin verifies or rejects an organizer"""
        response = self.api_client.post(
            "/api/auth/verify-organizer",
            headers={
                **self.token_manager.get_auth_header("admin"),
                "Content-Type": "application/json"
            },
            json_data={
                "organizer_id": organizer_id,
                "approve": approve,
            }
        )
        return response.json()

    def get_pending_organizers(self) -> list:
        """Admin gets list of pending organizers"""
        response = self.api_client.get(
            "/api/auth/pending-organizers",
            headers=self.token_manager.get_auth_header("admin")
        )
        return response.json()

    def ban_user(self, user_id: int) -> Dict:
        """Admin bans a user"""
        response = self.api_client.post(
            f"/api/auth/ban-user/{user_id}",
            headers=self.token_manager.get_auth_header("admin")
        )
        return response.json()

    def unban_user(self, user_id: int) -> Dict:
        """Admin unbans a user"""
        response = self.api_client.post(
            f"/api/auth/unban-user/{user_id}",
            headers=self.token_manager.get_auth_header("admin")
        )
        return response.json()


class EventManager:
    """Manages event creation and operations"""

    def __init__(self, api_client: APIClient, token_manager: TokenManager):
        self.api_client = api_client
        self.token_manager = token_manager
        self.data_generator = TestDataGenerator()

    def create_event(self, organizer_id: int = 1, custom_data: Dict = None) -> Dict[str, Any]:
        """Create an event as organizer using EventBase schema"""
        if custom_data:
            event_data = custom_data
        else:
            event_data = self.data_generator.event_data(organizer_id)

        response = self.api_client.post(
            "/api/events/",
            headers={
                **self.token_manager.get_auth_header("organizer"),
                "Content-Type": "application/json"
            },
            json_data=event_data,
            expected_status=200
        )
        return response.json()

    def get_events(self, filters: Dict = None) -> List[Dict[str, Any]]:
        """Get list of events with optional filters"""
        url = "/api/events"
        if filters:
            query_params = "&".join([f"{k}={v}" for k, v in filters.items()])
            url = f"{url}?{query_params}"

        response = self.api_client.get(url)
        return response.json()

    def get_event_by_id(self, event_id: int) -> Dict[str, Any]:
        """Get specific event details by ID"""
        response = self.api_client.get(f"/api/events/{event_id}")
        return response.json()

    def update_event(self, event_id: int, update_data: Dict = None) -> Dict[str, Any]:
        """Update an event using EventUpdate schema"""
        if update_data is None:
            update_data = self.data_generator.event_update_data()

        response = self.api_client.put(
            f"/api/events/{event_id}",
            headers={
                **self.token_manager.get_auth_header("organizer"),
                "Content-Type": "application/json"
            },
            json_data=update_data
        )
        return response.json()

    def delete_event(self, event_id: int) -> bool:
        """Cancel/delete an event"""
        response = self.api_client.delete(
            f"/api/events/{event_id}",
            headers=self.token_manager.get_auth_header("organizer")
        )
        return response.json()

    def authorize_event(self, event_id: int) -> bool:
        """Admin authorizes an event"""
        response = self.api_client.post(
            f"/api/events/authorize/{event_id}",
            headers=self.token_manager.get_auth_header("admin")
        )
        return response.json()

    def notify_participants(self, event_id: int, message: str = None, urgent: bool = False) -> Dict[
        str, Any]:
        """Notify participants of an event using NotificationRequest schema"""
        if message is None:
            notification_data = self.data_generator.notification_data(urgent)
        else:
            notification_data = {
                "message": message,
                "urgent": urgent
            }

        response = self.api_client.post(
            f"/api/events/{event_id}/notify",
            headers={
                **self.token_manager.get_auth_header("organizer"),
                "Content-Type": "application/json"
            },
            json_data=notification_data
        )
        return response.json()

    def create_ticket_type(self, event_id: int = 1, custom_data: Dict = None) -> Dict[str, Any]:
        """Create a ticket type for an event"""
        if custom_data:
            ticket_data = custom_data
        else:
            ticket_data = self.data_generator.ticket_type_data(event_id)

        response = self.api_client.post(
            "/api/ticket-types/",
            headers={
                **self.token_manager.get_auth_header("organizer"),
                "Content-Type": "application/json"
            },
            json_data=ticket_data
        )
        return response.json()

    def get_ticket_types(self, filters: Dict = None) -> List[Dict[str, Any]]:
        """Get list of ticket types with optional filters"""
        url = "/api/ticket-types/"
        if filters:
            query_params = "&".join([f"{k}={v}" for k, v in filters.items()])
            url = f"{url}?{query_params}"

        response = self.api_client.get(url)
        return response.json()

    def delete_ticket_type(self, type_id: int) -> bool:
        """Delete a ticket type"""
        response = self.api_client.delete(
            f"/api/ticket-types/{type_id}",
            headers=self.token_manager.get_auth_header("organizer")
        )
        return response.json()

    # Helper methods for testing specific scenarios
    def create_event_with_valid_dates(self, organizer_id: int = 1) -> Dict[str, Any]:
        """Create event with properly sequenced dates"""
        now = datetime.now()
        start_date = now.replace(hour=19, minute=0, second=0, microsecond=0)  # 7 PM today
        end_date = now.replace(hour=23, minute=0, second=0, microsecond=0)  # 11 PM today

        event_data = {
            "organizer_id": organizer_id,
            "name": f"Evening Concert {self.data_generator.random_string(4)}",
            "description": "An evening concert with proper timing",
            "start_date": start_date.isoformat(),
            "end_date": end_date.isoformat(),
            "minimum_age": 18,
            "location_id": 1,
            "category": ["Music", "Live"],
            "total_tickets": 200,
        }

        return self.create_event(organizer_id, event_data)

    def create_event_minimal(self, organizer_id: int = 1) -> Dict[str, Any]:
        """Create event with minimal required fields"""
        now = datetime.now()

        minimal_event = {
            "organizer_id": organizer_id,
            "name": f"Minimal Event {self.data_generator.random_string(4)}",
            "start_date": now.isoformat(),
            "end_date": (now.replace(hour=23, minute=59)).isoformat(),
            "location_id": 1,
            "category": ["General"],
            "total_tickets": 50,
        }

        return self.create_event(organizer_id, minimal_event)

    def create_multi_day_event(self, organizer_id: int = 1) -> Dict[str, Any]:
        """Create a multi-day event"""
        now = datetime.now()
        start_date = now.replace(hour=10, minute=0, second=0, microsecond=0)
        end_date = start_date.replace(day=start_date.day + 2, hour=18, minute=0)  # 3 days later

        multi_day_event = {
            "organizer_id": organizer_id,
            "name": f"3-Day Festival {self.data_generator.random_string(4)}",
            "description": "A comprehensive 3-day music festival",
            "start_date": start_date.isoformat(),
            "end_date": end_date.isoformat(),
            "minimum_age": 16,
            "location_id": 1,
            "category": ["Music", "Festival", "Outdoor"],
            "total_tickets": 1000,
        }

        return self.create_event(organizer_id, multi_day_event)


class TicketManager:
    """Manages ticket operations"""

    def __init__(self, api_client: APIClient, token_manager: TokenManager):
        self.api_client = api_client
        self.token_manager = token_manager

    def list_tickets(self, filters: Dict = None) -> list:
        """List tickets with optional filters"""
        url = "/api/tickets/"
        if filters:
            query_params = "&".join([f"{k}={v}" for k, v in filters.items()])
            url = f"{url}?{query_params}"

        response = self.api_client.get(
            url,
            headers=self.token_manager.get_auth_header("customer")
        )
        return response.json()

    def download_ticket(self, ticket_id: int) -> Dict[str, Any]:
        """Download ticket PDF"""
        response = self.api_client.get(
            f"/api/tickets/{ticket_id}/download",
            headers=self.token_manager.get_auth_header("customer")
        )
        return response.json()

    def resell_ticket(self, ticket_id: int, price: float) -> Dict[str, Any]:
        """Put ticket up for resale"""
        resell_data = {
            "price": price
        }

        response = self.api_client.post(
            f"/api/tickets/{ticket_id}/resell",
            headers={
                **self.token_manager.get_auth_header("customer"),
                "Content-Type": "application/json"
            },
            json_data=resell_data
        )
        return response.json()

    def cancel_resell(self, ticket_id: int) -> Dict[str, Any]:
        """Cancel ticket resale"""
        response = self.api_client.delete(
            f"/api/tickets/{ticket_id}/resell",
            headers=self.token_manager.get_auth_header("customer")
        )
        return response.json()

    def get_resale_marketplace(self, event_id: int = None, min_price: float = None, max_price: float = None) -> List[Dict[str, Any]]:
        """Get all tickets available for resale"""
        url = "/api/resale/marketplace"
        params = []

        if event_id is not None:
            params.append(f"event_id={event_id}")
        if min_price is not None:
            params.append(f"min_price={min_price}")
        if max_price is not None:
            params.append(f"max_price={max_price}")

        if params:
            url = f"{url}?{'&'.join(params)}"

        response = self.api_client.get(url)
        return response.json()

    def purchase_resale_ticket(self, ticket_id: int) -> Dict[str, Any]:
        """Purchase a ticket from the resale marketplace"""
        purchase_data = {
            "ticket_id": ticket_id
        }

        response = self.api_client.post(
            "/api/resale/purchase",
            headers={
                **self.token_manager.get_auth_header("customer"),
                "Content-Type": "application/json"
            },
            json_data=purchase_data
        )
        return response.json()

    def get_my_resale_listings(self) -> List[Dict[str, Any]]:
        """Get all tickets I have listed for resale"""
        response = self.api_client.get(
            "/api/resale/my-listings",
            headers=self.token_manager.get_auth_header("customer")
        )
        return response.json()


class ResaleManager:
    """Manages ticket resale marketplace operations"""

    def __init__(self, api_client: APIClient, token_manager: TokenManager):
        self.api_client = api_client
        self.token_manager = token_manager

    def get_marketplace(self, filters: Dict = None) -> list:
        """Get resale marketplace listings"""
        url = "/api/resale/marketplace"
        if filters:
            query_params = "&".join([f"{k}={v}" for k, v in filters.items()])
            url = f"{url}?{query_params}"

        response = self.api_client.get(url)
        return response.json()

    def purchase_resale_ticket(self, ticket_id: int) -> Dict[str, Any]:
        """Purchase a ticket from resale marketplace"""
        response = self.api_client.post(
            "/api/resale/purchase",
            headers={
                **self.token_manager.get_auth_header("customer"),
                "Content-Type": "application/json"
            },
            json_data={"ticket_id": ticket_id}
        )
        return response.json()

    def get_my_listings(self) -> list:
        """Get user's own resale listings"""
        response = self.api_client.get(
            "/api/resale/my-listings",
            headers=self.token_manager.get_auth_header("customer")
        )
        return response.json()


class CartManager:
    """Manages shopping cart operations"""

    def __init__(self, api_client: APIClient, token_manager: TokenManager):
        self.api_client = api_client
        self.token_manager = token_manager
        self.data_generator = TestDataGenerator()

    def add_item_to_cart(self, ticket_type_id: int = 1, quantity: int = 1) -> Dict[str, Any]:
        """Add item to customer's cart using query parameters"""
        response = self.api_client.post(
            f"/api/cart/items?ticket_type_id={ticket_type_id}&quantity={quantity}",
            headers=self.token_manager.get_auth_header("customer")
        )
        return response.json()

    def get_cart_items(self) -> list:
        """Get items in customer's cart"""
        response = self.api_client.get(
            "/api/cart/items",
            headers=self.token_manager.get_auth_header("customer")
        )
        return response.json()

    def remove_item_from_cart(self, cart_item_id: int) -> bool:
        """Remove specific item from customer's cart"""
        response = self.api_client.delete(
            f"/api/cart/items/{cart_item_id}",
            headers=self.token_manager.get_auth_header("customer")
        )
        return response.json()

    def update_cart_item_quantity(self, cart_item_id: int, new_quantity: int) -> Dict[str, Any]:
        """Update quantity of item in cart"""
        # This would be a PUT/PATCH endpoint if it exists
        response = self.api_client.put(
            f"/api/cart/items/{cart_item_id}",
            headers={
                **self.token_manager.get_auth_header("customer"),
                "Content-Type": "application/json"
            },
            json_data={"quantity": new_quantity}
        )
        return response.json()

    def clear_cart(self) -> bool:
        """Clear all items from cart"""
        response = self.api_client.delete(
            "/api/cart/items",
            headers=self.token_manager.get_auth_header("customer")
        )
        return response.json()

    def checkout(self) -> bool:
        """Checkout customer's cart"""
        response = self.api_client.post(
            "/api/cart/checkout",
            headers=self.token_manager.get_auth_header("customer")
        )
        return response.json()

    def get_cart_total(self) -> Dict[str, Any]:
        """Get cart total and summary"""
        response = self.api_client.get(
            "/api/cart/total",
            headers=self.token_manager.get_auth_header("customer")
        )
        return response.json()

    def apply_discount_code(self, discount_code: str) -> Dict[str, Any]:
        """Apply discount code to cart"""
        response = self.api_client.post(
            "/api/cart/discount",
            headers={
                **self.token_manager.get_auth_header("customer"),
                "Content-Type": "application/json"
            },
            json_data={"discount_code": discount_code}
        )
        return response.json()

    def save_cart_for_later(self) -> bool:
        """Save current cart for later"""
        response = self.api_client.post(
            "/api/cart/save",
            headers=self.token_manager.get_auth_header("customer")
        )
        return response.json()

    def restore_saved_cart(self) -> bool:
        """Restore previously saved cart"""
        response = self.api_client.post(
            "/api/cart/restore",
            headers=self.token_manager.get_auth_header("customer")
        )
        return response.json()


# Utility functions
def print_test_config():
    """Print current test configuration"""
    config = get_config()
    print(f"\n=== Test Configuration ===")
    print(f"Base URL: {config['base_url']}")
    print(f"Timeout: {config['timeout']}s")
    print(f"Admin Secret: {'*' * len(config['admin_secret']) if config['admin_secret'] else 'Not set'}")
    print(f"Initial Admin Email: {config['initial_admin_email']}")
    print(f"Initial Admin Password: {'*' * len(config['initial_admin_password'])}")
    print("=" * 30)


def assert_success_response(response: requests.Response, expected_keys: list = None):
    """Assert response is successful and contains expected keys"""
    assert response.status_code in [200,
                                    201], f"Expected success status, got {response.status_code}"

    if expected_keys:
        response_data = response.json()
        for key in expected_keys:
            assert key in response_data, f"Expected key '{key}' not found in response"


def assert_error_response(response: requests.Response, expected_status: int):
    """Assert response has expected error status"""
    assert response.status_code == expected_status, (
        f"Expected status {expected_status}, got {response.status_code}"
    )