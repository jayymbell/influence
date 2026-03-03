"""
Agent definitions for CrewAI.

Each agent has a role, goal, backstory, and optional tools.
The LLM is injected via the shared get_llm() helper.
"""

from crewai import Agent

from app.services.llm import get_llm
from app.tools.backend_tools import BackendHealthTool, BackendRequestTool


def create_general_assistant(
    model: str | None = None,
    verbose: bool = True,
) -> Agent:
    """
    A general-purpose assistant agent.

    Has access to backend tools so it can fetch data from the Rails API.
    """
    return Agent(
        role="General Assistant",
        goal=(
            "Help the user by answering questions, analysing data, and "
            "performing tasks accurately and concisely."
        ),
        backstory=(
            "You are an experienced AI assistant with broad knowledge. "
            "You have access to a backend API and can fetch live data "
            "when needed to answer questions or complete tasks."
        ),
        tools=[BackendHealthTool(), BackendRequestTool()],
        llm=get_llm(model),
        verbose=verbose,
        max_iter=10,
        max_execution_time=300,
        allow_delegation=False,
    )


def create_researcher(
    model: str | None = None,
    tools: list | None = None,
    verbose: bool = True,
) -> Agent:
    """
    A research-focused agent.

    Intended to be extended with domain-specific tools (web scrapers,
    database lookups, etc.).
    """
    return Agent(
        role="Research Specialist",
        goal=(
            "Conduct thorough research on the given topic and return "
            "well-structured, factual findings."
        ),
        backstory=(
            "You are a meticulous research analyst who values accuracy "
            "above all else.  You always cite your sources and present "
            "findings in a clear, organised manner."
        ),
        tools=tools or [BackendRequestTool()],
        llm=get_llm(model),
        verbose=verbose,
        max_iter=10,
        max_execution_time=300,
        allow_delegation=False,
    )
