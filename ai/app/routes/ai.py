import os

import httpx
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from app.crews.general_crew import run_general_crew

router = APIRouter()

BACKEND_URL = os.getenv("BACKEND_URL", "http://backend:3000")


class PromptRequest(BaseModel):
    """A simple example request body."""
    prompt: str


class PromptResponse(BaseModel):
    """A simple example response body."""
    result: str


@router.post("/prompt", response_model=PromptResponse)
async def handle_prompt(body: PromptRequest):
    """
    AI prompt endpoint powered by the CrewAI general assistant.

    Receives a prompt, runs it through the general assistant crew,
    and returns the agent's answer.
    """
    try:
        crew_result = await run_general_crew(description=body.prompt)
        return PromptResponse(result=crew_result["answer"])
    except ValueError as exc:
        raise HTTPException(status_code=500, detail=str(exc))
    except Exception as exc:
        raise HTTPException(
            status_code=502,
            detail=f"Crew execution failed: {exc}",
        )


@router.get("/ping-backend")
async def ping_backend():
    """Call the Rails backend /up endpoint to verify inter-service connectivity."""
    try:
        async with httpx.AsyncClient() as client:
            resp = await client.get(f"{BACKEND_URL}/up", timeout=5.0)
            resp.raise_for_status()
            return {"backend_status": resp.status_code, "backend_body": resp.text}
    except httpx.HTTPError as exc:
        raise HTTPException(
            status_code=502,
            detail=f"Could not reach backend: {exc}",
        )
