from fastapi import FastAPI, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
import whisper
import tempfile
import os

# ---------------------------
# App initialization
# ---------------------------
app = FastAPI(
    title="Jarvis AI Backend",
    description="Speech-to-Text backend using Whisper",
    version="1.0.0",
)

# ---------------------------
# CORS (important for Flutter / Android)
# ---------------------------
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # for development only
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ---------------------------
# Load Whisper ONCE at startup
# ---------------------------
print("🔊 Loading Whisper model...")
model = whisper.load_model("tiny")
print("✅ Whisper model loaded")

# ---------------------------
# Health check (very useful)
# ---------------------------
@app.get("/")
def health_check():
    return {"status": "Jarvis backend is running"}

# ---------------------------
# Speech-to-text endpoint
# ---------------------------
@app.post("/speech-to-text", tags=["Speech"])
async def speech_to_text(file: UploadFile = File(...)):
    """
    Receives audio file from Flutter (wav),
    transcribes using Whisper,
    returns text + Jarvis reply
    """

    # Save to temp file
    with tempfile.NamedTemporaryFile(delete=False, suffix=".wav") as temp_audio:
        audio_bytes = await file.read()
        temp_audio.write(audio_bytes)
        temp_path = temp_audio.name

    try:
        # Transcribe
        result = model.transcribe(
            temp_path,
            language="en",
            fp16=False  # REQUIRED for CPU
        )

        text = result.get("text", "").strip()

        if not text:
            reply = "I didn't catch that. Please try again."
        else:
            reply = f"I heard you say: {text}"

        return {
            "user_text": text,
            "jarvis_reply": reply
        }

    except Exception as e:
        return {
            "error": str(e),
            "jarvis_reply": "An error occurred while processing audio."
        }

    finally:
        # Clean up temp file
        if os.path.exists(temp_path):
            os.remove(temp_path)