"""Tavily search for research."""
import os
import json
import httpx


def tavily_search(query: str) -> dict:
    """Search the web for research, trends, factual information. NOT for product shopping."""
    api_key = os.getenv("TAVILY_API_KEY", "")
    if not api_key:
        return {"result": "Error: TAVILY_API_KEY not configured in .env"}

    if not query or not query.strip():
        return {"result": "Error: query is required"}

    try:
        url = "https://api.tavily.com/search"
        headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {api_key}",
        }
        payload = {
            "query": query.strip(),
            "max_results": 10,
            "include_answer": True,
        }
        with httpx.Client(timeout=30) as client:
            resp = client.post(url, headers=headers, json=payload)

        if resp.status_code != 200:
            return {"result": f"Error: Tavily API returned {resp.status_code}"}

        data = resp.json()
        answer = data.get("answer", "")
        results = data.get("results", [])

        lines = []
        if answer:
            lines.append(f"Summary: {answer}\n")
        for i, r in enumerate(results[:8]):
            title = r.get("title", "")
            url_val = r.get("url", "")
            content = str(r.get("content", ""))
            lines.append(f"{i + 1}. {title} ({url_val})")
            if content and len(content) < 300:
                lines.append(f"   {content}")

        return {"result": "\n".join(lines)}
    except Exception as e:
        return {"result": f"Error: {e}"}
