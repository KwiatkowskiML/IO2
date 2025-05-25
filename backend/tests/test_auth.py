"""
test_auth.py - Authentication and User Management Tests
------------------------------------------------------
Tests for user registration, login, and profile management.

Environment Variables:
- API_BASE_URL: Base URL for API (default: http://localhost:8080)
- API_TIMEOUT: Request timeout in seconds (default: 10)
- ADMIN_SECRET_KEY: Admin secret key for registration

Run with: pytest test_auth.py -v
"""

import pytest

from helper import (
    APIClient, TokenManager, TestDataGenerator, UserManager,
    print_test_config, assert_success_response
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


def prepare_test_env(user_manager: UserManager):
    """Prepare test environment with required users for auth tests"""
    print_test_config()
    # For auth tests, we create users as part of the tests themselves
    return {}


class TestUserRegistration:
    """Test user registration endpoints"""

    def test_customer_registration(self, api_client, test_data):
        """Test customer user registration"""
        user_data = test_data.customer_data()
        response = api_client.post(
            "/auth/register/customer",
            headers={"Content-Type": "application/json"},
            json_data=user_data,
            expected_status=201
        )

        assert_success_response(response, ["token"])

        response_data = response.json()
        assert len(response_data["token"]) > 0

    def test_organizer_registration(self, api_client, test_data):
        """Test organizer user registration"""
        user_data = test_data.organizer_data()
        response = api_client.post(
            "/auth/register/organizer",
            headers={"Content-Type": "application/json"},
            json_data=user_data,
            expected_status=201
        )

        assert_success_response(response, ["token"])

        response_data = response.json()
        assert len(response_data["token"]) > 0

    def test_admin_registration(self, api_client, test_data):
        """Test admin user registration"""
        user_data = test_data.admin_data()
        response = api_client.post(
            "/auth/register/admin",
            headers={"Content-Type": "application/json"},
            json_data=user_data,
            expected_status=201
        )

        assert_success_response(response, ["token"])

        response_data = response.json()
        assert len(response_data["token"]) > 0

    def test_duplicate_email_registration(self, api_client, test_data):
        """Test registration with duplicate email fails"""
        user_data = test_data.customer_data()

        # First registration should succeed
        api_client.post(
            "/auth/register/customer",
            headers={"Content-Type": "application/json"},
            json_data=user_data,
            expected_status=201
        )

        # Second registration with same email should fail
        with pytest.raises(AssertionError):
            api_client.post(
                "/auth/register/customer",
                headers={"Content-Type": "application/json"},
                json_data=user_data,
                expected_status=409  # Conflict
            )

    def test_invalid_registration_data(self, api_client):
        """Test registration with invalid data fails"""
        invalid_data = {
            "email": "invalid-email",  # Invalid email format
            "password": "123",  # Too short password
        }

        api_client.post(
            "/auth/register/customer",
            headers={"Content-Type": "application/json"},
            json_data=invalid_data,
            expected_status=422  # Validation error
        )


class TestUserLogin:
    """Test user login endpoints"""

    def test_customer_login_success(self, user_manager, token_manager):
        """Test successful customer login"""
        # Register a customer first
        customer_data = user_manager.register_and_login_customer()

        # Login with different method (form data)
        token = user_manager.login_user(customer_data, "customer")

        assert token is not None
        assert len(token) > 0
        assert token_manager.tokens["customer"] == token

    def test_organizer_login_success(self, user_manager, token_manager):
        """Test successful organizer login"""
        # Register an organizer first
        organizer_data = user_manager.register_and_login_organizer()

        # Login with different method (form data)
        token = user_manager.login_user(organizer_data, "organizer")

        assert token is not None
        assert len(token) > 0
        assert token_manager.tokens["organizer"] == token

    def test_admin_login_success(self, user_manager, token_manager):
        """Test successful admin login"""
        # Register an admin first
        admin_data = user_manager.register_and_login_admin()

        # Login with different method (form data)
        token = user_manager.login_user(admin_data, "admin")

        assert token is not None
        assert len(token) > 0
        assert token_manager.tokens["admin"] == token

    def test_login_invalid_credentials(self, api_client, test_data):
        """Test login with invalid credentials fails"""
        user_data = test_data.customer_data()

        # Register user first
        api_client.post(
            "/auth/register/customer",
            headers={"Content-Type": "application/json"},
            json_data=user_data,
            expected_status=201
        )

        # Try login with wrong password
        api_client.post(
            "/auth/token",
            headers={"Content-Type": "application/x-www-form-urlencoded"},
            data={
                "username": user_data["email"],
                "password": "WrongPassword123",
            },
            expected_status=401
        )

    def test_login_nonexistent_user(self, api_client):
        """Test login with non-existent user fails"""
        api_client.post(
            "/auth/token",
            headers={"Content-Type": "application/x-www-form-urlencoded"},
            data={
                "username": "nonexistent@example.com",
                "password": "Password123",
            },
            expected_status=401
        )


class TestUserProfile:
    """Test user profile management"""

    def test_get_customer_profile(self, user_manager, api_client, token_manager):
        """Test getting customer profile"""
        # Register and login customer
        customer_data = user_manager.register_and_login_customer()

        # Get profile
        response = api_client.get(
            "/user/me",
            headers=token_manager.get_auth_header("customer")
        )

        user_data = response.json()
        assert user_data["email"] == customer_data["email"]
        assert user_data["first_name"] == customer_data["first_name"]
        assert user_data["last_name"] == customer_data["last_name"]

    def test_get_organizer_profile(self, user_manager, api_client, token_manager):
        """Test getting organizer profile"""
        # Register and login organizer
        organizer_data = user_manager.register_and_login_organizer()

        # Get profile
        response = api_client.get(
            "/user/me",
            headers=token_manager.get_auth_header("organizer")
        )

        user_data = response.json()
        assert user_data["email"] == organizer_data["email"]
        assert user_data["first_name"] == organizer_data["first_name"]
        assert user_data["last_name"] == organizer_data["last_name"]

    def test_get_profile_unauthorized(self, api_client):
        """Test getting profile without authentication fails"""
        api_client.get(
            "/user/me",
            expected_status=401
        )

    def test_get_profile_invalid_token(self, api_client):
        """Test getting profile with invalid token fails"""
        api_client.get(
            "/user/me",
            headers={"Authorization": "Bearer INVALID_TOKEN"},
            expected_status=401
        )

class TestAdminOperations:
    """Test admin-specific operations"""

    def test_get_pending_organizers(self, user_manager, api_client, token_manager):
        """Test admin getting pending organizers"""
        # Register admin
        user_manager.register_and_login_admin()

        # Register an organizer (should be pending by default)
        user_manager.register_and_login_organizer()

        # Get pending organizers as admin
        response = api_client.get(
            "/auth/pending-organizers",
            headers=token_manager.get_auth_header("admin")
        )

        organizers = response.json()
        assert isinstance(organizers, list)

    def test_verify_organizer(self, user_manager, api_client, token_manager):
        """Test admin verifying an organizer"""
        # Register admin and organizer
        user_manager.register_and_login_admin()
        user_manager.register_and_login_organizer()

        # Get pending organizers
        response = api_client.get(
            "/auth/pending-organizers",
            headers=token_manager.get_auth_header("admin")
        )

        pending_organizers = response.json()
        if pending_organizers:
            organizer_id = pending_organizers[0]["organiser_id"]

            # Verify the organizer
            response = api_client.post(
                "/auth/verify-organizer",
                headers={
                    **token_manager.get_auth_header("admin"),
                    "Content-Type": "application/json"
                },
                json_data={
                    "organizer_id": organizer_id,
                    "approve": True,
                }
            )

            assert response.status_code == 200

    def test_non_admin_cannot_access_admin_endpoints(self, user_manager, api_client, token_manager):
        """Test that non-admin users cannot access admin endpoints"""
        # Register customer
        user_manager.register_and_login_customer()

        # Try to access admin endpoint
        api_client.get(
            "/auth/pending-organizers",
            headers=token_manager.get_auth_header("customer"),
            expected_status=403
        )


class TestTokenValidation:
    """Test token validation and expiration"""

    def test_token_format_validation(self, user_manager, token_manager):
        """Test that tokens have expected format"""
        # Register users and check token formats
        user_manager.register_and_login_customer()
        user_manager.register_and_login_organizer()
        user_manager.register_and_login_admin()

        for user_type in ["customer", "organizer", "admin"]:
            token = token_manager.tokens[user_type]
            assert token is not None
            assert len(token) > 20  # JWT tokens should be reasonably long
            assert "." in token  # JWT tokens contain dots

    def test_token_reuse(self, user_manager, api_client, token_manager):
        """Test that tokens can be reused for multiple requests"""
        # Register customer
        user_manager.register_and_login_customer()

        # Make multiple requests with same token
        for _ in range(3):
            response = api_client.get(
                "/user/me",
                headers=token_manager.get_auth_header("customer")
            )
            assert response.status_code == 200


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
