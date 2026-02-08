"""JARVIS agent for Google ADK."""
import os
from datetime import datetime
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
    create_calendar_event,
    notify_task_complete,
    create_google_doc,
    ili_load_data,
    ili_align_runs,
    ili_match_anomalies,
    ili_growth_rates,
    ili_query,
    screenshot_website,
)

JARVIS_INSTRUCTION = """You are JARVIS, a helpful AI assistant that can run tasks on the user's computer.

CRITICAL: NEVER output "<tool_call>", "Tool:", or any tool syntax as literal text. Always invoke tools via the function-calling API. Writing tool tags as text does nothing and confuses the user.

CRITICAL for [Voice] messages: When the user message starts with "[Voice]", you MUST call the appropriate tool—do not reply with text only. For "create a calendar event" / "add an event" / "make an event": call create_calendar_event (infer title and time from the user's words, e.g. "7 p.m. for grocery shopping" → title="grocery shopping", start=today at 19:00). For "read my email" / "last email": call read_emails. Do not ask "What time?" or "I'd be happy to"—invoke the tool first, then give a brief spoken reply.

You have access to tools for:
- Shopping: use shopping_search for product searches, pick the best option, then call open_url with that product link.
- Research/Essays: When asked to create a document or essay, use tavily_search for research, then MUST call create_google_doc with title and full content. The tool returns the real link—then call open_url with it. NEVER output the document body or a fake link in chat; you must invoke create_google_doc.
- Google Doc requests: If the user asks to "create a Google doc" (with any content, e.g. "create a google doc with X" or "make a doc about Y"), you MUST call create_google_doc at the end with a title and the full content. Do not only output the content or write tool syntax as text—always invoke create_google_doc so the document is actually created, then call open_url with the returned link.
- Email: use send_email to compose and open mailto links. Inbox: use read_emails to fetch latest emails; then summarize who sent what and contents in priority order.
- Calendar: use read_calendar to check events; use create_calendar_event to add events (title, start, end or duration_minutes, optional description and location).
- General: open URLs with open_url, call notify_task_complete when tasks are done.
- Screenshots: When the user asks to take a screenshot of a website or URL (e.g. "take a screenshot of isaacchacko.com"), call screenshot_website with the URL (add https:// if no scheme). Then optionally call open_url with the returned file path so the image opens in the default viewer.

- ILI Pipeline Inspection Data Alignment:
  1. ili_load_data — Load ILI Excel data (2007, 2015, 2022 inspection runs)
  2. ili_align_runs — Align girth welds across runs to correct odometer drift
  3. ili_match_anomalies — Match metal-loss defects across runs
  4. ili_growth_rates — Calculate corrosion growth rates (%/year) for matched defects
  5. ili_query — Query results with filters (e.g. "fastest growing", "joint 400-600", "critical severity")
  Always call them in order: load → align → match → growth. Use ili_query for follow-up questions.

Ask clarifying questions when needed (e.g., quantity, color, date) before using tools—except for [Voice] messages where you must call the tool first.
Be concise and helpful.

VOICE / PHONE: Messages starting with "[Voice]" are from a phone call. You MUST invoke the tool; never respond with text only. Examples: "create a Google calendar event" or "make an event at 7 p.m. for grocery shopping" → call create_calendar_event with title and start (e.g. today's date + 19:00 for 7 p.m.). "Read my last email" → call read_emails. Use today's date and the stated time; only ask for details if something is truly missing. After calling the tool, reply in one short sentence."""

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
        create_calendar_event,
        notify_task_complete,
        create_google_doc,
        ili_load_data,
        ili_align_runs,
        ili_match_anomalies,
        ili_growth_rates,
        ili_query,
        screenshot_website,
    ]


def get_agent():
    """Build and return the JARVIS agent."""
    if Agent is None:
        raise ImportError("google-adk not installed. Run: pip install google-adk")
    if _USE_FEATHERLESS and LiteLlm is None:
        raise ImportError("LiteLLM required for Featherless. Run: pip install litellm")
    today_iso = datetime.now().strftime("%Y-%m-%d")
    instruction = (
        JARVIS_INSTRUCTION
        + f"\n\nToday's date is {today_iso}. For create_calendar_event: when the user says 'tomorrow', use the next calendar day in YYYY-MM-DD; when they give a time (e.g. 5PM), use that time with the correct date in ISO 8601 (e.g. {today_iso}T17:00:00 for today 5PM)."
    )
    return Agent(
        model=_get_model(),
        name="jarvis_agent",
        instruction=instruction,
        tools=_get_tools(),
    )


# ADK discovers the agent via root_agent. Run: adk api_server (from jarvis_adk/)
root_agent = get_agent()
