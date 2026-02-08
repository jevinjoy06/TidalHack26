"""Notify task complete - no-op for ADK (Flutter can show notification via events)."""


def notify_task_complete(summary: str, details: str = "") -> dict:
    """Notify the user that a task is done."""
    return {"result": f"User notified: {summary}"}
