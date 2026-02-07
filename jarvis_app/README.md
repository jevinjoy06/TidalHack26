# JARVIS Flutter App with Featherless.ai

A modern Flutter voice assistant app powered by Featherless.ai, styled with tidaltamu.com-inspired design.

## Features

- 💬 **AI Chat**: Natural language conversations powered by Featherless.ai
- 🎤 **Voice Input**: Speech-to-text integration (ready for implementation)
- 🎨 **Modern UI**: Tidaltamu.com-inspired design with gradients and smooth animations
- ✅ **Task Management**: Create and manage tasks locally
- 🌙 **Dark Mode**: Beautiful dark and light themes

## Setup

### Prerequisites

- Flutter SDK 3.2.0 or higher
- Featherless.ai API key

### Installation

1. **Install dependencies:**
   ```bash
   cd jarvis_app
   flutter pub get
   ```

2. **Configure Featherless.ai API:**
   - Get your API key from [featherless.ai](https://featherless.ai)
   - Set it in the app settings (Settings > Featherless.ai API > API Key)
   - Or set environment variable: `FEATHERLESS_API_KEY=your_key_here`

3. **Run the app:**
   ```bash
   flutter run
   ```

## Configuration

### API Settings

Configure your Featherless.ai settings in the app:
- **API Key**: Your Featherless.ai API key
- **Base URL**: Default is `https://api.featherless.ai`
- **Model**: Default is `qwen2.5:14b-instruct`

You can change these in Settings > Featherless.ai API.

### Environment Variables

You can also set these via environment variables:
- `FEATHERLESS_API_KEY`: Your API key
- `FEATHERLESS_BASE_URL`: API base URL (default: https://api.featherless.ai)
- `FEATHERLESS_MODEL`: Model name (default: qwen2.5:14b-instruct)

## Project Structure

```
jarvis_app/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── config/
│   │   └── secrets.dart          # API configuration
│   ├── models/
│   │   ├── message.dart          # Chat message model
│   │   ├── task.dart             # Task model
│   │   └── tool.dart             # Tool model
│   ├── providers/
│   │   ├── chat_provider.dart    # Chat state management
│   │   ├── settings_provider.dart # Settings state
│   │   └── tasks_provider.dart   # Tasks state
│   ├── screens/
│   │   ├── home_screen.dart      # Main navigation
│   │   ├── chat_screen.dart      # Chat interface
│   │   ├── tasks_screen.dart     # Task management
│   │   └── settings_screen.dart  # App settings
│   ├── services/
│   │   └── featherless_service.dart # Featherless.ai API client
│   ├── theme/
│   │   └── app_theme.dart        # Tidaltamu.com-inspired theme
│   └── widgets/
│       ├── message_bubble.dart   # Chat message UI
│       ├── voice_mode_widget.dart # Voice input UI
│       └── ...
```

## Architecture

The app uses:
- **Provider** for state management
- **Featherless.ai** for AI chat completions
- **Cupertino** design system for iOS-style UI
- **Local storage** for settings and tasks

## Features in Detail

### Chat Interface
- Modern chat bubbles with gradient styling
- Real-time message streaming
- Conversation history
- Error handling and retry logic

### Voice Mode
- Voice input ready (speech_to_text integration)
- Text-to-speech ready (flutter_tts integration)
- Visual feedback during voice interactions

### Task Management
- Create, complete, and delete tasks
- Filter by status (pending, completed, all)
- Local task storage

## Troubleshooting

### "API key not configured"
- Go to Settings > Featherless.ai API > API Key
- Enter your Featherless.ai API key

### Connection errors
- Check your internet connection
- Verify your API key is correct
- Ensure Featherless.ai service is available

### Build errors
- Run `flutter clean` and `flutter pub get`
- Ensure Flutter SDK is up to date

## License

MIT
