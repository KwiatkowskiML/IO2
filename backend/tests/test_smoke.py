import pytest
from helper import APIClient

@pytest.fixture(scope="module")
def api_client():
    """API client fixture for smoke tests"""
    return APIClient()

@pytest.mark.smoke
def test_gateway_health_check(api_client):
    """Tests the API Gateway's root /health endpoint."""
    response = api_client.get("/health", expected_status=200)
    assert "healthy" in response.text.lower()

@pytest.mark.smoke
def test_gateway_root(api_client):
    """Tests the API Gateway's root / endpoint."""
    response = api_client.get("/", expected_status=200)
    assert "api gateway is up" in response.text.lower()
