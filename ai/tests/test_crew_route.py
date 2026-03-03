"""Tests for the /crew route handlers."""

from unittest.mock import AsyncMock, patch


CREW_RESULT = {
    "answer": "Research complete.",
    "reasoning": "Analysed 3 sources.",
    "raw": "raw crew output",
}


# ── POST /crew/run ───────────────────────────────────────────────────────


@patch("app.routes.crew.run_general_crew", new_callable=AsyncMock)
def test_crew_run_success(mock_crew, client):
    mock_crew.return_value = CREW_RESULT

    resp = client.post("/crew/run", json={"task": "Summarise users"})

    assert resp.status_code == 200
    data = resp.json()
    assert data["answer"] == "Research complete."
    assert data["reasoning"] == "Analysed 3 sources."
    assert data["raw"] == "raw crew output"


@patch("app.routes.crew.run_general_crew", new_callable=AsyncMock)
def test_crew_run_value_error_returns_500(mock_crew, client):
    mock_crew.side_effect = ValueError("bad config")

    resp = client.post("/crew/run", json={"task": "do something"})

    assert resp.status_code == 500
    assert "bad config" in resp.json()["detail"]


@patch("app.routes.crew.run_general_crew", new_callable=AsyncMock)
def test_crew_run_generic_error_returns_502(mock_crew, client):
    mock_crew.side_effect = RuntimeError("agent crashed")

    resp = client.post("/crew/run", json={"task": "do something"})

    assert resp.status_code == 502
    assert "Crew execution failed" in resp.json()["detail"]


# ── POST /crew/research ─────────────────────────────────────────────────


@patch("app.routes.crew.run_research_crew", new_callable=AsyncMock)
def test_crew_research_success(mock_crew, client):
    mock_crew.return_value = CREW_RESULT

    resp = client.post("/crew/research", json={"task": "Research AI trends"})

    assert resp.status_code == 200
    data = resp.json()
    assert data["answer"] == "Research complete."


@patch("app.routes.crew.run_research_crew", new_callable=AsyncMock)
def test_crew_research_with_custom_fields(mock_crew, client):
    mock_crew.return_value = CREW_RESULT

    resp = client.post(
        "/crew/research",
        json={
            "task": "Research AI trends",
            "model": "gpt-4o-mini",
            "expected_output": "Bullet-point summary.",
        },
    )

    assert resp.status_code == 200
    mock_crew.assert_awaited_once_with(
        description="Research AI trends",
        model="gpt-4o-mini",
        expected_output="Bullet-point summary.",
    )


@patch("app.routes.crew.run_research_crew", new_callable=AsyncMock)
def test_crew_research_generic_error_returns_502(mock_crew, client):
    mock_crew.side_effect = RuntimeError("boom")

    resp = client.post("/crew/research", json={"task": "x"})

    assert resp.status_code == 502


def test_crew_run_missing_task_returns_422(client):
    resp = client.post("/crew/run", json={})

    assert resp.status_code == 422
