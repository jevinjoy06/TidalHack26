# How to Launch JARVIS App

## Quick Start

### Option 1: Run directly (Recommended)
```bash
cd jarvis_app
flutter run -d windows
```

### Option 2: Build and run
```bash
cd jarvis_app
flutter build windows
flutter run -d windows
```

## First Time Setup

1. **Navigate to the app directory:**
   ```bash
   cd jarvis_app
   ```

2. **Get dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the app:**
   ```bash
   flutter run -d windows
   ```

## Configure API Key

1. Once the app launches, go to the **Settings** tab
2. Tap on **API Key**
3. Enter your Featherless.ai API key
4. The app will automatically test the connection

## Troubleshooting

If you get build errors:
```bash
cd jarvis_app
flutter clean
flutter pub get
flutter run -d windows
```

## Available Commands

- `flutter run -d windows` - Run on Windows
- `flutter run -d macos` - Run on macOS (if available)
- `flutter run -d linux` - Run on Linux (if available)
- `flutter build windows` - Build Windows executable
- `flutter clean` - Clean build cache
