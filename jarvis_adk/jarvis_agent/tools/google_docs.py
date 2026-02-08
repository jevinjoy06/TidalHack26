"""Create Google Doc via API. Uses local bridge if Google auth is in Flutter."""
import os
import json
import httpx

BRIDGE_URL = os.getenv("JARVIS_BRIDGE_URL", "http://127.0.0.1:8765")


def create_google_doc(title: str, content: str) -> dict:
    """Create a Google Doc. Calls Flutter bridge (which has google_sign_in)."""
    if not title or not title.strip():
        title = "Untitled"
    else:
        title = title.strip()
    content = (content or "").replace("\\n", "\n")
    for s in ("```",):
        content = content.replace(s, "")
    content = content.strip()

    try:
        with httpx.Client(timeout=30) as client:
            resp = client.post(
                f"{BRIDGE_URL}/execute",
                json={"tool": "create_google_doc", "args": {"title": title, "content": content}},
            )
        if resp.status_code != 200:
            return {"result": f"Error: Bridge returned {resp.status_code}"}
        data = resp.json()
        result = data.get("result", str(data))
        return {"result": result}
    except httpx.ConnectError:
        return {"result": "Error: Flutter local bridge not reachable. Start JARVIS app and sign in with Google."}
    except Exception as e:
        return {"result": f"Error: {e}"}
