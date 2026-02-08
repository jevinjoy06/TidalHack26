"""Shopping search via SerpAPI."""
import json
import os
import time
import httpx

from .local_bridge import open_url

# #region agent log
def _log(loc, msg, data, hid=None):
    p = {"location": loc, "message": msg, "data": data, "timestamp": int(time.time() * 1000)}
    if hid:
        p["hypothesisId"] = hid
    open("/Users/allenthomas/TidalHack26/.cursor/debug.log", "a").write(json.dumps(p) + "\n")
# #endregion


def shopping_search(query: str) -> dict:
    """Search for products on Google Shopping. Returns titles, prices, ratings, and links."""
    # #region agent log
    _log("shopping.py:entry", "shopping_search called", {"query": query}, "H1")
    # #endregion
    api_key = os.getenv("SERPAPI_KEY", "")
    if not api_key:
        return {"result": "Error: SERPAPI_KEY not configured in .env"}

    if not query or not query.strip():
        return {"result": "Error: query is required"}

    try:
        url = "https://serpapi.com/search.json"
        params = {
            "engine": "google_shopping",
            "q": query.strip(),
            "api_key": api_key,
        }
        with httpx.Client(timeout=15) as client:
            resp = client.get(url, params=params)

        if resp.status_code != 200:
            return {"result": f"Error: SerpAPI returned {resp.status_code}"}

        data = resp.json()
        results = data.get("shopping_results", [])
        if not results:
            return {"result": f'No products found for "{query}"'}

        lines = []
        for i, r in enumerate(results[:10]):
            title = r.get("title", "")
            price = r.get("price") or r.get("extracted_price") or "N/A"
            if isinstance(price, (int, float)):
                price = str(price)
            link = r.get("product_link") or r.get("link", "")
            source = r.get("source", "")
            rating = r.get("rating")
            reviews = r.get("reviews") or r.get("reviews_count")
            rating_str = f" | {rating or '?'} stars, {reviews or '?'} reviews" if (rating or reviews) else ""
            lines.append(f"{i + 1}. {title} – {price} (from {source}){rating_str} – {link}")

        result = "\n".join(lines)

        # Auto-open the top result so the user can add to cart immediately
        first_link = results[0].get("product_link") or results[0].get("link", "")
        # #region agent log
        _log("shopping.py:first_link", "extracted first_link", {"first_link": first_link, "num_results": len(results)}, "H2")
        # #endregion
        if first_link:
            try:
                # #region agent log
                _log("shopping.py:before_open_url", "calling open_url", {"url": first_link[:80]}, "H3")
                # #endregion
                open_url(first_link)
                # #region agent log
                _log("shopping.py:after_open_url", "open_url returned", {}, "H3")
                # #endregion
            except Exception as e:
                # #region agent log
                _log("shopping.py:open_url_exc", "open_url raised", {"error": str(e)}, "H3")
                # #endregion
                pass  # Still return results if bridge is unreachable

        return {"result": result}
    except Exception as e:
        return {"result": f"Error: {e}"}
