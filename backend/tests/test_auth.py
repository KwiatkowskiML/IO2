"""
test_auth.py - Updated Authentication and User Management Tests
--------------------------------------------------------------------
Tests for user registration, login, admin operations, and organizer verification.
Updated to support hardcoded initial admin and admin-only admin registration.

Environment Variables:
- API_BASE_URL: Base URL for API (default: http://localhost:8080)
- API_TIMEOUT: Request timeout in seconds (default: 10)
- ADMIN_SECRET_KEY: Admin secret key for registration
- INITIAL_ADMIN_EMAIL: Initial admin email (default: admin@resellio.com)
- INITIAL_ADMIN_PASSWORD: Initial admin password (default: AdminPassword123!)

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


@pytest.mark.auth
class TestUserRegistration:
    """Test user registration endpoints"""

    def test_customer_registration_success(self, api_client, test_data):
        """Test successful customer user registration"""
        user_data = test_data.customer_data()
        response = api_client.post(
            "/api/auth/register/customer",
            headers={"Content-Type": "application/json"},
            json_data=user_data,
            expected_status=201
        )

        assert_success_response(response, ["message", "user_id"])

        response_data = response.json()
        assert response_data["user_id"] > 0
        assert len(response_data["message"]) > 0

    def test_organizer_registration_success(self, api_client, test_data):
        """Test successful organizer user registration"""
        user_data = test_data.organizer_data()
        response = api_client.post(
            "/api/auth/register/organizer",
            headers={"Content-Type": "application/json"},
            json_data=user_data,
            expected_status=201
        )

        assert_success_response(response, ["token", "message"])

        response_data = response.json()
        assert len(response_data["token"]) > 0
        assert "awaiting administrator verification" in response_data["message"]

    def test_admin_registration_requires_existing_admin(self, api_client, test_data):
        """Test that admin registration requires existing admin authentication"""
        user_data = test_data.admin_data()

        # Should fail without authentication
        api_client.post(
            "/api/auth/register/admin",
            headers={"Content-Type": "application/json"},
            json_data=user_data,
            expected_status=401  # Unauthorized
        )

    def test_admin_registration_success_with_admin_auth(self, user_manager, api_client, test_data, token_manager):
        """Test successful admin registration with existing admin authentication"""
        # First login as initial admin
        user_manager.login_initial_admin()

        user_data = test_data.admin_data()
        response = api_client.post(
            "/api/auth/register/admin",
            headers={
                **token_manager.get_auth_header("admin"),
                "Content-Type": "application/json"
            },
            json_data=user_data,
            expected_status=201
        )

        assert_success_response(response, ["token", "message"])

        response_data = response.json()
        assert len(response_data["token"]) > 0
        assert "Administrator registered successfully" in response_data["message"]

    def test_admin_registration_invalid_secret(self, user_manager, api_client, test_data, token_manager):
        """Test admin registration with invalid secret key fails"""
        # First login as initial admin
        user_manager.login_initial_admin()

        user_data = test_data.admin_data()
        user_data["admin_secret_key"] = "invalid_secret"

        api_client.post(
            "/api/auth/register/admin",
            headers={
                **token_manager.get_auth_header("admin"),
                "Content-Type": "application/json"
            },
            json_data=user_data,
            expected_status=403  # Should fail
        )

    def test_duplicate_email_registration(self, api_client, test_data):
        """Test registration with duplicate email fails"""
        user_data = test_data.customer_data()

        # First registration should succeed
        api_client.post(
            "/api/auth/register/customer",
            headers={"Content-Type": "application/json"},
            json_data=user_data,
            expected_status=201
        )

        # Second registration with same email should fail
        api_client.post(
            "/api/auth/register/customer",
            headers={"Content-Type": "application/json"},
            json_data=user_data,
            expected_status=400  # Email already registered
        )

    def test_duplicate_login_registration(self, api_client, test_data):
        """Test registration with duplicate login fails"""
        user_data1 = test_data.customer_data()
        user_data2 = test_data.customer_data()
        user_data2["login"] = user_data1["login"]  # Same login, different email

        # First registration should succeed
        api_client.post(
            "/api/auth/register/customer",
            headers={"Content-Type": "application/json"},
            json_data=user_data1,
            expected_status=201
        )

        # Second registration with same login should fail
        api_client.post(
            "/api/auth/register/customer",
            headers={"Content-Type": "application/json"},
            json_data=user_data2,
            expected_status=400  # Login already taken
        )

    def test_registration_missing_fields(self, api_client):
        """Test registration with missing required fields fails"""
        invalid_data = {
            "email": "test@example.com",
            # Missing password, login, first_name, last_name
        }

        api_client.post(
            "/api/auth/register/customer",
            headers={"Content-Type": "application/json"},
            json_data=invalid_data,
            expected_status=422  # Validation error
        )


@pytest.mark.auth
class TestUserLogin:
    """Test user login endpoints"""

    def test_initial_admin_login_success(self, user_manager, token_manager):
        """Test successful initial admin login with hardcoded credentials"""
        # Login with initial admin credentials
        token = user_manager.login_initial_admin()

        assert token is not None
        assert len(token) > 0
        assert token_manager.tokens["admin"] == token

    def test_initial_admin_login_creates_user(self, api_client, user_manager):
        """Test that initial admin login creates the admin user in database"""
        # Login as initial admin
        user_manager.login_initial_admin()

        # Verify the admin can access admin endpoints
        response = api_client.get(
            "/api/auth/pending-organizers",
            headers=user_manager.token_manager.get_auth_header("admin")
        )

        assert response.status_code == 200

    def test_customer_login_success(self, user_manager, token_manager):
        """Test successful customer login"""
        # Register a customer first
        customer_data = user_manager.register_and_login_customer()

        # Login with different method (form data)
        token = user_manager.login_user(customer_data, "customer")

        assert token is not None
        assert len(token) > 0
        assert token_manager.tokens["customer"] == token

    def test_organizer_login_unverified(self, user_manager, api_client):
        """Test organizer login when unverified returns empty token"""
        # Register organizer (unverified)
        organizer_data = user_manager.register_organizer()

        # Try to login unverified organizer
        response = api_client.post(
            "/api/auth/token",
            headers={"Content-Type": "application/x-www-form-urlencoded"},
            data={
                "username": organizer_data["email"],
                "password": organizer_data["password"],
            }
        )

        login_result = response.json()
        assert login_result["token"] == ""  # Empty token for unverified
        assert "pending verification" in login_result["message"]

    def test_organizer_login_verified(self, user_manager, token_manager):
        """Test organizer login after admin verification"""
        # Register and verify organizer
        user_manager.register_and_login_organizer()

        # Should have valid token now
        assert token_manager.tokens["organizer"] is not None
        assert len(token_manager.tokens["organizer"]) > 0

    def test_admin_login_success(self, user_manager, token_manager):
        """Test successful admin login after registration"""
        # First login as initial admin
        user_manager.login_initial_admin()

        # Register a new admin
        admin_data = user_manager.register_admin_with_auth()

        # Login with the new admin credentials
        token = user_manager.login_user(admin_data, "admin")

        assert token is not None
        assert len(token) > 0

    def test_login_invalid_credentials(self, api_client, test_data):
        """Test login with invalid credentials fails"""
        user_data = test_data.customer_data()

        # Register user first
        api_client.post(
            "/api/auth/register/customer",
            headers={"Content-Type": "application/json"},
            json_data=user_data,
            expected_status=201
        )

        # Try login with wrong password
        api_client.post(
            "/api/auth/token",
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
            "/api/auth/token",
            headers={"Content-Type": "application/x-www-form-urlencoded"},
            data={
                "username": "nonexistent@example.com",
                "password": "Password123",
            },
            expected_status=401
        )

    def test_login_banned_user(self, user_manager, api_client, token_manager):
        """Test login with banned user fails"""
        # Create admin and customer
        user_manager.login_initial_admin()
        customer_data = user_manager.register_and_login_customer()

        response = api_client.get(
            "/api/user/me",
            headers=token_manager.get_auth_header("customer")
        )

        # Ban the customer
        user_manager.ban_user(response.json()["user_id"])

        api_client.post(
            "/api/auth/token",
            headers={"Content-Type": "application/x-www-form-urlencoded"},
            data={
                "username": customer_data["email"],
                "password": customer_data["password"],
            },
            expected_status=403  # Account banned
        )


@pytest.mark.auth
class TestUserProfile:
    """Test user profile management"""

    def test_get_customer_profile(self, user_manager, api_client, token_manager):
        """Test getting customer profile"""
        # Register and login customer
        customer_data = user_manager.register_and_login_customer()

        # Get profile
        response = api_client.get(
            "/api/user/me",
            headers=token_manager.get_auth_header("customer")
        )

        user_data = response.json()
        assert user_data["email"] == customer_data["email"]
        assert user_data["first_name"] == customer_data["first_name"]
        assert user_data["last_name"] == customer_data["last_name"]

    def test_get_organizer_profile(self, user_manager, api_client, token_manager):
        """Test getting organizer profile"""
        # Register and verify organizer
        organizer_data = user_manager.register_and_login_organizer()

        # Get profile
        response = api_client.get(
            "/api/user/me",
            headers=token_manager.get_auth_header("organizer")
        )

        user_data = response.json()
        assert user_data["email"] == organizer_data["email"]
        assert user_data["first_name"] == organizer_data["first_name"]
        assert user_data["last_name"] == organizer_data["last_name"]

    def test_get_admin_profile(self, user_manager, api_client, token_manager):
        """Test getting admin profile"""
        # Login as initial admin
        user_manager.login_initial_admin()

        # Get profile
        response = api_client.get(
            "/api/user/me",
            headers=token_manager.get_auth_header("admin")
        )

        user_data = response.json()
        # The initial admin email comes from environment variable
        assert "@" in user_data["email"]  # Basic email validation

    def test_get_profile_unauthorized(self, api_client):
        """Test getting profile without authentication fails"""
        api_client.get(
            "/api/user/me",
            expected_status=401
        )

    def test_get_profile_invalid_token(self, api_client):
        """Test getting profile with invalid token fails"""
        api_client.get(
            "/api/user/me",
            headers={"Authorization": "Bearer INVALID_TOKEN"},
            expected_status=401
        )


@pytest.mark.auth
@pytest.mark.admin
class TestAdminOperations:
    """Test admin-specific operations"""

    def test_get_pending_organizers_empty(self, user_manager, api_client, token_manager):
        """Test admin getting empty pending organizers list"""
        # Login as initial admin
        user_manager.login_initial_admin()

        # Get pending organizers (should be empty initially)
        response = api_client.get(
            "/api/auth/pending-organizers",
            headers=token_manager.get_auth_header("admin")
        )

        organizers = response.json()
        assert isinstance(organizers, list)

    def test_get_pending_organizers_with_data(self, user_manager, api_client, token_manager):
        """Test admin getting pending organizers with data"""
        # Login as initial admin and register unverified organizer
        user_manager.login_initial_admin()
        organizer_data = user_manager.register_organizer()

        # Get pending organizers
        response = api_client.get(
            "/api/auth/pending-organizers",
            headers=token_manager.get_auth_header("admin")
        )

        organizers = response.json()
        assert isinstance(organizers, list)
        assert len(organizers) >= 1

        # Find our organizer
        found_organizer = None
        for org in organizers:
            if org["email"] == organizer_data["email"]:
                found_organizer = org
                break

        assert found_organizer is not None
        assert found_organizer["company_name"] == organizer_data["company_name"]
        assert found_organizer["is_verified"] is False

    def test_verify_organizer_approve(self, user_manager, api_client, token_manager):
        """Test admin approving an organizer"""
        # Login as initial admin and register organizer
        user_manager.login_initial_admin()
        organizer_data = user_manager.register_organizer()

        # Get pending organizers to find the ID
        pending_organizers = user_manager.get_pending_organizers()
        organizer_record = None
        for org in pending_organizers:
            if org["email"] == organizer_data["email"]:
                organizer_record = org
                break

        assert organizer_record is not None

        # Verify the organizer
        response = api_client.post(
            "/api/auth/verify-organizer",
            headers={
                **token_manager.get_auth_header("admin"),
                "Content-Type": "application/json"
            },
            json_data={
                "organizer_id": organizer_record["organizer_id"],
                "approve": True,
            }
        )

        verified_organizer = response.json()
        assert verified_organizer["is_verified"] is True
        assert verified_organizer["email"] == organizer_data["email"]

    def test_verify_organizer_reject(self, user_manager, api_client, token_manager):
        """Test admin rejecting an organizer"""
        # Login as initial admin and register organizer
        user_manager.login_initial_admin()
        organizer_data = user_manager.register_organizer()

        # Get pending organizers to find the ID
        pending_organizers = user_manager.get_pending_organizers()
        organizer_record = None
        for org in pending_organizers:
            if org["email"] == organizer_data["email"]:
                organizer_record = org
                break

        assert organizer_record is not None

        # Reject the organizer
        response = api_client.post(
            "/api/auth/verify-organizer",
            headers={
                **token_manager.get_auth_header("admin"),
                "Content-Type": "application/json"
            },
            json_data={
                "organizer_id": organizer_record["organizer_id"],
                "approve": False,
            }
        )

        rejected_organizer = response.json()
        assert rejected_organizer["is_verified"] is False

    def test_ban_unban_user(self, user_manager, api_client, token_manager):
        """Test admin banning and unbanning a user"""
        # Create admin and customer
        user_manager.login_initial_admin()
        customer_data = user_manager.register_and_login_customer()

        response = api_client.get(
            "/api/user/me",
            headers=token_manager.get_auth_header("customer")
        )

        # Ban the customer
        ban_response = user_manager.ban_user(response.json()["user_id"])
        assert "banned" in ban_response["message"]

        # Try to login banned user should fail
        api_client.post(
            "/api/auth/token",
            headers={"Content-Type": "application/x-www-form-urlencoded"},
            data={
                "username": customer_data["email"],
                "password": customer_data["password"],
            },
            expected_status=403
        )

        # Unban the user
        unban_response = user_manager.unban_user(response.json()["user_id"])
        assert "unbanned" in unban_response["message"]

        # Now login should work
        login_response = api_client.post(
            "/api/auth/token",
            headers={"Content-Type": "application/x-www-form-urlencoded"},
            data={
                "username": customer_data["email"],
                "password": customer_data["password"],
            }
        )
        assert login_response.json()["token"] != ""

    def test_non_admin_cannot_access_admin_endpoints(self, user_manager, api_client, token_manager):
        """Test that non-admin users cannot access admin endpoints"""
        # Register customer
        user_manager.register_and_login_customer()

        # Try to access admin endpoint
        api_client.get(
            "/api/auth/pending-organizers",
            headers=token_manager.get_auth_header("customer"),
            expected_status=403
        )

        # Try to verify organizer
        api_client.post(
            "/api/auth/verify-organizer",
            headers={
                **token_manager.get_auth_header("customer"),
                "Content-Type": "application/json"
            },
            json_data={"organizer_id": 1, "approve": True},
            expected_status=403
        )

        # Try to ban user
        api_client.post(
            "/api/auth/ban-user/1",
            headers=token_manager.get_auth_header("customer"),
            expected_status=403
        )


@pytest.mark.auth
class TestLogout:
    """Test logout functionality"""

    def test_logout_endpoint(self, api_client):
        """Test logout endpoint (stateless - just returns message)"""
        response = api_client.post("/api/auth/logout")

        logout_data = response.json()
        assert "Logout successful" in logout_data["message"]


@pytest.mark.auth
class TestPasswordReset:
    """Test password reset functionality"""

    def test_request_password_reset(self, api_client, test_data):
        """Test password reset request"""
        user_data = test_data.customer_data()

        # Register user first
        api_client.post(
            "/api/auth/register/customer",
            headers={"Content-Type": "application/json"},
            json_data=user_data,
            expected_status=201
        )

        # Request password reset
        response = api_client.post(
            "/api/auth/request-password-reset",
            headers={"Content-Type": "application/json"},
            json_data={"email": user_data["email"]}
        )

        reset_data = response.json()
        assert "not supported" in reset_data["message"]  # Based on the API implementation

    def test_request_password_reset_nonexistent_email(self, api_client):
        """Test password reset request for non-existent email"""
        response = api_client.post(
            "/api/auth/request-password-reset",
            headers={"Content-Type": "application/json"},
            json_data={"email": "nonexistent@example.com"}
        )

        reset_data = response.json()
        assert "message" in reset_data  # Should return generic message

    def test_reset_password_not_implemented(self, api_client):
        """Test password reset endpoint returns not implemented"""
        response = api_client.post(
            "/api/auth/reset-password",
            headers={"Content-Type": "application/json"},
            json_data={"token": "fake_token", "new_password": "NewPassword123"}
        )

        reset_data = response.json()
        assert "not implemented" in reset_data["message"]


@pytest.mark.auth
class TestTokenValidation:
    """Test token validation and security"""

    def test_token_format_validation(self, user_manager, token_manager):
        """Test that tokens have expected format"""
        # Register users and check token formats
        user_manager.register_and_login_customer()
        user_manager.register_and_login_organizer()
        user_manager.login_initial_admin()

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
                "/api/user/me",
                headers=token_manager.get_auth_header("customer")
            )
            assert response.status_code == 200

    def test_expired_token_handling(self, api_client):
        """Test handling of malformed/expired tokens"""
        # Test with obviously fake token
        api_client.get(
            "/api/user/me",
            headers={"Authorization": "Bearer fake.token.here"},
            expected_status=401
        )

        # Test with malformed authorization header
        api_client.get(
            "/api/user/me",
            headers={"Authorization": "InvalidFormat"},
            expected_status=401
        )


@pytest.mark.integration
class TestCompleteAuthFlow:
    """Test complete authentication workflows"""

    def test_complete_customer_flow(self, api_client, test_data):
        """Test complete customer authentication flow"""
        customer_data = test_data.customer_data()

        # 1. Register
        reg_response = api_client.post(
            "/api/auth/register/customer",
            headers={"Content-Type": "application/json"},
            json_data=customer_data,
            expected_status=201
        )

        user_id = reg_response.json()["user_id"]
        assert user_id > 0

        # 2. Login as initial admin (instead of registering a new admin)
        config = test_data.get_config()
        initial_admin_email = config.get("initial_admin_email", "admin@resellio.com")
        initial_admin_password = config.get("initial_admin_password", "AdminPassword123!")

        admin_login_response = api_client.post(
            "/api/auth/token",
            headers={"Content-Type": "application/x-www-form-urlencoded"},
            data={
                "username": initial_admin_email,
                "password": initial_admin_password,
            },
            expected_status=200
        )
        admin_token = admin_login_response.json().get("token")
        assert admin_token is not None

        # 3. Admin approves the customer
        approve_response = api_client.post(
            f"/api/auth/approve-user/{user_id}",
            headers={"Authorization": f"Bearer {admin_token}"},
            expected_status=200
        )
        approve_response_data = approve_response.json()
        assert "token" in approve_response_data, "Token not found in admin approval response"

        # 4. Login with customer credentials
        login_response = api_client.post(
            "/api/auth/token",
            headers={"Content-Type": "application/x-www-form-urlencoded"},
            data={
                "username": customer_data["email"],
                "password": customer_data["password"],
            }
        )

        login_token = login_response.json()["token"]
        assert len(login_token) > 0

        # 5. Access profile
        profile_response = api_client.get(
            "/api/user/me",
            headers={"Authorization": f"Bearer {login_token}"}
        )

        profile_data = profile_response.json()
        assert profile_data["email"] == customer_data["email"]

        # 6. Logout (stateless)
        logout_response = api_client.post("/api/auth/logout")
        assert "successful" in logout_response.json()["message"]
    def test_complete_admin_flow(self, api_client, test_data):
        """Test complete admin flow with initial admin and new admin registration"""
        # Get initial admin credentials from helper
        config = test_data.get_config()
        initial_admin_email = config.get("initial_admin_email", "admin@resellio.com")
        initial_admin_password = config.get("initial_admin_password", "AdminPassword123!")

        # 1. Login as initial admin
        initial_login_response = api_client.post(
            "/api/auth/token",
            headers={"Content-Type": "application/x-www-form-urlencoded"},
            data={
                "username": initial_admin_email,
                "password": initial_admin_password,
            }
        )
        initial_token = initial_login_response.json()["token"]
        assert len(initial_token) > 0
        assert "Login successful" in initial_login_response.json()["message"]

        # 2. Register new admin using initial admin authentication
        new_admin_data = test_data.admin_data()
        new_admin_reg_response = api_client.post(
            "/api/auth/register/admin",
            headers={
                "Authorization": f"Bearer {initial_token}",
                "Content-Type": "application/json"
            },
            json_data=new_admin_data,
            expected_status=201
        )
        new_admin_token = new_admin_reg_response.json()["token"]
        assert len(new_admin_token) > 0

        # 3. Login with new admin credentials
        new_admin_login_response = api_client.post(
            "/api/auth/token",
            headers={"Content-Type": "application/x-www-form-urlencoded"},
            data={
                "username": new_admin_data["email"],
                "password": new_admin_data["password"],
            }
        )
        new_admin_login_token = new_admin_login_response.json()["token"]
        assert len(new_admin_login_token) > 0

        # 4. New admin can access admin endpoints
        admin_endpoints_response = api_client.get(
            "/api/auth/pending-organizers",
            headers={"Authorization": f"Bearer {new_admin_login_token}"}
        )
        assert admin_endpoints_response.status_code == 200

    def test_complete_organizer_verification_flow(self, api_client, test_data):
        """Test complete organizer registration and verification flow"""
        # Get initial admin credentials
        config = test_data.get_config()
        initial_admin_email = config.get("initial_admin_email", "admin@resellio.com")
        initial_admin_password = config.get("initial_admin_password", "AdminPassword123!")

        # 1. Login as initial admin
        admin_login_response = api_client.post(
            "/api/auth/token",
            headers={"Content-Type": "application/x-www-form-urlencoded"},
            data={
                "username": initial_admin_email,
                "password": initial_admin_password,
            }
        )
        admin_token = admin_login_response.json()["token"]

        # 2. Register organizer
        organizer_data = test_data.organizer_data()
        org_reg_response = api_client.post(
            "/api/auth/register/organizer",
            headers={"Content-Type": "application/json"},
            json_data=organizer_data,
            expected_status=201
        )
        org_token = org_reg_response.json()["token"]

        # 3. Try to login unverified organizer
        unverified_login_response = api_client.post(
            "/api/auth/token",
            headers={"Content-Type": "application/x-www-form-urlencoded"},
            data={
                "username": organizer_data["email"],
                "password": organizer_data["password"],
            }
        )
        unverified_result = unverified_login_response.json()
        assert unverified_result["token"] == ""  # Empty token
        assert "pending verification" in unverified_result["message"]

        # 4. Admin checks pending organizers
        pending_response = api_client.get(
            "/api/auth/pending-organizers",
            headers={"Authorization": f"Bearer {admin_token}"}
        )
        pending_organizers = pending_response.json()
        assert len(pending_organizers) >= 1

        # Find our organizer
        organizer_record = None
        for org in pending_organizers:
            if org["email"] == organizer_data["email"]:
                organizer_record = org
                break
        assert organizer_record is not None

        # 5. Admin verifies organizer
        verify_response = api_client.post(
            "/api/auth/verify-organizer",
            headers={
                "Authorization": f"Bearer {admin_token}",
                "Content-Type": "application/json"
            },
            json_data={
                "organizer_id": organizer_record["organizer_id"],
                "approve": True,
            }
        )
        verified_organizer = verify_response.json()
        assert verified_organizer["is_verified"] is True

        # 6. Now organizer can login successfully
        verified_login_response = api_client.post(
            "/api/auth/token",
            headers={"Content-Type": "application/x-www-form-urlencoded"},
            data={
                "username": organizer_data["email"],
                "password": organizer_data["password"],
            }
        )
        verified_result = verified_login_response.json()
        assert len(verified_result["token"]) > 0
        assert "successful" in verified_result["message"]

        # 7. Organizer can access profile
        org_profile_response = api_client.get(
            "/api/user/me",
            headers={"Authorization": f"Bearer {verified_result['token']}"}
        )
        org_profile = org_profile_response.json()
        assert org_profile["email"] == organizer_data["email"]
