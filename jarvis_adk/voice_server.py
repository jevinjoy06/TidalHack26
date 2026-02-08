#!/usr/bin/env python3
"""
Twilio voice webhook server: answer calls, run speech through ADK, speak reply.
Only allowed callers (8329696324, 8326215771). Requires TWILIO_* and VOICE_WEBHOOK_BASE in .env.
"""

import json
import os
import re
import time
import xml.sax.saxutils
from datetime import datetime

import httpx
from dotenv import load_dotenv
from fastapi import FastAPI, Request, Form
from fastapi.responses import Response

# Load .env from jarvis_adk so TWILIO_* and VOICE_WEBHOOK_BASE are set before imports that read env
load_dotenv(os.path.join(os.path.dirname(__file__), ".env"))

DEBUG_LOG_PATH = "/Users/allenthomas/TidalHack26/.cursor/debug.log"


def _debug_log(location: str, message: str, data: dict | None = None, hypothesis_id: str | None = None) -> None:
    try:
        payload = {"location": location, "message": message, "data": data or {}, "timestamp": int(time.time() * 1000)}
        if hypothesis_id:
            payload["hypothesisId"] = hypothesis_id
        with open(DEBUG_LOG_PATH, "a") as f:
            f.write(json.dumps(payload) + "\n")
    except Exception:
        pass

ALLOWED_SENDER_DIGITS = ("8329696324", "8326215771", "2815208817")
ADK_URL = os.getenv("JARVIS_ADK_URL", "http://localhost:8000")
ADK_APP_NAME = "jarvis_agent"
# Match app: same userId. New session per request so each message is "first in session" like app.
USER_ID = "default_user"
VOICE_WEBHOOK_BASE = os.getenv("VOICE_WEBHOOK_BASE", "").rstrip("/")

app = FastAPI(title="JARVIS Voice")


def _get(obj, *keys):
    if not isinstance(obj, dict):
        return None
    for k in keys:
        if k in obj:
            return obj[k]
    return None


def normalize_caller_digits(caller: str) -> str:
    return re.sub(r"\D", "", caller) if caller else ""


def is_allowed_caller(caller: str) -> bool:
    if not caller:
        return False
    digits = normalize_caller_digits(caller)
    return any(digits == num or digits.endswith(num) for num in ALLOWED_SENDER_DIGITS)


def get_final_text_from_events(events: list[dict]) -> str | None:
    last_text = None
    for e in events:
        content = _get(e, "content")
        if not isinstance(content, dict):
            continue
        parts = _get(content, "parts")
        if not parts or not isinstance(parts, list):
            continue
        for p in parts:
            if isinstance(p, str):
                t = (p or "").strip()
                if t and "tool_call" not in t.lower():
                    last_text = p
                continue
            if not isinstance(p, dict):
                continue
            # ADK can return "text" (camelCase from API) or other part shapes
            text = _get(p, "text")
            if text is None:
                continue
            t = (text or "").strip()
            if not t:
                continue
            if "tool_call" in t.lower():
                stripped = re.sub(r"<{1,2}/?tool_call[^>]*>", "", t, flags=re.IGNORECASE).strip()
                if not stripped:
                    continue
            last_text = text
    return last_text


def get_tools_called_from_events(events: list[dict]) -> set[str]:
    names = set()
    for e in events:
        content = _get(e, "content")
        parts = _get(content, "parts") if isinstance(content, dict) else None
        if not parts:
            continue
        for p in parts:
            if not isinstance(p, dict):
                continue
            fc = _get(p, "functionCall", "function_call")
            if isinstance(fc, dict):
                n = _get(fc, "name", "Name")
                if n:
                    names.add(str(n))
    return names


def build_fallback_reply(events: list[dict]) -> str:
    tools = get_tools_called_from_events(events)
    if "create_google_doc" in tools:
        return "I ran your request. If you asked for a document, check your Google Docs."
    if "open_url" in tools:
        return "I ran your request. A link may have been opened in your browser."
    if tools:
        return "I ran your request but didn't get a clear summary."
    return "I was unable to generate a response. Try rephrasing your request."


def sanitize_reply(text: str) -> str:
    t = text.strip()
    if not t:
        return text
    if "tool_call" not in t.lower():
        return text
    stripped = re.sub(r"<{1,2}/?tool_call[^>]*>", "", t, flags=re.IGNORECASE).strip()
    return stripped if stripped else text


# Ordinal words for day-of-month (1–31) for spoken date
_ORDINAL = (
    None, "first", "second", "third", "fourth", "fifth", "sixth", "seventh", "eighth", "ninth", "tenth",
    "eleventh", "twelfth", "thirteenth", "fourteenth", "fifteenth", "sixteenth", "seventeenth", "eighteenth", "nineteenth", "twentieth",
    "twenty-first", "twenty-second", "twenty-third", "twenty-fourth", "twenty-fifth", "twenty-sixth", "twenty-seventh", "twenty-eighth", "twenty-ninth", "thirtieth", "thirty-first",
)


def _year_to_speech(year: int) -> str:
    """e.g. 2026 -> 'twenty twenty-six', 2020 -> 'twenty twenty'."""
    if year < 2000 or year > 2099:
        return str(year)
    _, b = divmod(year, 100)
    ones = ("", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine")
    teens = ("ten", "eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen", "seventeen", "eighteen", "nineteen")
    tens = ("", "", "twenty", "thirty", "forty", "fifty", "sixty", "seventy", "eighty", "ninety")
    if b < 10:
        second = ones[b]
    elif b < 20:
        second = teens[b - 10]
    else:
        t, o = divmod(b, 10)
        second = tens[t] + ("-" + ones[o] if o else "")
    return "twenty " + second if second else "twenty"


def _time_to_speech(h: int, m: int) -> str:
    """24h h,m -> e.g. '5 PM', '5:30 PM', 'noon', 'midnight'."""
    if h == 12 and m == 0:
        return "noon"
    if h == 0 and m == 0:
        return "midnight"
    if h == 0:
        hour_12 = 12
        am_pm = "AM"
    elif h < 12:
        hour_12, am_pm = h, "AM"
    elif h == 12:
        hour_12, am_pm = 12, "PM"
    else:
        hour_12, am_pm = h - 12, "PM"
    if m == 0:
        return f"{hour_12} {am_pm}"
    return f"{hour_12}:{m:02d} {am_pm}"


def _date_time_to_speech(d: datetime) -> str:
    """Single datetime -> e.g. 'February eighth, twenty twenty-six at 5 PM'."""
    month = d.strftime("%B")
    day = d.day
    day_word = _ORDINAL[day] if 1 <= day <= 31 else str(day)
    year_s = _year_to_speech(d.year)
    time_s = _time_to_speech(d.hour, d.minute)
    return f"{month} {day_word}, {year_s} at {time_s}"


def speech_friendly_dates(text: str) -> str:
    """Convert ISO dates/times in text to natural speech for TTS (e.g. 2026-02-08 at 17:00 -> February eighth, twenty twenty-six at 5 PM)."""
    if not text or not text.strip():
        return text

    out = text
    # Combined: 2026-02-08T17:00:00 or 2026-02-08T17:00 or 2026-02-08 at 17:00
    for m in re.finditer(
        r"(\d{4}-\d{2}-\d{2})(?:T|\s+at\s+)(\d{1,2})\s*:\s*(\d{2})(?:\s*:\s*(\d{2}))?",
        out,
    ):
        try:
            y, mo, d = int(m.group(1)[:4]), int(m.group(1)[5:7]), int(m.group(1)[8:10])
            h, mi = int(m.group(2)), int(m.group(3))
            sec = int(m.group(4)) if m.group(4) else 0
            dt = datetime(y, mo, d, h, mi, sec)
            out = out.replace(m.group(0), _date_time_to_speech(dt), 1)
        except (ValueError, KeyError, IndexError):
            pass
    # Date only: 2026-02-08 (avoid re-matching inside already-replaced)
    def _replace_date_only(m):
        s = m.group(0)
        try:
            dt = datetime.strptime(s, "%Y-%m-%d")
            day_word = _ORDINAL[dt.day] if 1 <= dt.day <= 31 else str(dt.day)
            return f"{dt.strftime('%B')} {day_word}, {_year_to_speech(dt.year)}"
        except (ValueError, KeyError, IndexError):
            return s
    out = re.sub(r"\b\d{4}-\d{2}-\d{2}\b", _replace_date_only, out)
    # Standalone 24h time only (17:00, 09:30) so we don't replace "5:30" in "5:30 PM"
    def _replace_time(m):
        try:
            h, mi = int(m.group(1)), int(m.group(2))
            if 0 <= h <= 23 and 0 <= mi <= 59 and (h >= 13 or h == 0):
                return _time_to_speech(h, mi)
        except (ValueError, IndexError):
            pass
        return m.group(0)
    out = re.sub(r"\b(\d{1,2})\s*:\s*(\d{2})(?:\s*:\s*\d{2})?\b", _replace_time, out)
    return out


def run_adk(user_message: str) -> str:
    # New session per request (like app's first message in a new chat) so model sees same context.
    session_id = f"voice_{int(time.time() * 1000)}"
    create_url = f"{ADK_URL}/apps/{ADK_APP_NAME}/users/{USER_ID}/sessions"
    body = {
        "appName": ADK_APP_NAME,
        "userId": USER_ID,
        "sessionId": session_id,
        "newMessage": {"role": "user", "parts": [{"text": user_message}]},
    }
    with httpx.Client(timeout=120) as client:
        client.post(create_url, json={"session_id": session_id}, headers={"Content-Type": "application/json"})
        resp = client.post(f"{ADK_URL}/run", json=body, headers={"Content-Type": "application/json"})
    if resp.status_code != 200:
        return f"Error: ADK returned {resp.status_code}."
    body = resp.json()
    # ADK returns list[Event]; some clients might wrap as {"events": [...]}
    events = body if isinstance(body, list) else (body.get("events") if isinstance(body, dict) else None)
    if not isinstance(events, list):
        return "Error: ADK response was not a list of events."
    if not events:
        print("[voice] ADK returned 0 events", flush=True)
        _debug_log("voice:run_adk", "ADK returned empty events", {"body_type": type(body).__name__, "body_keys": list(body.keys()) if isinstance(body, dict) else None}, "empty_events")
        return "I didn't get a response from the agent. Try again in a moment."
    # Debug: log event structure so we can fix parsing if ADK shape differs
    if events:
        last = events[-1]
        content = last.get("content") if isinstance(last, dict) else None
        parts = content.get("parts") if isinstance(content, dict) else None
        part_keys = list(parts[0].keys()) if parts and isinstance(parts[0], dict) else []
        _debug_log(
            "voice:run_adk",
            "ADK events",
            {"n_events": len(events), "last_has_content": content is not None, "last_parts_len": len(parts) if parts else 0, "first_part_keys": part_keys},
            "events_shape",
        )
        print(f"[voice] ADK returned {len(events)} events; last event parts[0] keys: {part_keys}", flush=True)
    raw = get_final_text_from_events(events)
    fallback = build_fallback_reply(events)
    text = (raw or fallback).strip()
    return sanitize_reply(text) or fallback


def twiml_say(s: str) -> str:
    escaped = xml.sax.saxutils.escape(s or "")
    return f'<?xml version="1.0" encoding="UTF-8"?><Response><Say>{escaped}</Say><Hangup/></Response>'


def twiml_say_then_gather(prompt: str, action_url: str) -> str:
    escaped_prompt = xml.sax.saxutils.escape(prompt or "")
    escaped_action = xml.sax.saxutils.escape(action_url)
    return (
        '<?xml version="1.0" encoding="UTF-8"?><Response>'
        f"<Say>{escaped_prompt}</Say>"
        f'<Gather input="speech" action="{escaped_action}" speechTimeout="auto" speechModel="default"/>'
        "</Response>"
    )


@app.api_route("/voice/incoming", methods=["GET", "HEAD", "POST"])
async def voice_incoming(request: Request):
    """Twilio calls this when someone dials the number. Return TwiML to answer and gather speech."""
    try:
        # #region agent log
        _debug_log("voice_server:incoming", "POST /voice/incoming received", {"has_base": bool(VOICE_WEBHOOK_BASE)}, "H1")
        # #endregion
        print("[voice] POST /voice/incoming", flush=True)
        if not VOICE_WEBHOOK_BASE:
            # #region agent log
            _debug_log("voice_server:incoming", "returning error TwiML missing VOICE_WEBHOOK_BASE", {}, "H2")
            # #endregion
            return Response(
                content=twiml_say("Voice server is misconfigured. Missing V O I C E W E B H O O K B A S E."),
                media_type="application/xml",
            )
        action = f"{VOICE_WEBHOOK_BASE}/voice/gather"
        prompt = "Hello. Say your request after the beep."
        body = twiml_say_then_gather(prompt, action)
        # #region agent log
        _debug_log("voice_server:incoming", "returning TwiML", {"body_len": len(body), "content_type": "application/xml"}, "H2")
        # #endregion
        return Response(
            content=body,
            media_type="application/xml",
        )
    except Exception as e:
        # #region agent log
        _debug_log("voice_server:incoming", "exception", {"error": str(e)}, "H2")
        # #endregion
        raise


@app.post("/voice/gather")
async def voice_gather(
    request: Request,
    Caller: str = Form(None),
    SpeechResult: str = Form(None),
):
    """Twilio POSTs here with the caller and speech result. Check allowlist, call ADK, return Say."""
    print("[voice] POST /voice/gather", "Caller=", Caller, "SpeechResult=", (SpeechResult or "")[:80], flush=True)
    caller = Caller or ""
    if not is_allowed_caller(caller):
        return Response(
            content=twiml_say("You are not authorized to use this line. Goodbye."),
            media_type="application/xml",
        )
    raw_transcript = (SpeechResult or "").strip()
    if not raw_transcript:
        return Response(
            content=twiml_say("I didn't catch that. Please call back and try again. Goodbye."),
            media_type="application/xml",
        )
    # Send the same format as the app: just the user's words, no prefix/suffix.
    # That way the model behaves like in chat (calls tools when it would there).
    transcript = raw_transcript
    # End call on goodbye so the user can hang up naturally
    if transcript.strip().lower() in ("goodbye", "good bye", "bye", "hang up", "end call"):
        return Response(
            content=twiml_say("Goodbye."),
            media_type="application/xml",
        )
    try:
        reply = run_adk(transcript)
    except Exception as e:
        reply = f"Sorry, an error occurred: {e}"
    reply = speech_friendly_dates(reply)
    # Keep call alive: say reply then gather again for another turn
    action = f"{VOICE_WEBHOOK_BASE}/voice/gather"
    return Response(
        content=twiml_say_then_gather(reply, action),
        media_type="application/xml",
    )


if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("VOICE_SERVER_PORT", "8001"))
    uvicorn.run(app, host="0.0.0.0", port=port)
