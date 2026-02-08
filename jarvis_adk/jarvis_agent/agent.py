"""JARVIS agent for Google ADK."""
import os
from pathlib import Path

from dotenv import load_dotenv

# Load .env from jarvis_adk root (parent of jarvis_agent)
_env_path = Path(__file__).resolve().parent.parent / ".env"
load_dotenv(_env_path)

# Map Featherless vars to LiteLLM's expected vars when using Featherless
if os.getenv("FEATHERLESS_BASE_URL") and not os.getenv("OPENAI_API_BASE"):
    os.environ["OPENAI_API_BASE"] = os.getenv("FEATHERLESS_BASE_URL", "")
if os.getenv("FEATHERLESS_API_KEY_1") and not os.getenv("OPENAI_API_KEY"):
    os.environ["OPENAI_API_KEY"] = os.getenv("FEATHERLESS_API_KEY_1", "")

# Import ADK components
try:
    from google.adk.agents import Agent
except ImportError:
    Agent = None
try:
    from google.adk.models.lite_llm import LiteLlm
except ImportError:
    LiteLlm = None

from .tools import (
    shopping_search,
    tavily_search,
    open_url,
    send_email,
    read_calendar,
    read_emails,
    notify_task_complete,
    create_google_doc,
)

JARVIS_INSTRUCTION = """You are JARVIS, a helpful AI assistant that can run tasks on the user's computer.

CRITICAL: NEVER output "<tool_call>", "Tool:", or any tool syntax as literal text. Always invoke tools via the function-calling API. Writing tool tags as text does nothing and confuses the user.

You have access to tools for:
- Shopping: use shopping_search for product searches, pick the best option, then call open_url with that product link.
- Research/Essays: When asked to create a document or essay, use tavily_search for research, then MUST call create_google_doc with title and full content. The tool returns the real link—then call open_url with it. NEVER output the document body or a fake link in chat; you must invoke create_google_doc.
- Email: use send_email to compose and open mailto links. Inbox: use read_emails to fetch latest emails; then summarize who sent what and contents in priority order.
- Calendar: use read_calendar to check events.
- General: open URLs with open_url, call notify_task_complete when tasks are done.

Ask clarifying questions when needed (e.g., quantity, color, date) before using tools.
Be concise and helpful."""

# Use Featherless via LiteLLM when OPENAI_API_BASE is set; otherwise Gemini
_USE_FEATHERLESS = bool(os.getenv("OPENAI_API_BASE"))
_FEATHERLESS_MODEL = os.getenv("ADK_MODEL") or os.getenv("FEATHERLESS_DEFAULT_MODEL", "Qwen/Qwen2.5-7B-Instruct")
_GEMINI_MODEL = os.getenv("ADK_MODEL", "gemini-2.0-flash")


def _get_model():
    """Return model config: LiteLlm for Featherless, else Gemini model string."""
    if _USE_FEATHERLESS and LiteLlm is not None:
        return LiteLlm(model=f"openai/{_FEATHERLESS_MODEL}")
    return _GEMINI_MODEL


def _get_tools():
    """Return tool functions for ADK. ADK auto-wraps them."""
    return [
        shopping_search,
        tavily_search,
        open_url,
        send_email,
        read_calendar,
        read_emails,
        notify_task_complete,
        create_google_doc,
    ]


def get_agent():
    """Build and return the JARVIS agent."""
    if Agent is None:
        raise ImportError("google-adk not installed. Run: pip install google-adk")
    if _USE_FEATHERLESS and LiteLlm is None:
        raise ImportError("LiteLLM required for Featherless. Run: pip install litellm")
    return Agent(
        model=_get_model(),
        name="jarvis_agent",
        instruction=JARVIS_INSTRUCTION,
        tools=_get_tools(),
    )


# ADK discovers the agent via root_agent. Run: adk api_server (from jarvis_adk/)
root_agent = get_agent()
