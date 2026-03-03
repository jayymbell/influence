"""
Client for the GitHub Models API.

Uses a GitHub Personal Access Token (PAT) to call the GitHub Models
chat completions endpoint (OpenAI-compatible).

Docs: https://docs.github.com/en/github-models
API:  https://models.github.ai/inference/chat/completions
"""

import os
from typing import Any

import httpx

GITHUB_TOKEN: str = os.getenv("GITHUB_TOKEN", "")
GITHUB_MODELS_BASE: str = os.getenv(
    "GITHUB_MODELS_BASE", "https://models.github.ai/inference"
)
GITHUB_MODELS_MODEL: str = os.getenv("GITHUB_MODELS_MODEL", "gpt-4o")


def _headers() -> dict[str, str]:
    if not GITHUB_TOKEN:
        raise ValueError(
            "GITHUB_TOKEN is not set. "
            "Provide it via environment variable or .env file."
        )
    return {
        "Authorization": f"Bearer {GITHUB_TOKEN}",
        "Content-Type": "application/json",
        "Accept": "application/json",
    }


async def chat_completion(
    messages: list[dict[str, str]],
    *,
    model: str | None = None,
    temperature: float = 0.7,
    max_tokens: int = 1024,
    **kwargs: Any,
) -> dict:
    """
    Send a chat completion request to the GitHub Models API.

    Parameters
    ----------
    messages : list[dict]
        OpenAI-style messages, e.g.
        [{"role": "system", "content": "You are helpful."},
         {"role": "user",   "content": "Hello!"}]
    model : str, optional
        Model name. Defaults to GITHUB_MODELS_MODEL env var (gpt-4o).
    temperature : float
        Sampling temperature.
    max_tokens : int
        Maximum tokens in the response.

    Returns
    -------
    dict
        The raw JSON response from the GitHub Models API.
    """
    payload: dict[str, Any] = {
        "model": model or GITHUB_MODELS_MODEL,
        "messages": messages,
        "temperature": temperature,
        "max_tokens": max_tokens,
        **kwargs,
    }

    async with httpx.AsyncClient(timeout=60.0) as client:
        resp = await client.post(
            f"{GITHUB_MODELS_BASE}/chat/completions",
            headers=_headers(),
            json=payload,
        )
        resp.raise_for_status()
        return resp.json()
