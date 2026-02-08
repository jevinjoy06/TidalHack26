"""Local tools that call the Flutter bridge at http://127.0.0.1:8765/execute."""
import os
import json
import time
import httpx

BRIDGE_URL = os.getenv("JARVIS_BRIDGE_URL", "http://127.0.0.1:8765")

# #region agent log
def _log(loc, msg, data, hid=None):
    p = {"location": loc, "message": msg, "data": data, "timestamp": int(time.time() * 1000)}
    if hid:
        p["hypothesisId"] = hid
    open("/Users/allenthomas/TidalHack26/.cursor/debug.log", "a").write(json.dumps(p) + "\n")
# #endregion


def _call_bridge(tool: str, args: dict) -> str:
    """POST to Flutter bridge and return result."""
    # #region agent log
    _log("local_bridge.py:_call_bridge", "POST to bridge", {"tool": tool, "args_keys": list(args.keys())}, "H3")
    # #endregion
    try:
        with httpx.Client(timeout=15) as client:
            resp = client.post(
                f"{BRIDGE_URL}/execute",
                json={"tool": tool, "args": args},
            )
        # #region agent log
        _log("local_bridge.py:bridge_resp", "bridge response", {"status": resp.status_code, "body_preview": resp.text[:200]}, "H3")
        # #endregion
        if resp.status_code != 200:
            return f"Error: Bridge returned {resp.status_code}"
        data = resp.json()
        return data.get("result", str(data))
    except httpx.ConnectError as e:
        # #region agent log
        _log("local_bridge.py:connect_error", "bridge unreachable", {"error": str(e)}, "H3")
        # #endregion
        return "Error: Flutter local bridge not reachable. Start the JARVIS app first."
    except Exception as e:
        # #region agent log
        _log("local_bridge.py:call_exc", "bridge exception", {"error": str(e)}, "H3")
        # #endregion
        return f"Error: {e}"


def open_url(url: str) -> dict:
    """Open a URL in the default browser."""
    if not url or not url.strip():
        return {"result": "Error: url is required"}
    result = _call_bridge("open_url", {"url": url})
    return {"result": result}


def send_email(to: str, subject: str = "", body: str = "") -> dict:
    """Open mail client with pre-filled email."""
    if not to or not to.strip():
        return {"result": "Error: 'to' is required"}
    result = _call_bridge("send_email", {"to": to, "subject": subject or "", "body": body or ""})
    return {"result": result}


def read_calendar(query: str = "events this week") -> dict:
    """Read calendar events. Query e.g. 'next Thursday', 'events this week'."""
    result = _call_bridge("read_calendar", {"query": query or "events this week"})
    return {"result": result}


def read_emails(max_results: int = 15, unread_only: bool = False) -> dict:
    """Fetch the user's latest Gmail emails; returns sender, subject, and snippet in priority order."""
    result = _call_bridge("read_emails", {"max_results": max_results, "unread_only": unread_only})
    return {"result": result}
