"""Tests for app.tools.backend_tools (CrewAI tools)."""

from unittest.mock import patch, MagicMock

import requests

from app.tools.backend_tools import BackendHealthTool, BackendRequestTool


class TestBackendHealthTool:
    @patch("app.tools.backend_tools.requests.get")
    def test_returns_status_on_success(self, mock_get):
        mock_resp = MagicMock()
        mock_resp.status_code = 200
        mock_get.return_value = mock_resp

        tool = BackendHealthTool()
        result = tool._run()

        assert "200" in result
        assert "Backend responded" in result

    @patch("app.tools.backend_tools.requests.get")
    def test_returns_error_message_on_failure(self, mock_get):
        mock_get.side_effect = requests.ConnectionError("refused")

        tool = BackendHealthTool()
        result = tool._run()

        assert "Could not reach backend" in result
        assert "refused" in result


class TestBackendRequestTool:
    @patch("app.tools.backend_tools.requests.get")
    def test_returns_body_on_success(self, mock_get):
        mock_resp = MagicMock()
        mock_resp.status_code = 200
        mock_resp.text = '{"users": []}'
        mock_get.return_value = mock_resp

        tool = BackendRequestTool()
        result = tool._run(path="/users")

        assert "200" in result
        assert '{"users": []}' in result
        mock_get.assert_called_once()
        call_url = mock_get.call_args[0][0]
        assert call_url.endswith("/users")

    @patch("app.tools.backend_tools.requests.get")
    def test_returns_error_on_network_failure(self, mock_get):
        mock_get.side_effect = requests.ConnectionError("network down")

        tool = BackendRequestTool()
        result = tool._run(path="/roles")

        assert "failed" in result
        assert "network down" in result
