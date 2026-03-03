"""
Task factory functions for CrewAI.

Tasks describe *what* an agent should do.  They are paired with agents
when assembling a Crew.
"""

from crewai import Task, Agent
from pydantic import BaseModel, Field


# ── Output schemas ───────────────────────────────────────────────────────


class TaskResult(BaseModel):
    """Generic structured output for a single-task crew."""
    answer: str = Field(..., description="The agent's final answer")
    reasoning: str = Field(
        default="",
        description="Brief explanation of how the answer was derived",
    )


# ── Task factories ───────────────────────────────────────────────────────


def create_general_task(
    description: str,
    agent: Agent,
    expected_output: str = "A clear, concise answer to the user's question.",
    output_pydantic: type[BaseModel] | None = None,
) -> Task:
    """
    Build a general-purpose task from a user-supplied description.

    Parameters
    ----------
    description : str
        What the agent should do (the "prompt").
    agent : Agent
        The agent assigned to this task.
    expected_output : str
        What a good answer looks like (guides the agent).
    output_pydantic : type[BaseModel], optional
        If provided, CrewAI will parse the agent's output into this
        Pydantic model automatically.
    """
    return Task(
        description=description,
        expected_output=expected_output,
        agent=agent,
        output_pydantic=output_pydantic or TaskResult,
    )
