#!/usr/bin/env python3
"""
imsg bridge: only accept texts from 8329696324 that start with "JARVIS".
Watches imsg, filters by sender and prefix, POSTs to ADK /run, replies via imsg send.
Requires: imsg CLI, ADK server at ADK_URL, Flutter bridge for tools.
"""

import json
import os
import pty
import time
import re
import shutil
import subprocess
import sys

import httpx
from dotenv import load_dotenv

load_dotenv(os.path.join(os.path.dirname(__file__), ".env"))

DEBUG_LOG_PATH = "/Users/allenthomas/TidalHack26/.cursor/debug.log"


def _debug_log(location: str, message: str, data: dict | None = None, hypothesis_id: str | None = None) -> None:
    try:
        payload = {
            "location": location,
            "message": message,
            "data": data or {},
            "timestamp": __import__("time").time() * 1000,
        }
        if hypothesis_id:
            payload["hypothesisId"] = hypothesis_id
        with open(DEBUG_LOG_PATH, "a") as f:
            f.write(json.dumps(payload) + "\n")
    except Exception:
        pass

# Allowed senders: phone digits (any of these) and/or Apple ID email from env
ALLOWED_SENDER_DIGITS = ("8329696324", "8326215771")
ALLOWED_SENDER_EMAIL = os.getenv("JARVIS_IMSG_ALLOWED_EMAIL", "").strip().lower()
TRIGGER_PREFIX = "JARVIS"
ADK_URL = os.getenv("JARVIS_ADK_URL", "http://localhost:8000")
ADK_APP_NAME = "jarvis_agent"
USER_ID = "imsg"
SESSION_ID = "8329696324"
IMSG_PARTICIPANTS = "+18329696324"


def resolve_imsg_bin() -> str | None:
    """Return path to imsg executable, or None if not found. Prefer IMSG_BIN env."""
    path = os.getenv("IMSG_BIN")
    if path and os.path.isfile(path) and os.access(path, os.X_OK):
        # #region agent log
        _debug_log("imsg_bridge.py:resolve_imsg_bin", "imsg from IMSG_BIN", {"path": path}, "H1")
        # #endregion
        return path
    which = shutil.which("imsg")
    if which:
        # #region agent log
        _debug_log("imsg_bridge.py:resolve_imsg_bin", "imsg from PATH", {"path": which}, "H1")
        # #endregion
        return which
    # Fallback: sibling imsg clone (e.g. TidalHack26/imsg when run from TidalHack26/jarvis_adk)
    script_dir = os.path.dirname(os.path.abspath(__file__))
    sibling = os.path.abspath(os.path.join(script_dir, "..", "imsg", ".build", "release", "imsg"))
    if os.path.isfile(sibling) and os.access(sibling, os.X_OK):
        # #region agent log
        _debug_log("imsg_bridge.py:resolve_imsg_bin", "imsg from sibling repo", {"path": sibling}, "H1")
        # #endregion
        return sibling
    # #region agent log
    _debug_log("imsg_bridge.py:resolve_imsg_bin", "imsg not found", {"IMSG_BIN": path}, "H1")
    # #endregion
    return None


def _get(obj, *keys):
    """Get first key that exists in dict (for camelCase/snake_case)."""
    if not isinstance(obj, dict):
        return None
    for k in keys:
        if k in obj:
            return obj[k]
    return None


def normalize_sender_digits(sender: str) -> str:
    """Return digits only from sender string."""
    return re.sub(r"\D", "", sender) if sender else ""


def is_allowed_sender(sender: str) -> bool:
    """True if sender is one of the allowed numbers or allowed email (e.g. Apple ID)."""
    if not sender:
        return False
    normalized = sender.strip().lower()
    if ALLOWED_SENDER_EMAIL and normalized == ALLOWED_SENDER_EMAIL:
        return True
    digits = normalize_sender_digits(sender)
    return any(digits == num or digits.endswith(num) for num in ALLOWED_SENDER_DIGITS)


def format_sender_for_imsg(sender: str) -> str:
    """Format sender for imsg send --to (E.164 for phone, or email as-is)."""
    if not sender:
        return sender
    s = sender.strip()
    if "@" in s:
        return s
    digits = normalize_sender_digits(sender)
    if len(digits) == 10:
        return f"+1{digits}"
    if len(digits) == 11 and digits.startswith("1"):
        return f"+{digits}"
    return f"+{digits}" if digits else s


def extract_user_message(text: str) -> str | None:
    """If text starts with JARVIS (case-insensitive), return rest trimmed; else None."""
    if not text or not isinstance(text, str):
        return None
    t = text.strip()
    if not t.upper().startswith(TRIGGER_PREFIX):
        return None
    # Strip prefix (case-insensitive) and any following space
    rest = t[len(TRIGGER_PREFIX) :].lstrip()
    return rest


RESET_PHRASES = ("hi", "hello", "reset", "new chat", "start over", "clear")


def should_reset_context(user_message: str) -> bool:
    """True if the message is a reset phrase that should start a fresh conversation."""
    return user_message.strip().lower() in RESET_PHRASES


def get_final_text_from_events(events: list[dict]) -> str | None:
    """Extract last meaningful assistant text from ADK events (skip tool_call-only)."""
    last_text: str | None = None
    for e in events:
        content = _get(e, "content")
        parts = _get(content, "parts") if isinstance(content, dict) else None
        if not parts:
            continue
        for p in parts:
            if not isinstance(p, dict):
                continue
            text = _get(p, "text")
            if text is None:
                continue
            t = (text or "").strip()
            if not t:
                continue
            lower = t.lower()
            if "tool_call" in lower:
                stripped = re.sub(r"<{1,2}/?tool_call[^>]*>", "", t, flags=re.IGNORECASE).strip()
                if not stripped:
                    continue
            last_text = text
    return last_text


def get_tools_called_from_events(events: list[dict]) -> set[str]:
    """Set of tool names called in events."""
    names: set[str] = set()
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
    """Contextual fallback when agent returns no text (e.g. only tool calls)."""
    tools = get_tools_called_from_events(events)
    if "create_google_doc" in tools:
        return "I ran your request. If you asked for a document, check your Google Docs—it may have been created."
    if "open_url" in tools:
        return "I ran your request. A link may have been opened in your browser."
    if tools:
        return "I ran your request but didn't get a clear summary. Check whether the action completed."
    return "I was unable to generate a response. Try rephrasing your request."


def sanitize_reply(text: str) -> str:
    """Strip literal tool_call garbage from reply."""
    t = text.strip()
    if not t:
        return text
    if "tool_call" not in t.lower():
        return text
    stripped = re.sub(r"<{1,2}/?tool_call[^>]*>", "", t, flags=re.IGNORECASE).strip()
    return stripped if stripped else text


def ensure_session_client(client: httpx.Client, session_id: str) -> None:
    """Create ADK session if it doesn't exist. /run returns 404 when session is missing."""
    create_url = f"{ADK_URL}/apps/{ADK_APP_NAME}/users/{USER_ID}/sessions"
    resp = client.post(create_url, json={"session_id": session_id}, headers={"Content-Type": "application/json"})
    if resp.status_code not in (200, 201, 409):
        pass  # still try /run; session might already exist


def run_adk(user_message: str, session_id: str) -> str:
    """POST to ADK /run and return reply text."""
    body = {
        "appName": ADK_APP_NAME,
        "userId": USER_ID,
        "sessionId": session_id,
        "newMessage": {
            "role": "user",
            "parts": [{"text": user_message}],
        },
    }
    with httpx.Client(timeout=120) as client:
        ensure_session_client(client, session_id)
        resp = client.post(
            f"{ADK_URL}/run",
            json=body,
            headers={"Content-Type": "application/json"},
        )
    if resp.status_code != 200:
        return f"Error: ADK returned {resp.status_code}: {resp.text[:200]}"
    events = resp.json()
    if not isinstance(events, list):
        return "Error: ADK response was not a list of events"
    raw = get_final_text_from_events(events)
    fallback = build_fallback_reply(events)
    text = (raw or fallback).strip()
    return sanitize_reply(text) or fallback


def ensure_session():
    """Create ADK session if needed (optional; /run may create it)."""
    try:
        with httpx.Client(timeout=10) as client:
            client.post(
                f"{ADK_URL}/apps/{ADK_APP_NAME}/users/{USER_ID}/sessions/{SESSION_ID}",
                json={},
                headers={"Content-Type": "application/json"},
            )
    except Exception:
        pass


def imsg_send(to: str, text: str, imsg_bin: str) -> None:
    """Send message via imsg send --to <to> --text <text>."""
    subprocess.run(
        [imsg_bin, "send", "--to", to, "--text", text],
        check=False,
        capture_output=True,
    )


def main() -> None:
    imsg_bin = resolve_imsg_bin()
    if not imsg_bin:
        print(
            "imsg not found. Install from https://github.com/steipete/imsg or set IMSG_BIN to its path.",
            file=sys.stderr,
        )
        sys.exit(1)

    # Current session for this conversation. Fresh session per bridge run; reset phrases start a new one.
    current_session_id = f"imsg_{int(time.time() * 1000)}"

    # imsg watch --json; use a pty so imsg sees a TTY and may stay running (some tools exit when stdout is a pipe)
    cmd = [imsg_bin, "watch", "--json"]
    master_fd, slave_fd = pty.openpty()
    try:
        proc = subprocess.Popen(
            cmd,
            stdout=slave_fd,
            stderr=slave_fd,
            stdin=subprocess.DEVNULL,
            text=False,
        )
    except Exception:
        os.close(slave_fd)
        os.close(master_fd)
        raise
    os.close(slave_fd)
    try:
        stream = open(master_fd, "r", encoding="utf-8", errors="replace")
    except Exception:
        os.close(master_fd)
        proc.wait()
        raise

    print("imsg bridge running (allowed senders: %s, prefix JARVIS). Ctrl+C to stop." % ", ".join(ALLOWED_SENDER_DIGITS), file=sys.stderr)
    try:
        for line in stream:
            line = line.strip()
            if not line:
                continue
            try:
                payload = json.loads(line)
            except json.JSONDecodeError:
                continue
            # #region agent log
            _debug_log(
                "imsg_bridge:raw",
                "json line from imsg",
                {"keys": list(payload.keys()) if isinstance(payload, dict) else [], "has_message": isinstance(payload, dict) and ("message" in payload or "Message" in payload)},
                "H0",
            )
            # #endregion
            # imsg can emit flat payloads (sender, text, is_from_me at top level) or nested under "message"
            msg = _get(payload, "message", "Message")
            if not msg or not isinstance(msg, dict):
                msg = payload if isinstance(payload, dict) and ("sender" in payload or "text" in payload) else None
            if not msg or not isinstance(msg, dict):
                continue
            is_from_me = _get(msg, "isFromMe", "is_from_me", "IsFromMe") is True
            sender = _get(msg, "sender", "Sender") or ""
            text = _get(msg, "text", "Text") or ""
            # #region agent log
            _debug_log(
                "imsg_bridge:line",
                "message received",
                {
                    "sender_raw": sender[:20] if sender else "",
                    "sender_digits": normalize_sender_digits(sender),
                    "is_from_me": is_from_me,
                    "text_preview": (text[:30] + "…") if len(text) > 30 else text,
                    "starts_jarvis": text.strip().upper().startswith(TRIGGER_PREFIX),
                },
                "H1",
            )
            # #endregion
            if is_from_me:
                continue
            if not is_allowed_sender(sender):
                continue
            user_message = extract_user_message(text)
            if user_message is None:
                continue
            if not user_message.strip():
                imsg_send(format_sender_for_imsg(sender), "Say something after JARVIS.", imsg_bin)
                continue
            if should_reset_context(user_message):
                current_session_id = f"imsg_{int(time.time() * 1000)}"
            # #region agent log
            _debug_log("imsg_bridge:trigger", "calling ADK and sending reply", {"user_message_len": len(user_message), "session_id": current_session_id}, "H2")
            # #endregion
            try:
                reply = run_adk(user_message, current_session_id)
            except Exception as e:
                reply = f"Error: {e}"
            imsg_send(format_sender_for_imsg(sender), reply, imsg_bin)
    finally:
        stream.close()
        try:
            proc.wait()
        except Exception:
            pass

    # If we get here, imsg watch exited (EOF on stdout)
    if proc.returncode is not None and proc.returncode != 0:
        print(f"imsg watch exited with code {proc.returncode}. Check errors above.", file=sys.stderr)
    else:
        print("imsg watch ended.", file=sys.stderr)


if __name__ == "__main__":
    main()
