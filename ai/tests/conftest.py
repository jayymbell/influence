"""
Shared fixtures for the AI service test suite.
"""

import os
import pytest
from httpx import ASGITransport, AsyncClient

# Ensure GITHUB_TOKEN is set so modules that read it at import time
# don't fail. Individual tests can override via monkeypatch.
os.environ.setdefault("GITHUB_TOKEN", "test-token-for-unit-tests")

from app.main import app  # noqa: E402  (must come after env setup)


@pytest.fixture
def client():
    """Synchronous TestClient for FastAPI (httpx-based)."""
    from fastapi.testclient import TestClient

    return TestClient(app)


@pytest.fixture
async def async_client():
    """Async httpx client for FastAPI."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac
