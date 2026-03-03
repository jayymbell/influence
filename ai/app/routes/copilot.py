"""Routes for interacting with the GitHub Copilot API."""

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field

from app.services import copilot_client

router = APIRouter()


# ── Request / Response schemas ───────────────────────────────────────────


class Message(BaseModel):
    role: str = Field(..., description="One of: system, user, assistant")
    content: str


class ChatRequest(BaseModel):
    messages: list[Message]
    model: str | None = Field(
        default=None,
        description="Model to use (defaults to COPILOT_MODEL env var)",
    )
    temperature: float = 0.7
    max_tokens: int = 1024


class ChatResponse(BaseModel):
    """Thin wrapper so callers get a predictable shape."""
    raw: dict = Field(..., description="Raw Copilot API response")
    message: str = Field(
        ..., description="The assistant reply text (convenience field)"
    )


# ── Endpoints ────────────────────────────────────────────────────────────


@router.post("/chat", response_model=ChatResponse)
async def copilot_chat(body: ChatRequest):
    """
    Send messages to GitHub Copilot and return the assistant's reply.
    """
    try:
        result = await copilot_client.chat_completion(
            messages=[m.model_dump() for m in body.messages],
            model=body.model,
            temperature=body.temperature,
            max_tokens=body.max_tokens,
        )
        # Extract the assistant message text from the response
        assistant_msg = (
            result.get("choices", [{}])[0]
            .get("message", {})
            .get("content", "")
        )
        return ChatResponse(raw=result, message=assistant_msg)
    except ValueError as exc:
        raise HTTPException(status_code=500, detail=str(exc))
    except Exception as exc:
        raise HTTPException(
            status_code=502,
            detail=f"Copilot API error: {exc}",
        )
