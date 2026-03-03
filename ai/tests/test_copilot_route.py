"""Tests for the /copilot route handlers."""

from unittest.mock import AsyncMock, patch


SAMPLE_COPILOT_RESPONSE = {
    "choices": [
        {
            "message": {
                "role": "assistant",
                "content": "Hello! How can I help?",
            }
        }
    ],
    "model": "gpt-4o",
}


@patch("app.routes.copilot.copilot_client.chat_completion", new_callable=AsyncMock)
def test_copilot_chat_success(mock_chat, client):
    mock_chat.return_value = SAMPLE_COPILOT_RESPONSE

    resp = client.post(
        "/copilot/chat",
        json={
            "messages": [{"role": "user", "content": "Hi"}],
            "temperature": 0.5,
            "max_tokens": 512,
        },
    )

    assert resp.status_code == 200
    data = resp.json()
    assert data["message"] == "Hello! How can I help?"
    assert data["raw"] == SAMPLE_COPILOT_RESPONSE


@patch("app.routes.copilot.copilot_client.chat_completion", new_callable=AsyncMock)
def test_copilot_chat_extracts_message_from_single_choice(mock_chat, client):
    """The assistant text is extracted from choices[0].message.content."""
    mock_chat.return_value = {
        "choices": [
            {"message": {"role": "assistant", "content": "Sure thing!"}}
        ]
    }

    resp = client.post(
        "/copilot/chat",
        json={"messages": [{"role": "user", "content": "Hi"}]},
    )

    assert resp.status_code == 200
    assert resp.json()["message"] == "Sure thing!"


@patch("app.routes.copilot.copilot_client.chat_completion", new_callable=AsyncMock)
def test_copilot_chat_value_error_returns_500(mock_chat, client):
    mock_chat.side_effect = ValueError("GITHUB_TOKEN is not set")

    resp = client.post(
        "/copilot/chat",
        json={"messages": [{"role": "user", "content": "Hi"}]},
    )

    assert resp.status_code == 500
    assert "GITHUB_TOKEN" in resp.json()["detail"]


@patch("app.routes.copilot.copilot_client.chat_completion", new_callable=AsyncMock)
def test_copilot_chat_generic_error_returns_502(mock_chat, client):
    mock_chat.side_effect = RuntimeError("timeout")

    resp = client.post(
        "/copilot/chat",
        json={"messages": [{"role": "user", "content": "Hi"}]},
    )

    assert resp.status_code == 502
    assert "Copilot API error" in resp.json()["detail"]


def test_copilot_chat_invalid_body_returns_422(client):
    resp = client.post("/copilot/chat", json={"bad": "payload"})

    assert resp.status_code == 422
