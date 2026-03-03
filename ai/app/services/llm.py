"""
Shared LLM instance for CrewAI agents.

Uses GitHub Models via a GitHub PAT, following the same pattern as:
    LLM(model="github/gpt-4o", api_key=os.environ.get("GITHUB_TOKEN"))
"""

import os

from crewai import LLM

GITHUB_TOKEN: str = os.getenv("GITHUB_TOKEN", "")
GITHUB_MODELS_MODEL: str = os.getenv("GITHUB_MODELS_MODEL", "gpt-4o")


def get_llm(model: str | None = None) -> LLM:
    """
    Return a CrewAI LLM configured for GitHub Models.

    Parameters
    ----------
    model : str, optional
        Model name without the ``github/`` prefix.
        Defaults to GITHUB_MODELS_MODEL env var (gpt-4o).
    """
    if not GITHUB_TOKEN:
        raise ValueError(
            "GITHUB_TOKEN is not set. "
            "Provide it via environment variable or .env file."
        )
    resolved = model or GITHUB_MODELS_MODEL
    return LLM(
        model=f"github/{resolved}",
        api_key=GITHUB_TOKEN,
    )
