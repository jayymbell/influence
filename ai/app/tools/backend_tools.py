"""
Example CrewAI tool that calls the Rails backend.

Demonstrates how an agent can use a tool to fetch data from the backend
service over the Docker network.
"""

import os
from typing import Type

import requests
from crewai.tools import BaseTool
from pydantic import BaseModel, Field

BACKEND_URL: str = os.getenv("BACKEND_URL", "http://backend:3000")


class BackendHealthInput(BaseModel):
    """Input schema for the backend health-check tool (no params needed)."""
    pass


class BackendHealthTool(BaseTool):
    """
    Checks if the Rails backend is healthy by calling GET /up.

    This is a minimal example.  Add your own tools following this pattern:
      1. Define an input schema (Pydantic BaseModel).
      2. Subclass BaseTool with name, description, args_schema.
      3. Implement _run() with the tool logic.
    """

    name: str = "backend_health_check"
    description: str = (
        "Checks whether the Rails backend service is online by calling "
        "its /up health endpoint. Returns the HTTP status code."
    )
    args_schema: Type[BaseModel] = BackendHealthInput

    def _run(self) -> str:
        try:
            resp = requests.get(
                f"{BACKEND_URL}/up",
                headers={"User-Agent": "AI-Service-CrewAI/1.0"},
                timeout=10,
            )
            return f"Backend responded with status {resp.status_code}."
        except requests.RequestException as exc:
            return f"Could not reach backend: {exc}"


class BackendRequestInput(BaseModel):
    """Input schema for making arbitrary GET requests to the backend."""
    path: str = Field(
        ...,
        description="The URL path to request from the backend, e.g. '/users' or '/roles'",
    )


class BackendRequestTool(BaseTool):
    """
    Makes a GET request to an arbitrary path on the Rails backend.

    Useful for agents that need to fetch data from the backend API.
    """

    name: str = "backend_request"
    description: str = (
        "Makes a GET request to the Rails backend at the given path "
        "and returns the response body. Use this to fetch data from "
        "backend API endpoints."
    )
    args_schema: Type[BaseModel] = BackendRequestInput

    def _run(self, path: str) -> str:
        url = f"{BACKEND_URL}{path}"
        try:
            resp = requests.get(
                url,
                headers={"User-Agent": "AI-Service-CrewAI/1.0"},
                timeout=15,
            )
            return (
                f"Status: {resp.status_code}\n"
                f"Body: {resp.text[:2000]}"
            )
        except requests.RequestException as exc:
            return f"Request to {url} failed: {exc}"
