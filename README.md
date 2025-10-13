# Edumate

Edumate is a Flutter mobile app that connects to a locally running RAG (Retrieval Augmented Generation) backend with ngrok or local Wi-Fi IP, with offline functionality using cached Q&A pairs. Your AI Learning Assistant for educational content and knowledge retrieval.

## Features

- **Online Mode**: Connects to FastAPI backend running phi-2 + NLLB translation + hybrid retrieval model
- **Offline Mode**: Uses cached Q&A pairs from local Hive database
- **Smart Connectivity**: Automatically detects online/offline status
- **Modern UI**: Chat-like interface with connection status indicators
- **Configurable**: Switch between ngrok and local network connections
- **Persistent Storage**: Local database for offline Q&A pairs

## Setup Instructions

### 1. Backend Setup

Ensure your FastAPI backend is running with the following endpoints:
- `POST /ask` - Accepts questions and returns RAG responses
- `GET /health` - Health check endpoint
- `GET /info` - Backend information endpoint

### 2. Flutter App Setup

1. **Install dependencies**:
   ```bash
   flutter pub get
   ```

2. **Generate code** (for Hive and JSON serialization):
   ```bash
   flutter packages pub run build_runner build
   ```

3. **Configure API endpoints**:
   - Open the app and go to Settings (gear icon)
   - Set your ngrok URL or local IP address
   - Choose between ngrok or local network connection

### 3. Configuration

#### For Ngrok:
1. Start your FastAPI backend
2. Run ngrok: `ngrok http 8000`
3. Copy the ngrok URL (e.g., `https://abc123.ngrok.io`)
4. Set this URL in the app settings

#### For Local Network:
1. Find your computer's IP address
2. Ensure your phone and computer are on the same Wi-Fi network
3. Set the local URL in format: `http://YOUR_IP:8000`
4. Make sure your FastAPI backend is accessible on this IP

### 4. Running the App

```bash
flutter run
```

## How It Works

### Online Mode
1. User asks a question
2. App checks if online and can reach backend
3. Sends question to FastAPI backend
4. Receives answer from RAG system
5. Saves Q&A pair to local database
6. Displays answer to user

### Offline Mode
1. User asks a question
2. App detects no internet connection
3. Searches local database for exact match
4. If found, displays cached answer
5. If not found, shows similar questions or offline message

### Smart Features
- **Connection Detection**: Automatically detects online/offline status
- **Similar Questions**: Shows related questions when exact match not found
- **Caching**: All online Q&A pairs are cached for offline use
- **Error Handling**: Graceful fallback to offline mode when online fails

## Project Structure

```
lib/
├── config/
│   └── api_config.dart          # API configuration
├── models/
│   ├── qa_pair.dart             # Q&A pair data model
│   └── api_response.dart        # API response models
├── providers/
│   └── qna_provider.dart        # State management
├── screens/
│   ├── home_screen.dart         # Main chat interface
│   └── settings_screen.dart     # Settings configuration
├── services/
│   ├── api_service.dart         # FastAPI communication
│   ├── connectivity_service.dart # Network status detection
│   ├── database_service.dart    # Local Hive database
│   └── qna_service.dart         # Q&A business logic
├── widgets/
│   ├── connection_status.dart   # Connection indicator
│   ├── loading_indicator.dart   # Loading spinner
│   └── qa_message.dart          # Q&A message widget
└── main.dart                    # App entry point
```

## Dependencies

- `http`: HTTP requests to FastAPI backend
- `hive`: Local database for offline storage
- `connectivity_plus`: Network connectivity detection
- `provider`: State management
- `flutter_spinkit`: Loading animations
- `json_annotation`: JSON serialization

## Troubleshooting

### Connection Issues
1. **Ngrok not working**: Check if ngrok URL is correct and backend is running
2. **Local network not working**: Ensure both devices are on same Wi-Fi
3. **Backend not reachable**: Check firewall settings and port accessibility

### Offline Mode Issues
1. **No cached answers**: Ask some questions online first to build cache
2. **Database errors**: Clear app data and restart

### Build Issues
1. **Code generation errors**: Run `flutter packages pub run build_runner clean` then `flutter packages pub run build_runner build`
2. **Dependency conflicts**: Run `flutter pub deps` to check for conflicts

## API Endpoints Expected

Your FastAPI backend should implement:

```python
@app.post("/generate")
async def generate_answer(request: dict):
    # Expected request: {"question": "string", "language": "string"}
    # Expected response: {"answer": "string", "sources": ["string"], "sourceUrl": "string", "confidence": float}
    pass

@app.get("/health")
async def health_check():
    # Expected response: {"status": "healthy"}
    pass

@app.get("/info")
async def get_info():
    # Expected response: {"model": "string", "version": "string", "capabilities": ["string"]}
    pass
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License.