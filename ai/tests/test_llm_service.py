"""Tests for app.services.llm (LLM factory)."""

from unittest.mock import patch, MagicMock

import pytest


class TestGetLlm:
    def test_raises_when_token_empty(self, monkeypatch):
        import app.services.llm as mod

        monkeypatch.setattr(mod, "GITHUB_TOKEN", "")
        with pytest.raises(ValueError, match="GITHUB_TOKEN is not set"):
            mod.get_llm()

    @patch("app.services.llm.LLM")
    def test_uses_default_model(self, mock_llm_cls, monkeypatch):
        import app.services.llm as mod

        monkeypatch.setattr(mod, "GITHUB_TOKEN", "ghp_TEST")
        monkeypatch.setattr(mod, "GITHUB_MODELS_MODEL", "gpt-4o")

        mod.get_llm()

        mock_llm_cls.assert_called_once_with(
            model="github/gpt-4o",
            api_key="ghp_TEST",
        )

    @patch("app.services.llm.LLM")
    def test_uses_custom_model(self, mock_llm_cls, monkeypatch):
        import app.services.llm as mod

        monkeypatch.setattr(mod, "GITHUB_TOKEN", "ghp_TEST")

        mod.get_llm(model="gpt-4o-mini")

        mock_llm_cls.assert_called_once_with(
            model="github/gpt-4o-mini",
            api_key="ghp_TEST",
        )
