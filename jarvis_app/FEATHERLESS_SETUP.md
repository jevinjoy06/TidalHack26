# Featherless.ai Setup Guide

## ⚠️ Important
**You need to be on a paid subscription to use these models via the API.**

## Quick Setup

### Step 1: Get Your API Key
1. Go to [Featherless.ai](https://featherless.ai)
2. Sign up or log in
3. Navigate to your API keys section
4. Copy your API key (starts with `rc_` or similar)

### Step 2: Configure in the App
1. Open the JARVIS app
2. Go to the **Settings** tab (bottom right)
3. Tap on **API Key**
4. Paste your Featherless.ai API key (format: `rc_...`)
5. Tap **Save**

### Step 3: Set Base URL
1. In Settings, tap on **Base URL**
2. Make sure it's set to: `https://api.featherless.ai/v1`
   - **Important:** Must include `/v1` at the end
3. Tap **Save**

### Step 4: Select a Model
1. In Settings, tap on **Model**
2. Choose from the list of common models:
   - `google/gemma-3-27b-it` (recommended, shown in setup)
   - `google/gemma-2-27b-it`
   - `qwen2.5-14b-instruct`
   - `qwen2.5-7b-instruct`
   - `llama-3.1-8b-instruct`
   - `llama-3.1-70b-instruct`
   - `mistral-7b-instruct`
   - `deepseek-chat`
   - `deepseek-coder`
3. Or type a custom model name
4. Tap **Save**

### Step 5: Verify Connection
1. Check the **Connection** status at the top of Settings
2. It should show "Connected" with a green indicator
3. If disconnected, tap the refresh button

## Configuration Summary

Based on Featherless.ai setup instructions:

- **Base URL:** `https://api.featherless.ai/v1` (must include `/v1`)
- **API Key Format:** `rc_...` (starts with `rc_`)
- **Model Format:** Uses slashes (e.g., `google/gemma-3-27b-it`)

## Common Issues

### Error: "The model does not exist"
**Solution:** 
- Check the model name format - some use slashes (`google/gemma-3-27b-it`)
- Make sure you're using a model available on your Featherless.ai subscription
- Try the recommended model: `google/gemma-3-27b-it`

### Error: "API key not configured"
**Solution:** 
1. Make sure you've entered your API key in Settings
2. Check that the API key is correct (starts with `rc_`)
3. Verify your Featherless.ai account has an active paid subscription
4. Check that the API key has no extra spaces

### Error: "Failed to connect"
**Solution:**
1. Check your internet connection
2. Verify the Base URL is correct: `https://api.featherless.ai/v1` (with `/v1`)
3. Check if Featherless.ai service is available
4. Verify your subscription is active

### Error: "401 Unauthorized"
**Solution:**
- Your API key might be incorrect
- Your subscription might have expired
- Make sure you're on a paid plan

## Finding Available Models

To see all available models on your Featherless.ai account:
1. Check the Featherless.ai dashboard
2. Or use the API endpoint: `GET https://api.featherless.ai/v1/models`
3. The app will show common models in the Model selection dialog

## Model Recommendations

- **For general chat:** `google/gemma-3-27b-it` or `qwen2.5-14b-instruct`
- **For coding:** `deepseek-coder` or `google/gemma-3-27b-it`
- **For faster responses:** `qwen2.5-7b-instruct` or `mistral-7b-instruct`
- **For best quality:** `google/gemma-3-27b-it` or `llama-3.1-70b-instruct` (slower but more accurate)

## API Configuration Example

The app uses the OpenAI-compatible API format:

```dart
// Base URL
'https://api.featherless.ai/v1'

// API Key
'rc_7a701cc51e2aeaa61857851ac1e1a17bd' // Your actual key

// Model
'google/gemma-3-27b-it'
```

## Need Help?

- Check Featherless.ai documentation: https://featherless.ai/docs
- Verify your API key is valid and starts with `rc_`
- Make sure you have an active paid subscription
- Ensure your Base URL includes `/v1` at the end
