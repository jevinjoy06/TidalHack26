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

## iMessage bridge (optional)

To trigger JARVIS from iMessage, run the imsg bridge. It only accepts messages from **8329696324** whose text **starts with "JARVIS"**; the rest of the line is sent to the agent and the reply is sent back via iMessage.

1. Install [imsg](https://github.com/steipete/imsg) and grant Messages.app access (Full Disk Access, Automation).
2. With ADK and (for tools) the Flutter app running:  
   `python imsg_bridge.py`  
   (or `python -m imsg_bridge` from `jarvis_adk`.)
3. From the allowed number, send e.g. `JARVIS what's on my calendar?` to get a reply in the same chat.

## Phone call (Twilio, optional)

To talk to JARVIS by calling a phone number, set up a Twilio number and run the voice webhook server. See [docs/PHONE_CALL_JARVIS_SETUP.md](docs/PHONE_CALL_JARVIS_SETUP.md) for .env variables (Twilio SID, auth token, `VOICE_WEBHOOK_BASE`), ngrok, and Twilio Console steps. Then:

1. Start ADK: `adk api_server`
2. Start voice server: `python voice_server.py` (port 8001)
3. Expose with ngrok: `ngrok http 8001` and set `VOICE_WEBHOOK_BASE` in `.env` to the ngrok HTTPS URL
4. In Twilio, set your number’s Voice webhook to `https://<your-ngrok-host>/voice/incoming` (POST)
5. Call from an allowed number (8329696324 or 8326215771); speak your request and hear the reply.
