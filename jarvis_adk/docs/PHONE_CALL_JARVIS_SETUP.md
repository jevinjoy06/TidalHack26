# Phone call to JARVIS – concrete plan and your setup

You have a Twilio number. This doc is the concrete plan for the voice webhook server and **everything you need to do on your end** (Twilio console, .env, ngrok, running order).

---

## 1. What the code will add

- **New file**: `jarvis_adk/voice_server.py` (or a small `jarvis_voice` package).
- **Endpoints**:
  - `POST /voice/incoming` – Twilio calls this when someone dials your number. Returns TwiML that answers and uses `<Gather input="speech" action="/voice/gather" ...>` so Twilio does speech-to-text and POSTs the result to `/voice/gather`.
  - `POST /voice/gather` – Receives Twilio’s form (including `Caller`, `SpeechResult`). Checks caller against allowlist (8329696324, 8326215771). If allowed: POSTs transcript to ADK `/run`, gets reply text, returns TwiML with `<Say>` (and optionally another `<Gather>` for a second turn or `<Hangup/>`).
- **Allowlist**: Same logic as imsg bridge – normalize caller to digits, allow only those two numbers; otherwise return “Not authorized” and hang up.
- **ADK**: Same `POST /run` payload as `imsg_bridge.py` (appName, userId, sessionId, newMessage). Reuse or copy the “get final text from events” logic.

---

## 2. What you need in `.env`

Put these in **`jarvis_adk/.env`** (same file as your ADK keys). The voice server will load them.

| Variable | Required | Where to get it | Example |
|----------|----------|-----------------|--------|
| `TWILIO_ACCOUNT_SID` | Yes | Twilio Console → Account → API keys & tokens | `ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx` |
| `TWILIO_AUTH_TOKEN` | Yes | Same place (click “View” to reveal) | `your_auth_token_string` |
| `VOICE_WEBHOOK_BASE` | Yes | Your public URL (ngrok or deployed app). No trailing slash. | `https://abc123.ngrok.io` |
| `JARVIS_ADK_URL` | Yes (if different) | Already used by imsg_bridge; voice server uses it to call ADK | `http://localhost:8000` |

You do **not** put the webhook path in Twilio’s console by hand in .env – you set the **full URL** in the Twilio Console (see below). `VOICE_WEBHOOK_BASE` is used by the **server** when it builds TwiML: e.g. `action="{{ VOICE_WEBHOOK_BASE }}/voice/gather"` so Twilio knows where to POST the speech result. So:

- **Twilio Console** = “When a call comes in, POST to this URL” → you paste the full URL (e.g. `https://abc123.ngrok.io/voice/incoming`).
- **.env** = `VOICE_WEBHOOK_BASE=https://abc123.ngrok.io` so the server can generate correct `action` URLs in TwiML.

Optional (recommended for production):

- **Request validation**: The server can validate that incoming requests are from Twilio using `TWILIO_AUTH_TOKEN` (Twilio signature validation). So yes – the auth token is needed in .env for that.

**Example `.env` addition:**

```bash
# Twilio (phone call to JARVIS)
TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TWILIO_AUTH_TOKEN=your_auth_token_here
VOICE_WEBHOOK_BASE=https://your-ngrok-subdomain.ngrok.io
# JARVIS_ADK_URL=http://localhost:8000   # optional if that's already set
```

---

## 3. What you need to do on your end

### Step 1: Get Twilio credentials

1. Go to [Twilio Console](https://console.twilio.com).
2. On the dashboard, copy **Account SID** and **Auth Token** (click “View” for the token).
3. Add them to `jarvis_adk/.env` as `TWILIO_ACCOUNT_SID` and `TWILIO_AUTH_TOKEN`.

### Step 2: Install ngrok (for local testing)

- Install from [ngrok.com](https://ngrok.com/download) or `brew install ngrok`.
- You’ll run the voice server locally and expose it with ngrok so Twilio can reach it.

### Step 3: Run services in this order

1. **ADK** (terminal 1):
   ```bash
   cd jarvis_adk && source .venv/bin/activate && adk api_server
   ```
   (Runs on port 8000.)

2. **Voice server** (terminal 2):
   ```bash
   cd jarvis_adk && source .venv/bin/activate && python voice_server.py
   ```
   Runs on port **8001** by default. Override with `VOICE_SERVER_PORT` in `.env` if needed.

3. **ngrok** (terminal 3):
   ```bash
   ngrok http 8001
   ```
   Copy the **HTTPS** URL (e.g. `https://abc123.ngrok-free.app`).

**Calendar / email / Google Docs from a call:** Those features use the JARVIS app’s “local bridge” (port 8765). For “add to my calendar” (or read calendar, email, create docs) to work **while you’re on a call**, the **JARVIS Flutter app must be running on the same computer** as the ADK and voice server, with the bridge active and you **signed in to Google**. Start the JARVIS app on that machine and sign in before or during the call; then voice requests like “add an event for 5 p.m. titled Go grocery shopping” can succeed.

### Step 4: Set `VOICE_WEBHOOK_BASE` in .env

- Set `VOICE_WEBHOOK_BASE` to the ngrok HTTPS URL (no trailing slash), e.g. `VOICE_WEBHOOK_BASE=https://abc123.ngrok-free.app`.
- Restart the voice server so it picks up the new value.

### Step 5: Configure the Twilio number

1. Twilio Console → **Phone Numbers** → **Manage** → **Active Numbers**.
2. Click your number.
3. Under **Voice & Fax**:
   - **A call comes in**: choose **Webhook**.
   - URL: `https://your-ngrok-url.ngrok-free.app/voice/incoming` (must match your ngrok URL and the route the server exposes).
   - HTTP: **POST**.
4. Save.

### Step 6: Test

- From an **allowed** phone number (8329696324 or 8326215771), call your Twilio number.
- You should hear a prompt, speak your request, then hear JARVIS’s reply.

---

## 4. Summary checklist

- [ ] Add `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, `VOICE_WEBHOOK_BASE` (and optionally `JARVIS_ADK_URL`) to `jarvis_adk/.env`.
- [x] Implement `voice_server.py` (incoming + gather, allowlist, ADK call, TwiML).
- [ ] Run ADK, then voice server, then ngrok; set `VOICE_WEBHOOK_BASE` to the ngrok HTTPS URL.
- [ ] In Twilio, set the number’s Voice webhook to `https://<your-ngrok-host>/voice/incoming`, method POST.
- [ ] Call from an allowed number and test.

You do **not** put the webhook URL *path* in .env – Twilio gets the **full** webhook URL from the Console. The .env only needs the **base** URL so the server can build the full URL for the `<Gather action="...">` in TwiML.

---

## 5. Troubleshooting

**“JARVIS can’t add to my calendar” (works in app, not on a call)**  
Calendar (and email, Google Docs) go through the **local bridge** at `http://127.0.0.1:8765`. The ADK runs on the same machine as the voice server; when you call, it tries to reach that bridge. If the JARVIS app isn’t running on that machine, or the bridge isn’t up, the tool fails.

- **Fix:** On the computer where ADK and the voice server run, **start the JARVIS Flutter app** and **sign in with Google**. Use the app once (e.g. send a message) so the bridge starts. Then call again; “add an event for 5 p.m. titled …” should work.
- If you run ADK/voice on a different machine (e.g. a server), the bridge there has no app/Google account; calendar/email/docs from a call won’t work unless you run the app on that same host or add a different bridge.

