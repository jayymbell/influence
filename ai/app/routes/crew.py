"""
Routes for running CrewAI crews via HTTP.

POST /crew/run          — run the general assistant crew
POST /crew/research     — run the research crew
"""

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field

from app.crews.general_crew import run_general_crew, run_research_crew

router = APIRouter()


# ── Request / Response schemas ───────────────────────────────────────────


class CrewRunRequest(BaseModel):
    """Body for kicking off a crew."""
    task: str = Field(
        ...,
        description="Description of what the agent should do",
    )
    model: str | None = Field(
        default=None,
        description="GitHub Models model name (e.g. 'gpt-4o'). Uses env default if omitted.",
    )
    expected_output: str = Field(
        default="A clear, concise answer to the user's question.",
        description="Describes what a good answer looks like (guides the agent).",
    )


class CrewRunResponse(BaseModel):
    """Structured response from a crew run."""
    answer: str = Field(..., description="The agent's final answer")
    reasoning: str = Field(
        default="", description="How the answer was derived"
    )
    raw: str = Field(
        default="", description="Raw crew output for debugging"
    )


# ── Endpoints ────────────────────────────────────────────────────────────


@router.post("/run", response_model=CrewRunResponse)
async def crew_run(body: CrewRunRequest):
    """
    Run the general assistant crew.

    The agent has access to backend tools and will reason through the
    task step-by-step before returning a structured answer.
    """
    try:
        result = await run_general_crew(
            description=body.task,
            model=body.model,
            expected_output=body.expected_output,
        )
        return CrewRunResponse(**result)
    except ValueError as exc:
        raise HTTPException(status_code=500, detail=str(exc))
    except Exception as exc:
        raise HTTPException(
            status_code=502,
            detail=f"Crew execution failed: {exc}",
        )


@router.post("/research", response_model=CrewRunResponse)
async def crew_research(body: CrewRunRequest):
    """
    Run the research crew.

    Uses the research agent, which is optimised for thorough investigation
    and structured findings.
    """
    try:
        result = await run_research_crew(
            description=body.task,
            model=body.model,
            expected_output=body.expected_output,
        )
        return CrewRunResponse(**result)
    except ValueError as exc:
        raise HTTPException(status_code=500, detail=str(exc))
    except Exception as exc:
        raise HTTPException(
            status_code=502,
            detail=f"Crew execution failed: {exc}",
        )
