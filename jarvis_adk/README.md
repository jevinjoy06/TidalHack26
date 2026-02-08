# JARVIS ADK Backend

Google ADK backend for JARVIS. Run the ADK API server before starting the Flutter app.

## Setup

1. Create virtual environment and install deps:
   ```bash
   cd jarvis_adk
   python3 -m venv .venv
   source .venv/bin/activate  # or .venv\Scripts\activate on Windows
   pip install -r requirements.txt
   ```

2. Create `.env` with required keys (or copy from `../jarvis_app/.env`):
   - **Featherless (recommended)**: Set `FEATHERLESS_BASE_URL` and `FEATHERLESS_API_KEY_1` (or `OPENAI_API_BASE` + `OPENAI_API_KEY`). ADK will use LiteLLM with Featherless.
   - **Gemini**: Set `GOOGLE_API_KEY` only (no OPENAI_API_BASE).
   - **Tools**: `SERPAPI_KEY`, `TAVILY_API_KEY`

3. Start the ADK server:
   ```bash
   adk api_server
   ```

   Server runs at http://localhost:8000. The Flutter app connects to it when "Use ADK" is enabled in Settings.

## Launch Flow

1. Start ADK: `cd jarvis_adk && adk api_server`
2. Start Flutter: `cd jarvis_app && flutter run -d macos`
3. Flutter starts the local bridge on port 8765 for local tools (open_url, send_email, read_calendar, create_google_doc).
