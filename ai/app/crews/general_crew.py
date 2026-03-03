"""
Crew assembly — wires agents + tasks into runnable Crews.

Usage from a route:

    from app.crews.general_crew import run_general_crew
    result = await run_general_crew("Summarise the latest users")
"""

import asyncio
from typing import Any

from crewai import Crew, Process

from app.agents.base_agents import create_general_assistant, create_researcher
from app.tasks.base_tasks import TaskResult, create_general_task


async def run_general_crew(
    description: str,
    *,
    model: str | None = None,
    expected_output: str = "A clear, concise answer to the user's question.",
    verbose: bool = True,
) -> dict[str, Any]:
    """
    Spin up a single-agent crew, execute the task, and return the result.

    Because ``crew.kickoff()`` is synchronous (it blocks), we run it
    inside ``asyncio.to_thread`` so it doesn't stall the FastAPI event loop.

    Returns
    -------
    dict
        ``{"answer": "...", "reasoning": "...", "raw": "..."}``
    """
    agent = create_general_assistant(model=model, verbose=verbose)
    task = create_general_task(
        description=description,
        agent=agent,
        expected_output=expected_output,
        output_pydantic=TaskResult,
    )

    crew = Crew(
        agents=[agent],
        tasks=[task],
        process=Process.sequential,
        verbose=verbose,
    )

    # crew.kickoff() is blocking — offload to a thread
    result = await asyncio.to_thread(crew.kickoff)

    # Extract the structured output
    if hasattr(result, "pydantic") and result.pydantic is not None:
        task_result: TaskResult = result.pydantic
        return {
            "answer": task_result.answer,
            "reasoning": task_result.reasoning,
            "raw": str(result),
        }

    return {
        "answer": str(result),
        "reasoning": "",
        "raw": str(result),
    }


async def run_research_crew(
    description: str,
    *,
    model: str | None = None,
    tools: list | None = None,
    expected_output: str = "Well-structured research findings with sources.",
    verbose: bool = True,
) -> dict[str, Any]:
    """
    Spin up a research-focused crew.

    Same pattern as ``run_general_crew`` but uses the researcher agent,
    which can be given additional domain-specific tools.
    """
    agent = create_researcher(model=model, tools=tools, verbose=verbose)
    task = create_general_task(
        description=description,
        agent=agent,
        expected_output=expected_output,
        output_pydantic=TaskResult,
    )

    crew = Crew(
        agents=[agent],
        tasks=[task],
        process=Process.sequential,
        verbose=verbose,
    )

    result = await asyncio.to_thread(crew.kickoff)

    if hasattr(result, "pydantic") and result.pydantic is not None:
        task_result: TaskResult = result.pydantic
        return {
            "answer": task_result.answer,
            "reasoning": task_result.reasoning,
            "raw": str(result),
        }

    return {
        "answer": str(result),
        "reasoning": "",
        "raw": str(result),
    }
