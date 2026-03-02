import os

import httpx
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

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
    Example AI endpoint.

    Receives a prompt, processes it, and returns a result.
    Demonstrates calling back to the Rails backend over HTTP.
    """
    # --- Example: call back to the Rails backend ---------------------------
    # Uncomment when you have an endpoint to call:
    #
    # async with httpx.AsyncClient() as client:
    #     resp = await client.get(f"{BACKEND_URL}/up")
    #     resp.raise_for_status()

    # Placeholder AI logic – replace with your model / LLM call
    result = f"Echo: {body.prompt}"

    return PromptResponse(result=result)


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
