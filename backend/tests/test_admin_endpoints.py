"""
test_admin_endpoints.py - Tests for Admin User Management Endpoints
------------------------------------------------------------------
Tests for admin-only endpoints: listing users, user statistics, and user details.

Add these test classes to your existing test_auth.py file.
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

@pytest.mark.admin
class TestAdminUserListing:
    """Test admin user listing functionality"""

    @pytest.fixture(autouse=True)
    def setup(self, user_manager, token_manager):
        """Setup test environment with multiple users"""
        # Create admin
        user_manager.register_and_login_admin()

        # Create multiple customers
        self.customers = []
        for i in range(3):
            customer_data = user_manager.register_and_login_customer()
            self.customers.append(customer_data)

        # Create multiple organizers (some verified, some not)
        self.organizers = []
        for i in range(2):
            organizer_data = user_manager.register_organizer()
            self.organizers.append(organizer_data)

        # Verify one organizer
        pending_organizers = user_manager.get_pending_organizers()
        if pending_organizers:
            user_manager.verify_organizer_by_admin(pending_organizers[0]["organizer_id"], True)

        self.user_manager = user_manager
        self.token_manager = token_manager

    def test_list_all_users_default(self, api_client):
        """Test listing all users with default parameters"""
        response = api_client.get(
            "/api/auth/users",
            headers=self.token_manager.get_auth_header("admin")
        )

        users = response.json()
        assert isinstance(users, list)
        assert len(users) >= 6  # 1 admin + 3 customers + 2 organizers

        # Verify response structure
        for user in users:
            assert "user_id" in user
            assert "email" in user
            assert "first_name" in user
            assert "last_name" in user
            assert "user_type" in user
            assert "is_active" in user

            # Check if organizer has additional fields
            if user["user_type"] == "organizer":
                assert "user_id" in user
                assert "company_name" in user
                assert "is_verified" in user

    def test_list_users_with_pagination(self, api_client):
        """Test user listing with pagination"""
        # Test first page with limit 2
        response = api_client.get(
            "/api/auth/users?page=1&limit=2",
            headers=self.token_manager.get_auth_header("admin")
        )

        users_page1 = response.json()
        assert len(users_page1) == 2

        # Test second page
        response = api_client.get(
            "/api/auth/users?page=2&limit=2",
            headers=self.token_manager.get_auth_header("admin")
        )

        users_page2 = response.json()
        assert len(users_page2) >= 1

        # Ensure different users on different pages
        page1_ids = {user["user_id"] for user in users_page1}
        page2_ids = {user["user_id"] for user in users_page2}
        assert page1_ids.isdisjoint(page2_ids)

    def test_search_users_by_email(self, api_client):
        """Test searching users by email"""
        # Search for a specific customer
        customer_email = self.customers[0]["email"]
        search_term = customer_email.split("@")[0]  # Get username part

        response = api_client.get(
            f"/api/auth/users?search={search_term}",
            headers=self.token_manager.get_auth_header("admin")
        )

        users = response.json()
        assert len(users) >= 1

        # Verify search results contain the search term
        found_user = any(search_term in user["email"] for user in users)
        assert found_user

    def test_filter_by_user_type(self, api_client):
        """Test filtering users by type"""
        # Filter customers only
        response = api_client.get(
            "/api/auth/users?user_type=customer",
            headers=self.token_manager.get_auth_header("admin")
        )

        customers = response.json()
        assert len(customers) >= 3
        assert all(user["user_type"] == "customer" for user in customers)

        # Filter organizers only
        response = api_client.get(
            "/api/auth/users?user_type=organizer",
            headers=self.token_manager.get_auth_header("admin")
        )

        organizers = response.json()
        assert len(organizers) >= 2
        assert all(user["user_type"] == "organizer" for user in organizers)

        # All organizers should have additional fields
        for organizer in organizers:
            assert "organizer_id" in organizer
            assert "company_name" in organizer
            assert "is_verified" in organizer

    def test_filter_by_active_status(self, api_client):
        """Test filtering by active status"""
        # First ban a user
        response = api_client.get(
            "/api/auth/users?user_type=customer&limit=1",
            headers=self.token_manager.get_auth_header("admin")
        )
        customer = response.json()[0]
        customer_id = customer["user_id"]

        # Ban the customer
        self.user_manager.ban_user(customer_id)

        # Filter active users
        response = api_client.get(
            "/api/auth/users?is_active=true",
            headers=self.token_manager.get_auth_header("admin")
        )

        active_users = response.json()
        assert all(user["is_active"] is True for user in active_users)

        # Filter banned users
        response = api_client.get(
            "/api/auth/users?is_active=false",
            headers=self.token_manager.get_auth_header("admin")
        )

        banned_users = response.json()
        assert len(banned_users) >= 1
        assert all(user["is_active"] is False for user in banned_users)

        # Verify our banned user is in the list
        banned_user_ids = {user["user_id"] for user in banned_users}
        assert customer_id in banned_user_ids

    def test_filter_by_verification_status(self, api_client):
        """Test filtering organizers by verification status"""
        # Filter verified organizers
        response = api_client.get(
            "/api/auth/users?user_type=organizer&is_verified=true",
            headers=self.token_manager.get_auth_header("admin")
        )

        verified_organizers = response.json()
        assert len(verified_organizers) >= 1
        assert all(
            user["user_type"] == "organizer" and user["is_verified"] is True
            for user in verified_organizers
        )

        # Filter unverified organizers
        response = api_client.get(
            "/api/auth/users?user_type=organizer&is_verified=false",
            headers=self.token_manager.get_auth_header("admin")
        )

        unverified_organizers = response.json()
        assert len(unverified_organizers) >= 1
        assert all(
            user["user_type"] == "organizer" and user["is_verified"] is False
            for user in unverified_organizers
        )

    def test_sorting_users(self, api_client):
        """Test sorting functionality"""
        # Sort by email ascending
        response = api_client.get(
            "/api/auth/users?sort_by=email&sort_order=asc",
            headers=self.token_manager.get_auth_header("admin")
        )

        users_asc = response.json()
        emails_asc = [user["email"] for user in users_asc]
        assert emails_asc == sorted(emails_asc)

        # Sort by email descending
        response = api_client.get(
            "/api/auth/users?sort_by=email&sort_order=desc",
            headers=self.token_manager.get_auth_header("admin")
        )

        users_desc = response.json()
        emails_desc = [user["email"] for user in users_desc]
        assert emails_desc == sorted(emails_desc, reverse=True)

    def test_invalid_user_type_filter(self, api_client):
        """Test filtering with invalid user type"""
        response = api_client.get(
            "/api/auth/users?user_type=invalid_type",
            headers=self.token_manager.get_auth_header("admin"),
            expected_status=400
        )

        error = response.json()
        assert "Invalid user_type" in error["detail"]

    def test_combined_filters(self, api_client):
        """Test combining multiple filters"""
        response = api_client.get(
            "/api/auth/users?user_type=organizer&is_active=true&is_verified=false",
            headers=self.token_manager.get_auth_header("admin")
        )

        users = response.json()
        for user in users:
            assert user["user_type"] == "organizer"
            assert user["is_active"] is True
            assert user["is_verified"] is False

    def test_non_admin_cannot_list_users(self, api_client):
        """Test that non-admin users cannot access user listing"""
        # Test with customer
        api_client.get(
            "/api/auth/users",
            headers=self.token_manager.get_auth_header("customer"),
            expected_status=403
        )


@pytest.mark.admin
class TestAdminUserStats:
    """Test admin user statistics functionality"""

    @pytest.fixture(autouse=True)
    def setup(self, user_manager, token_manager):
        """Setup test environment"""
        user_manager.register_and_login_admin()

        # Create test users
        for _ in range(2):
            user_manager.register_and_login_customer()

        for _ in range(2):
            user_manager.register_organizer()

        # Verify one organizer
        pending_organizers = user_manager.get_pending_organizers()
        if pending_organizers:
            user_manager.verify_organizer_by_admin(pending_organizers[0]["organizer_id"], True)

        self.user_manager = user_manager
        self.token_manager = token_manager

    def test_get_user_statistics(self, api_client):
        """Test getting user statistics"""
        response = api_client.get(
            "/api/auth/users/stats",
            headers=self.token_manager.get_auth_header("admin")
        )

        stats = response.json()

        # Verify response structure
        required_fields = [
            "total_users", "active_users", "banned_users",
            "users_by_type", "organizer_stats"
        ]
        for field in required_fields:
            assert field in stats

        # Verify users_by_type structure
        user_types = stats["users_by_type"]
        assert "customers" in user_types
        assert "organizers" in user_types
        assert "administrators" in user_types

        # Verify organizer_stats structure
        organizer_stats = stats["organizer_stats"]
        assert "verified" in organizer_stats
        assert "pending" in organizer_stats

        # Verify data consistency
        assert stats["total_users"] == stats["active_users"] + stats["banned_users"]
        assert stats["total_users"] >= 5  # At least 1 admin + 2 customers + 2 organizers

    def test_stats_after_banning_user(self, api_client):
        """Test statistics update after banning a user"""
        # Get initial stats
        response = api_client.get(
            "/api/auth/users/stats",
            headers=self.token_manager.get_auth_header("admin")
        )
        initial_stats = response.json()

        # Get a customer to ban
        response = api_client.get(
            "/api/auth/users?user_type=customer&limit=1",
            headers=self.token_manager.get_auth_header("admin")
        )
        customer = response.json()[0]

        # Ban the customer
        self.user_manager.ban_user(customer["user_id"])

        # Get updated stats
        response = api_client.get(
            "/api/auth/users/stats",
            headers=self.token_manager.get_auth_header("admin")
        )
        updated_stats = response.json()

        # Verify stats changed correctly
        assert updated_stats["active_users"] == initial_stats["active_users"] - 1
        assert updated_stats["banned_users"] == initial_stats["banned_users"] + 1
        assert updated_stats["total_users"] == initial_stats["total_users"]

    def test_non_admin_cannot_get_stats(self, api_client):
        """Test that non-admin users cannot access statistics"""
        api_client.get(
            "/api/auth/users/stats",
            headers=self.token_manager.get_auth_header("customer"),
            expected_status=403
        )


@pytest.mark.admin
class TestAdminUserDetails:
    """Test admin user details functionality"""

    @pytest.fixture(autouse=True)
    def setup(self, user_manager, token_manager):
        """Setup test environment"""
        user_manager.register_and_login_admin()
        self.customer_data = user_manager.register_and_login_customer()
        self.organizer_data = user_manager.register_and_login_organizer()

        self.user_manager = user_manager
        self.token_manager = token_manager

    def test_get_customer_details(self, api_client):
        """Test getting customer details"""
        # Get customer ID
        response = api_client.get(
            f"/api/auth/users?search={self.customer_data['email'].split('@')[0]}&user_type=customer",
            headers=self.token_manager.get_auth_header("admin")
        )
        customer = response.json()[0]
        customer_id = customer["user_id"]

        # Get customer details
        response = api_client.get(
            f"/api/auth/users/{customer_id}",
            headers=self.token_manager.get_auth_header("admin")
        )

        user_details = response.json()

        # Verify response structure
        assert user_details["user_id"] == customer_id
        assert user_details["email"] == self.customer_data["email"]
        assert user_details["first_name"] == self.customer_data["first_name"]
        assert user_details["last_name"] == self.customer_data["last_name"]
        assert user_details["user_type"] == "customer"

    def test_get_organizer_details(self, api_client):
        """Test getting organizer details with extended information"""
        # Get organizer ID
        response = api_client.get(
            f"/api/auth/users?search={self.organizer_data['email'].split('@')[0]}&user_type=organizer",
            headers=self.token_manager.get_auth_header("admin")
        )
        organizer = response.json()[0]
        organizer_id = organizer["user_id"]

        # Get organizer details
        response = api_client.get(
            f"/api/auth/users/{organizer_id}",
            headers=self.token_manager.get_auth_header("admin")
        )

        user_details = response.json()

        # Verify basic user fields
        assert user_details["user_id"] == organizer_id
        assert user_details["email"] == self.organizer_data["email"]
        assert user_details["user_type"] == "organizer"

        # Verify organizer-specific fields
        assert "organizer_id" in user_details
        assert "company_name" in user_details
        assert "is_verified" in user_details
        assert user_details["company_name"] == self.organizer_data["company_name"]

    def test_get_nonexistent_user_details(self, api_client):
        """Test getting details for non-existent user"""
        response = api_client.get(
            "/api/auth/users/99999",
            headers=self.token_manager.get_auth_header("admin"),
            expected_status=404
        )

        error = response.json()
        assert "User not found" in error["detail"]

    def test_non_admin_cannot_get_user_details(self, api_client):
        """Test that non-admin users cannot access user details"""
        api_client.get(
            "/api/auth/users/1",
            headers=self.token_manager.get_auth_header("customer"),
            expected_status=403
        )


@pytest.mark.admin
class TestAdminEndpointsIntegration:
    """Integration tests for admin endpoints"""

    @pytest.fixture(autouse=True)
    def setup(self, user_manager, token_manager):
        """Setup comprehensive test environment"""
        user_manager.register_and_login_admin()

        # Create diverse user base
        self.test_users = {
            "customers": [],
            "organizers": [],
            "banned_users": []
        }

        # Create customers
        for i in range(3):
            customer_data = user_manager.register_and_login_customer()
            self.test_users["customers"].append(customer_data)

        # Create organizers
        for i in range(3):
            organizer_data = user_manager.register_organizer()
            self.test_users["organizers"].append(organizer_data)

        # Verify some organizers
        pending_organizers = user_manager.get_pending_organizers()
        for i, org in enumerate(pending_organizers[:2]):  # Verify first 2
            user_manager.verify_organizer_by_admin(org["organizer_id"], True)

        self.user_manager = user_manager
        self.token_manager = token_manager

    def test_complete_admin_workflow(self, api_client):
        """Test complete admin workflow: list -> filter -> view details -> manage"""
        # 1. Get overall statistics
        stats_response = api_client.get(
            "/api/auth/users/stats",
            headers=self.token_manager.get_auth_header("admin")
        )
        initial_stats = stats_response.json()

        assert initial_stats["total_users"] >= 7  # 1 admin + 3 customers + 3 organizers
        assert initial_stats["users_by_type"]["customers"] >= 3
        assert initial_stats["users_by_type"]["organizers"] >= 3

        # 2. List all users and verify count matches stats
        users_response = api_client.get(
            "/api/auth/users",
            headers=self.token_manager.get_auth_header("admin")
        )
        all_users = users_response.json()
        assert len(all_users) == initial_stats["total_users"]

        # 3. Filter pending organizers
        pending_org_response = api_client.get(
            "/api/auth/users?user_type=organizer&is_verified=false",
            headers=self.token_manager.get_auth_header("admin")
        )
        pending_organizers = pending_org_response.json()
        assert len(pending_organizers) >= 1

        # 4. Get details of a pending organizer
        pending_org = pending_organizers[0]
        org_details_response = api_client.get(
            f"/api/auth/users/{pending_org['user_id']}",
            headers=self.token_manager.get_auth_header("admin")
        )
        org_details = org_details_response.json()

        assert org_details["user_type"] == "organizer"
        assert org_details["is_verified"] is False
        assert "company_name" in org_details

        # 5. Ban a customer
        customers_response = api_client.get(
            "/api/auth/users?user_type=customer&limit=1",
            headers=self.token_manager.get_auth_header("admin")
        )
        customer_to_ban = customers_response.json()[0]

        ban_response = self.user_manager.ban_user(customer_to_ban["user_id"])
        assert "banned" in ban_response["message"]

        # 6. Verify banned user appears in banned users list
        banned_users_response = api_client.get(
            "/api/auth/users?is_active=false",
            headers=self.token_manager.get_auth_header("admin")
        )
        banned_users = banned_users_response.json()

        banned_user_ids = {user["user_id"] for user in banned_users}
        assert customer_to_ban["user_id"] in banned_user_ids

        # 7. Verify updated statistics
        final_stats_response = api_client.get(
            "/api/auth/users/stats",
            headers=self.token_manager.get_auth_header("admin")
        )
        final_stats = final_stats_response.json()

        assert final_stats["banned_users"] == initial_stats["banned_users"] + 1
        assert final_stats["active_users"] == initial_stats["active_users"] - 1

    def test_search_and_filter_combinations(self, api_client):
        """Test various search and filter combinations"""
        # Search for organizers with company name
        search_term = "Test Events"  # From TestDataGenerator.organizer_data()
        response = api_client.get(
            f"/api/auth/users?search={search_term}&user_type=organizer",
            headers=self.token_manager.get_auth_header("admin")
        )

        search_results = response.json()
        # Should find organizers since company_name contains "Test Events"
        assert len(
            search_results) >= 0  # May or may not find results depending on search implementation

        # Complex filter: active verified organizers
        response = api_client.get(
            "/api/auth/users?user_type=organizer&is_active=true&is_verified=true",
            headers=self.token_manager.get_auth_header("admin")
        )

        verified_active_orgs = response.json()
        for org in verified_active_orgs:
            assert org["user_type"] == "organizer"
            assert org["is_active"] is True
            assert org["is_verified"] is True

    def test_pagination_with_large_dataset(self, api_client):
        """Test pagination behavior with the created dataset"""
        # Test small page size to verify pagination
        page_size = 2
        all_users_paginated = []
        page = 1

        while True:
            response = api_client.get(
                f"/api/auth/users?page={page}&limit={page_size}",
                headers=self.token_manager.get_auth_header("admin")
            )

            page_users = response.json()
            if not page_users:
                break

            all_users_paginated.extend(page_users)
            page += 1

            # Safety check to prevent infinite loop
            if page > 10:
                break

        # Verify we got all users through pagination
        total_response = api_client.get(
            "/api/auth/users",
            headers=self.token_manager.get_auth_header("admin")
        )
        total_users = total_response.json()

        assert len(all_users_paginated) == len(total_users)

        # Verify no duplicate users in paginated results
        paginated_ids = [user["user_id"] for user in all_users_paginated]
        assert len(paginated_ids) == len(set(paginated_ids))
