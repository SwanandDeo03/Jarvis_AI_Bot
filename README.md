# Jarvis AI Assistant

Jarvis is a full-stack, entirely localized, and private AI personal assistant. It is capable of receiving voice input from a mobile device (or desktop), transcribing it using local ML models, generating intelligent contextual responses via a local LLM, and speaking the responses back using Text-to-Speech.

---

## 🏗️ System Architecture

The project consists of a Python-based intelligent backend and a Flutter-based mobile frontend that communicate over the local network via a REST API.

### 1. Backend (Python/FastAPI)
The backend acts as the "Brain" and "Ears" of Jarvis. 
- **API (`api.py`)**: Runs on `uvicorn` and exposes the `/speech-to-text` and `/jarvis` endpoints. Allows the mobile app to send raw audio files.
- **STT (Speech-to-Text)**: Uses OpenAI's **Whisper** (`small` model) to transcribe recorded audio into text locally with high accuracy.
- **Brain (`brain/llm_brain.py`)**: Responsible for logic and conversation generation. It passes the user prompt and conversation history to **Ollama** running the **Mistral** local LLM via a subprocess call.
- **Memory (`memory/memory.py`)**: Saves conversation history into `memory.json` to keep track of previous context (up to 20 messages).
- **Core Engine (`main.py`)**: An alternative native Windows entry point to run Jarvis entirely on your PC using your desktop microphone and native TTS, bypassing the mobile app. It also includes hooks for system automation (opening Chrome, Spotify, etc.).

### 2. Frontend (Flutter)
The frontend (`jarvis/`) resides on your Android device (or iOS).
- **Audio Service**: Uses `speech_to_text` and raw microphone recording to capture your voice.
- **API Service (`lib/services/jarvis_api.dart`)**: Uploads the raw `.wav` voice file as a `multipart/form-data` request to the Python backend over Wi-Fi using the host PC's IP (`192.168.1.5`).
- **TTS**: Uses `flutter_tts` to immediately speak out the generated response from Jarvis right on your phone.
- **UI (`lib/screens/jarvis_home.dart`)**: A modern, sleek chat interface that displays your speech and Jarvis' responses, with a dynamic animated microphone button.

---

## 🚀 Prerequisites

To run this project, you need the following installed on your host PC:
1. **Python 3.10+** (For the backend server)
2. **FFmpeg** (Required by Whisper for audio transcription)
3. **Ollama** (Running the `mistral` model)
4. **Flutter SDK** (For the mobile app)

---

## 🛠️ Setup and Execution

### Activating the Backend

1. **Start Ollama** (Make sure the mistral model is pulled):
   ```bash
   ollama run mistral
   ```
2. **Activate the Virtual Environment**:
   ```powershell
   cd c:\dev\AI_bot
   .\venv\Scripts\activate
   ```
3. **Run the FastAPI Server**:
   ```bash
   uvicorn api:app --host 0.0.0.0 --port 8000 --reload
   ```
   *Note: Ensure your Windows Firewall allows inbound TCP connections on port 8000.*

### Running the Mobile App

1. Ensure your physical phone is connected to the **same Wi-Fi network** as your PC.
2. Launch the Flutter app via USB debugging or Wireless debugging:
   ```bash
   cd c:\dev\AI_bot\jarvis
   flutter run
   ```
   
### Alternative: Run Natively on PC
If you just want Jarvis to listen to your PC microphone without the mobile phone:
```bash
python main.py
```

---

## 🔒 Privacy & Data
Everything happens locally.
- **No Cloud APIs**: Voice transcription happens via local Whisper, avoiding Google/Apple limits. No data is sent to external API providers.
- **Local Brain**: Mistral runs directly on your GPU/CPU via Ollama. 
- **Offline Capable**: As long as the phone and PC are on the same local Router, no internet connection is required to talk to Jarvis.
