"""Tests for the /ai route handlers."""

from unittest.mock import AsyncMock, patch

import pytest


# ── POST /ai/prompt ──────────────────────────────────────────────────────


@patch("app.routes.ai.run_general_crew", new_callable=AsyncMock)
def test_prompt_success(mock_crew, client):
    mock_crew.return_value = {"answer": "42", "reasoning": "", "raw": "42"}

    resp = client.post("/ai/prompt", json={"prompt": "What is the meaning of life?"})

    assert resp.status_code == 200
    data = resp.json()
    assert data["result"] == "42"
    mock_crew.assert_awaited_once_with(description="What is the meaning of life?")


@patch("app.routes.ai.run_general_crew", new_callable=AsyncMock)
def test_prompt_value_error_returns_500(mock_crew, client):
    mock_crew.side_effect = ValueError("Missing token")

    resp = client.post("/ai/prompt", json={"prompt": "hello"})

    assert resp.status_code == 500
    assert "Missing token" in resp.json()["detail"]


@patch("app.routes.ai.run_general_crew", new_callable=AsyncMock)
def test_prompt_generic_error_returns_502(mock_crew, client):
    mock_crew.side_effect = RuntimeError("network timeout")

    resp = client.post("/ai/prompt", json={"prompt": "hello"})

    assert resp.status_code == 502
    assert "Crew execution failed" in resp.json()["detail"]


def test_prompt_missing_body_returns_422(client):
    resp = client.post("/ai/prompt", json={})

    assert resp.status_code == 422


# ── GET /ai/ping-backend ────────────────────────────────────────────────


@patch("app.routes.ai.httpx.AsyncClient")
def test_ping_backend_success(mock_client_cls, client):
    """Verify that ping-backend proxies the Rails /up response."""
    mock_resp = type("Resp", (), {"status_code": 200, "text": "OK", "raise_for_status": lambda self: None})()
    mock_instance = AsyncMock()
    mock_instance.get.return_value = mock_resp
    mock_instance.__aenter__ = AsyncMock(return_value=mock_instance)
    mock_instance.__aexit__ = AsyncMock(return_value=False)
    mock_client_cls.return_value = mock_instance

    resp = client.get("/ai/ping-backend")

    assert resp.status_code == 200
    data = resp.json()
    assert data["backend_status"] == 200
    assert data["backend_body"] == "OK"
