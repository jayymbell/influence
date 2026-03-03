"""Tests for the /up health-check endpoint."""


def test_health_check_returns_ok(client):
    resp = client.get("/up")
    assert resp.status_code == 200
    assert resp.json() == {"status": "ok"}
