#!/usr/bin/env python3
"""
Resellio API Gateway Test Framework
----------------------------------
A modular testing framework for the Resellio API Gateway.
"""

import os
import sys
import json
import time
import random
import string
import argparse
from datetime import datetime

import colorama
from tabulate import tabulate
from colorama import Fore, Style

colorama.init()

CONFIG = {
    "base_url": "http://localhost:8080",
    "timeout": 10,
    "verbose": True,
}

# Store tokens for authentication between test modules
TOKENS = {
    "customer": None,
    "organizer": None,
    "admin": None,
}

# Store test results
RESULTS = []

# Test user credentials
TEST_USERS = {}


class GatewayTestClient:
    """API Gateway test client to handle HTTP requests and responses"""

    def __init__(
        self,
        config=None,
    ):
        import requests

        self.requests = requests
        self.config = config or CONFIG

    def request(
        self,
        method,
        url,
        headers=None,
        data=None,
        json_data=None,
        expected_status=200,
    ):
        """Make an HTTP request and return the response"""
        full_url = f"{self.config['base_url']}{url}"

        start_time = time.time()

        try:
            response = None

            if method.upper() == "GET":
                response = self.requests.get(
                    full_url,
                    headers=headers,
                    timeout=self.config["timeout"],
                )
            elif method.upper() == "POST":
                response = self.requests.post(
                    full_url,
                    headers=headers,
                    data=data,
                    json=json_data,
                    timeout=self.config["timeout"],
                )
            elif method.upper() == "PUT":
                response = self.requests.put(
                    full_url,
                    headers=headers,
                    data=data,
                    json=json_data,
                    timeout=self.config["timeout"],
                )
            elif method.upper() == "DELETE":
                response = self.requests.delete(
                    full_url,
                    headers=headers,
                    data=data,
                    json=json_data,
                    timeout=self.config["timeout"],
                )
            else:
                raise ValueError(f"Invalid HTTP method: {method}")

            elapsed = time.time() - start_time

            return {
                "response": response,
                "status_code": response.status_code,
                "elapsed": elapsed,
                "success": response.status_code == expected_status,
            }

        except Exception as e:
            elapsed = time.time() - start_time
            return {
                "response": None,
                "status_code": None,
                "elapsed": elapsed,
                "success": False,
                "error": str(e),
            }


class TestCase:
    """Base class for all test cases"""

    def __init__(
        self,
        client=None,
    ):
        """Initialize the test case with a client"""
        self.client = client or GatewayTestClient()

    def run_test(
        self,
        name,
        method,
        url,
        expected_status=200,
        headers=None,
        data=None,
        json_data=None,
        extract_token=False,
        token_type=None,
    ):
        """Run a test and record the result"""

        print(f"{Fore.YELLOW}Testing: {Style.RESET_ALL} {name}")
        print(f"{Fore.YELLOW}URL: {Style.RESET_ALL} {method} {url}")

        if headers:
            print(f"{Fore.YELLOW}Headers: {Style.RESET_ALL} {headers}")
        if data:
            print(f"{Fore.YELLOW}Form Data: {Style.RESET_ALL} {data}")
        if json_data:
            print(f"{Fore.YELLOW}JSON Data: {Style.RESET_ALL} {json.dumps(json_data, indent=2)}")

        result = self.client.request(
            method=method,
            url=url,
            headers=headers,
            data=data,
            json_data=json_data,
            expected_status=expected_status,
        )

        # Extract token if needed
        if extract_token and token_type and result["success"]:
            try:
                response_json = result["response"].json()
                if "token" in response_json:
                    TOKENS[token_type] = response_json["token"]
                    print(f"{Fore.YELLOW}Token ({token_type}): {Style.RESET_ALL} {TOKENS[token_type][:20]}...")
            except Exception as e:
                print(f"{Fore.RED}Error extracting token: {str(e)}{Style.RESET_ALL}")

        if result["success"]:
            status = "Pass"
            status_color = Fore.GREEN
        else:
            status = "Fail"
            status_color = Fore.RED

        status_code = result["status_code"] if result["status_code"] else "Error"
        print(f"{status_color}Status Code: {Style.RESET_ALL} {status_code} (Expected: {expected_status}) - {status}")
        print(f"{Fore.YELLOW}Response Time: {Style.RESET_ALL} {result['elapsed']: .4f}s")

        # Print response body (first part only if large)
        if result["response"]:
            try:
                response_text = json.dumps(result["response"].json(), indent=2)
                if len(response_text) > 500:
                    response_text = response_text[:500] + "..."
            except Exception as e:
                print(e)
                response_text = (
                    result["response"].text[:500] + "..."
                    if len(result["response"].text) > 500
                    else result["response"].text
                )

            print(f"{Fore.YELLOW}Response: {Style.RESET_ALL}\n{response_text}")
        elif "error" in result:
            print(f"{Fore.RED}Error: {result['error']}{Style.RESET_ALL}")

        # Add to results table
        RESULTS.append(
            [
                name,
                f"{method} {url}",
                expected_status,
                status_code,
                f"{result['elapsed']: .4f}s",
                status,
            ]
        )

        print("-" * 80)
        return result

    def auth_header(
        self,
        token_type,
    ):
        """Create authorization header with the specified token type"""
        if token_type in TOKENS and TOKENS[token_type]:
            return {"Authorization": f"Bearer {TOKENS[token_type]}"}
        print(f"{Fore.RED}Warning: No token available for {token_type}{Style.RESET_ALL}")
        return {}


# Utility functions
def print_header(
    text,
):
    """Print a formatted header"""
    print(f"\n{Fore.BLUE}{'=' * 20} {text} {'=' * 20}{Style.RESET_ALL}\n")


def generate_random_string(
    length=8,
):
    """Generate a random string for unique emails/usernames"""
    return "".join(random.choice(string.ascii_lowercase + string.digits) for _ in range(length))


def generate_test_users():
    """Generate random credentials for test users"""
    random_suffix = generate_random_string()
    
    # Get admin secret key from environment variable, with a fallback for local dev
    admin_key = os.getenv("ADMIN_SECRET_KEY", "local-admin-secret-key")

    TEST_USERS.update(
        {
            "customer": {
                "email": f"customer_{random_suffix}@example.com",
                "login": f"customer_{random_suffix}",
                "password": "Password123",
                "first_name": "Test",
                "last_name": "Customer",
            },
            "organizer": {
                "email": f"organizer_{random_suffix}@example.com",
                "login": f"organizer_{random_suffix}",
                "password": "Password123",
                "first_name": "Test",
                "last_name": "Organizer",
                "company_name": "Test Events Inc",
            },
            "admin": {
                "email": f"admin_{random_suffix}@example.com",
                "login": f"admin_{random_suffix}",
                "password": "Password123",
                "first_name": "Test",
                "last_name": "Admin",
                "admin_secret_key": admin_key, # <-- Use the variable here
            },
        }
    )

# Test modules - Each module tests a specific area of functionality
class HealthTests(TestCase):
    """Tests for basic health check endpoints"""

    def run_all(self):
        """Run all tests in this module"""
        print_header("Basic Health Checks")

        self.run_test(
            name="Gateway Health Check",
            method="GET",
            url="/health",
        )
        self.run_test(
            name="Gateway Root",
            method="GET",
            url="/",
        )


class AuthTests(TestCase):
    """Tests for authentication endpoints"""

    def run_all(self):
        """Run all tests in this module"""
        print_header("User Authentication Tests")

        # Customer authentication
        customer = TEST_USERS["customer"]
        self.run_test(
            name="Register Customer",
            method="POST",
            url="/api/auth/register/customer",
            expected_status=201,
            headers={"Content-Type": "application/json"},
            json_data=customer,
            extract_token=True,
            token_type="customer",
        )

        self.run_test(
            name="Customer Login",
            method="POST",
            url="/api/auth/token",
            expected_status=200,
            headers={"Content-Type": "application/x-www-form-urlencoded"},
            data={
                "username": customer["email"],
                "password": customer["password"],
            },
            extract_token=True,
            token_type="customer",
        )

        if TOKENS["customer"]:
            self.run_test(
                name="Get User Profile",
                method="GET",
                url="/api/user/me",
                expected_status=200,
                headers=self.auth_header("customer"),
            )

        # Organizer authentication
        print_header("Organizer Tests")

        organizer = TEST_USERS["organizer"]
        self.run_test(
            name="Register Organizer",
            method="POST",
            url="/api/auth/register/organizer",
            expected_status=201,
            headers={"Content-Type": "application/json"},
            json_data=organizer,
            extract_token=True,
            token_type="organizer",
        )

        self.run_test(
            name="Organizer Login",
            method="POST",
            url="/api/auth/token",
            expected_status=200,
            headers={"Content-Type": "application/x-www-form-urlencoded"},
            data={
                "username": organizer["email"],
                "password": organizer["password"],
            },
            extract_token=True,
            token_type="organizer",
        )

        # Admin authentication
        print_header("Admin Tests")

        admin = TEST_USERS["admin"]
        self.run_test(
            name="Register Admin",
            method="POST",
            url="/api/auth/register/admin",
            expected_status=201,
            headers={"Content-Type": "application/json"},
            json_data=admin,
            extract_token=True,
            token_type="admin",
        )

        self.run_test(
            name="Admin Login",
            method="POST",
            url="/api/auth/token",
            expected_status=200,
            headers={"Content-Type": "application/x-www-form-urlencoded"},
            data={
                "username": admin["email"],
                "password": admin["password"],
            },
            extract_token=True,
            token_type="admin",
        )

        # Admin functions
        if TOKENS["admin"]:
            pending_result = self.run_test(
                name="Get Pending Organizers",
                method="GET",
                url="/api/auth/pending-organizers",
                expected_status=200,
                headers=self.auth_header("admin"),
            )

            # Try to verify an organizer if possible
            if pending_result["success"] and pending_result["response"].json():
                try:
                    organizer_id = pending_result["response"].json()[0]["organiser_id"]
                    print(f"Found organizer ID: {organizer_id}")

                    self.run_test(
                        name="Verify Organizer",
                        method="POST",
                        url="/api/auth/verify-organizer",
                        expected_status=200,
                        headers={**self.auth_header("admin"), "Content-Type": "application/json"},
                        json_data={
                            "organizer_id": organizer_id,
                            "approve": True,
                        },
                    )

                    # Login as organizer again (now verified)
                    self.run_test(
                        name="Organizer Login (Verified)",
                        method="POST",
                        url="/api/auth/token",
                        expected_status=200,
                        headers={"Content-Type": "application/x-www-form-urlencoded"},
                        data={
                            "username": organizer["email"],
                            "password": organizer["password"],
                        },
                        extract_token=True,
                        token_type="organizer",
                    )
                except (KeyError, IndexError, ValueError):
                    print(f"{Fore.RED}No pending organizers found or couldn't extract organizer ID{Style.RESET_ALL}")


class EventTests(TestCase):
    """Tests for event endpoints"""

    def run_all(self):
        """Run all tests in this module"""
        print_header("Events Service Tests")

        # Get events list (no auth needed)
        self.run_test(
            name="Get Events",
            method="GET",
            url="/api/events",
        )

        # Create an event (requires organizer token)
        if TOKENS["organizer"]:
            event_data = {
                "organizer_id": 1,  # Using default ID
                "name": "Test Concert",
                "description": "A test concert event",
                "start": datetime.now().isoformat(),
                "end": datetime.now().isoformat(),
                "minimum_age": 18,
                "location": "Test Venue",
                "category": ["Music", "Live"],
                "total_tickets": 100,
            }
            self.run_test(
                name="Create Event",
                method="POST",
                url="/api/events/",
                expected_status=200,
                headers={**self.auth_header("organizer"), "Content-Type": "application/json"},
                json_data=event_data,
            )


class TicketTests(TestCase):
    """Tests for ticket and ticket type endpoints"""

    def run_all(self):
        """Run all tests in this module"""
        print_header("Ticket Types Tests")

        # Get ticket types (no auth needed)
        self.run_test(
            name="Get Ticket Types",
            method="GET",
            url="/api/ticket-types/",
        )

        # Create a ticket type (requires organizer token)
        if TOKENS["organizer"]:
            ticket_type_data = {
                "type_id": 1,
                "event_id": 1,
                "description": "VIP Access",
                "max_count": 50,
                "price": 149.99,
                "currency": "PLN",
                "available_from": "2025-04-15T10:00:00",
            }
            self.run_test(
                name="Create Ticket Type",
                method="POST",
                url="/api/ticket-types/",
                expected_status=200,
                headers={**self.auth_header("organizer"), "Content-Type": "application/json"},
                json_data=ticket_type_data,
            )


class CartTests(TestCase):
    """Tests for shopping cart endpoints"""

    def run_all(self):
        """Run all tests in this module"""
        print_header("Cart Tests")

        # Add to cart (requires customer token)
        if TOKENS["customer"]:
            cart_item_data = {
                "ticket_id": 1,
                "ticket_type_id": 1,
                "seat": "A1",
            }
            self.run_test(
                name="Add to Cart",
                method="POST",
                url="/api/cart/items",
                expected_status=200,
                headers={**self.auth_header("customer"), "Content-Type": "application/json"},
                json_data=cart_item_data,
            )

            # Get cart items
            self.run_test(
                name="Get Cart Items",
                method="GET",
                url="/api/cart/items",
                expected_status=200,
                headers=self.auth_header("customer"),
            )

            # Checkout
            self.run_test(
                name="Checkout",
                method="POST",
                url="/api/cart/checkout",
                expected_status=200,
                headers=self.auth_header("customer"),
            )


class ErrorTests(TestCase):
    """Tests for error handling"""

    def run_all(self):
        """Run all tests in this module"""
        print_header("Error Handling Tests")

        # Invalid authentication
        self.run_test(
            name="Invalid Authentication",
            method="GET",
            url="/api/user/me",
            expected_status=401,
            headers={"Authorization": "Bearer INVALID_TOKEN"},
        )

        # Non-existent endpoint
        self.run_test(
            name="Non-existent Endpoint",
            method="GET",
            url="/api/non-existent",
            expected_status=404,
        )

        # Unauthorized access
        if TOKENS["customer"]:
            self.run_test(
                name="Unauthorized Access",
                method="GET",
                url="/api/auth/pending-organizers",
                expected_status=403,
                headers=self.auth_header("customer"),
            )


def print_results():
    """Print test results and statistics"""
    print_header("Test Results Summary")
    headers = ["Test", "Endpoint", "Expected", "Actual", "Time", "Result"]
    print(tabulate(RESULTS, headers=headers, tablefmt="grid"))

    # Print summary statistics
    passed = sum(1 for r in RESULTS if r[5] == "Pass")
    failed = sum(1 for r in RESULTS if r[5] == "Fail")
    total = len(RESULTS)
    pass_rate = (passed / total) * 100 if total > 0 else 0

    print(f"\n{Fore.BLUE}Summary: {Style.RESET_ALL}")
    print(f"Total Tests: {total}")
    print(f"Passed: {Fore.GREEN}{passed}{Style.RESET_ALL} ({pass_rate: .1f}%)")
    print(f"Failed: {Fore.RED}{failed}{Style.RESET_ALL} ({100-pass_rate: .1f}%)")

    return passed, failed, total


def parse_args():
    """Parse command-line arguments"""
    parser = argparse.ArgumentParser(description="Test the API Gateway")
    parser.add_argument(
        "--url",
        default="http://localhost:8080",
        help="Base URL for the API Gateway",
    )
    parser.add_argument(
        "--timeout",
        type=int,
        default=10,
        help="Request timeout in seconds",
    )
    parser.add_argument(
        "--tests",
        help="Comma-separated list of test modules to run (default: all)",
    )
    parser.add_argument(
        "--quiet",
        action="store_true",
        help="Disable verbose output",
    )
    return parser.parse_args()


def main():
    """Main entry point"""
    args = parse_args()

    # Update configuration
    CONFIG.update(
        {
            "base_url": args.url,
            "timeout": args.timeout,
            "verbose": not args.quiet,
        }
    )

    # Create client
    client = GatewayTestClient(CONFIG)

    # Generate test users
    generate_test_users()

    print_header("API Gateway Testing Framework")

    # Available test modules
    test_modules = {
        "health": HealthTests(client),
        "auth": AuthTests(client),
        "events": EventTests(client),
        "tickets": TicketTests(client),
        "cart": CartTests(client),
        "errors": ErrorTests(client),
    }

    # Determine which tests to run
    if args.tests:
        modules_to_run = [m.strip() for m in args.tests.split(",")]
        # Validate modules
        for module in modules_to_run:
            if module not in test_modules:
                print(f"{Fore.RED}Error: Unknown test module '{module}'{Style.RESET_ALL}")
                print(f"Available modules: {', '.join(test_modules.keys())}")
                return 1
    else:
        modules_to_run = list(test_modules.keys())

    # Run selected test modules
    for module_name in modules_to_run:
        test_modules[module_name].run_all()

    # Print results
    _, failed, _ = print_results()

    # Return exit code based on test results
    return 0 if failed == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
