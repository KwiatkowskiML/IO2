"""
helper.py - Reusable test components for Resellio API Gateway tests
----------------------------------------------------------------
Shared utilities, fixtures, and base classes for all test modules.
"""

import os
import random
import string
from datetime import datetime
from typing import Dict, Optional, Any

import pytest
import requests


# Configuration from environment variables
def get_config():
    """Get configuration from environment variables with defaults"""
    return {
        "base_url": os.getenv("API_BASE_URL", "http://localhost:8080/api").rstrip('/'),
        "timeout": int(os.getenv("API_TIMEOUT", "10")),
        "admin_secret": os.getenv("ADMIN_SECRET_KEY", "admin-secret-key-change-this-in-production"),
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
    def event_data(cls, organizer_id: int = 1) -> Dict[str, Any]:
        """Generate event data"""
        now = datetime.now()
        return {
            "organizer_id": organizer_id,
            "name": f"Test Concert {cls.random_string(4)}",
            "description": "A test concert event",
            "start": now.isoformat(),
            "end": now.isoformat(),
            "minimum_age": 18,
            "location": "Test Venue",
            "category": ["Music", "Live"],
            "total_tickets": 100,
        }

    @classmethod
    def ticket_type_data(cls, event_id: int = 1) -> Dict[str, Any]:
        """Generate ticket type data"""
        return {
            "type_id": 1,
            "event_id": event_id,
            "description": "VIP Access",
            "max_count": 50,
            "price": 149.99,
            "currency": "PLN",
            "available_from": "2025-04-15T10:00:00",
        }

    @classmethod
    def cart_item_data(cls, ticket_id: int = 1, ticket_type_id: int = 1) -> Dict[str, Any]:
        """Generate cart item data"""
        return {
            "ticket_id": ticket_id,
            "ticket_type_id": ticket_type_id,
            "seat": f"{random.choice('ABCDEFGH')}{random.randint(1, 20)}",
        }


class UserManager:
    """Manages user registration and authentication"""

    def __init__(self, api_client: APIClient, token_manager: TokenManager):
        self.api_client = api_client
        self.token_manager = token_manager
        self.data_generator = TestDataGenerator()

    def register_and_login_customer(self) -> Dict[str, str]:
        """Register and login a customer user"""
        user_data = self.data_generator.customer_data()

        # Register customer
        response = self.api_client.post(
            "/auth/register/customer",
            headers={"Content-Type": "application/json"},
            json_data=user_data,
            expected_status=201
        )

        # Extract and store token
        token = response.json().get("token")
        if token:
            self.token_manager.set_token("customer", token)
            self.token_manager.set_user("customer", user_data)

        return user_data

    def register_and_login_organizer(self) -> Dict[str, str]:
        """Register and login an organizer user"""
        user_data = self.data_generator.organizer_data()

        # Register organizer
        response = self.api_client.post(
            "/auth/register/organizer",
            headers={"Content-Type": "application/json"},
            json_data=user_data,
            expected_status=201
        )

        # Extract and store token
        token = response.json().get("token")
        if token:
            self.token_manager.set_token("organizer", token)
            self.token_manager.set_user("organizer", user_data)

        return user_data

    def register_and_login_admin(self) -> Dict[str, str]:
        """Register and login an admin user"""
        user_data = self.data_generator.admin_data()

        # Register admin
        response = self.api_client.post(
            "/auth/register/admin",
            headers={"Content-Type": "application/json"},
            json_data=user_data,
            expected_status=201
        )

        # Extract and store token
        token = response.json().get("token")
        if token:
            self.token_manager.set_token("admin", token)
            self.token_manager.set_user("admin", user_data)

        return user_data

    def login_user(self, user_data: Dict[str, str], user_type: str) -> str:
        """Login user with credentials and return token"""
        response = self.api_client.post(
            "/auth/token",
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


class EventManager:
    """Manages event creation and operations"""

    def __init__(self, api_client: APIClient, token_manager: TokenManager):
        self.api_client = api_client
        self.token_manager = token_manager
        self.data_generator = TestDataGenerator()

    def create_event(self, organizer_id: int = 1) -> Dict[str, Any]:
        """Create an event as organizer"""
        event_data = self.data_generator.event_data(organizer_id)

        response = self.api_client.post(
            "/events/",
            headers={
                **self.token_manager.get_auth_header("organizer"),
                "Content-Type": "application/json"
            },
            json_data=event_data
        )

        return response.json()

    def create_ticket_type(self, event_id: int = 1) -> Dict[str, Any]:
        """Create a ticket type for an event"""
        ticket_data = self.data_generator.ticket_type_data(event_id)

        response = self.api_client.post(
            "/ticket-types/",
            headers={
                **self.token_manager.get_auth_header("organizer"),
                "Content-Type": "application/json"
            },
            json_data=ticket_data
        )

        return response.json()


class CartManager:
    """Manages shopping cart operations"""

    def __init__(self, api_client: APIClient, token_manager: TokenManager):
        self.api_client = api_client
        self.token_manager = token_manager
        self.data_generator = TestDataGenerator()

    def add_item_to_cart(self, ticket_id: int = 1, ticket_type_id: int = 1) -> Dict[str, Any]:
        """Add item to customer's cart"""
        cart_item = self.data_generator.cart_item_data(ticket_id, ticket_type_id)

        response = self.api_client.post(
            "/cart/items",
            headers={
                **self.token_manager.get_auth_header("customer"),
                "Content-Type": "application/json"
            },
            json_data=cart_item
        )

        return response.json()

    def get_cart_items(self) -> list:
        """Get items in customer's cart"""
        response = self.api_client.get(
            "/cart/items",
            headers=self.token_manager.get_auth_header("customer")
        )

        return response.json()

    def checkout(self) -> Dict[str, Any]:
        """Checkout customer's cart"""
        response = self.api_client.post(
            "/cart/checkout",
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
    print(f"Admin Secret: {'*' * len(config['admin_secret'])}")
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
