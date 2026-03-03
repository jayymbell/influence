"""Tests for app.services.copilot_client."""

import os
from unittest.mock import AsyncMock, patch, MagicMock

import httpx
import pytest
import respx

# The module reads GITHUB_TOKEN at import time, so we ensure it's set
# via conftest.py (os.environ.setdefault).


class TestHeaders:
    def test_headers_raises_when_token_empty(self, monkeypatch):
        """_headers() must raise ValueError when GITHUB_TOKEN is empty."""
        import app.services.copilot_client as mod

        monkeypatch.setattr(mod, "GITHUB_TOKEN", "")
        with pytest.raises(ValueError, match="GITHUB_TOKEN is not set"):
            mod._headers()

    def test_headers_returns_bearer_token(self, monkeypatch):
        import app.services.copilot_client as mod

        monkeypatch.setattr(mod, "GITHUB_TOKEN", "ghp_TESTTOKEN")
        headers = mod._headers()
        assert headers["Authorization"] == "Bearer ghp_TESTTOKEN"
        assert headers["Content-Type"] == "application/json"


class TestChatCompletion:
    @respx.mock
    @pytest.mark.asyncio
    async def test_sends_correct_payload(self, monkeypatch):
        import app.services.copilot_client as mod

        monkeypatch.setattr(mod, "GITHUB_TOKEN", "ghp_TEST")
        monkeypatch.setattr(mod, "GITHUB_MODELS_BASE", "https://models.test")
        monkeypatch.setattr(mod, "GITHUB_MODELS_MODEL", "gpt-4o")

        expected_response = {"choices": [{"message": {"content": "Hi"}}]}
        route = respx.post("https://models.test/chat/completions").mock(
            return_value=httpx.Response(200, json=expected_response)
        )

        result = await mod.chat_completion(
            messages=[{"role": "user", "content": "Hello"}],
            temperature=0.3,
            max_tokens=256,
        )

        assert route.called
        request_json = route.calls[0].request.read()
        import json

        body = json.loads(request_json)
        assert body["model"] == "gpt-4o"
        assert body["temperature"] == 0.3
        assert body["max_tokens"] == 256
        assert body["messages"] == [{"role": "user", "content": "Hello"}]
        assert result == expected_response

    @respx.mock
    @pytest.mark.asyncio
    async def test_uses_custom_model(self, monkeypatch):
        import app.services.copilot_client as mod

        monkeypatch.setattr(mod, "GITHUB_TOKEN", "ghp_TEST")
        monkeypatch.setattr(mod, "GITHUB_MODELS_BASE", "https://models.test")

        route = respx.post("https://models.test/chat/completions").mock(
            return_value=httpx.Response(200, json={"choices": []})
        )

        await mod.chat_completion(
            messages=[{"role": "user", "content": "Hi"}],
            model="gpt-4o-mini",
        )

        import json

        body = json.loads(route.calls[0].request.read())
        assert body["model"] == "gpt-4o-mini"

    @respx.mock
    @pytest.mark.asyncio
    async def test_raises_on_http_error(self, monkeypatch):
        import app.services.copilot_client as mod

        monkeypatch.setattr(mod, "GITHUB_TOKEN", "ghp_TEST")
        monkeypatch.setattr(mod, "GITHUB_MODELS_BASE", "https://models.test")

        respx.post("https://models.test/chat/completions").mock(
            return_value=httpx.Response(500, text="Internal Server Error")
        )

        with pytest.raises(httpx.HTTPStatusError):
            await mod.chat_completion(
                messages=[{"role": "user", "content": "Hi"}],
            )
