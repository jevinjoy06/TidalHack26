"""Shopping search via SerpAPI."""
import os
import httpx


def shopping_search(query: str) -> dict:
    """Search for products on Google Shopping. Returns titles, prices, ratings, and links."""
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

        return {"result": "\n".join(lines)}
    except Exception as e:
        return {"result": f"Error: {e}"}
