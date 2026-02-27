import sounddevice as sd
import numpy as np
from scipy.io.wavfile import write
import whisper
import time
import subprocess
import re

from TTS.api import TTS
from brain.llm_brain import think
from memory.memory import load_memory, save_memory

# --------------------------------------------------
# AUDIO CONFIG (WINDOWS SAFE)
# --------------------------------------------------
SAMPLE_RATE = 16000
sd.default.samplerate = SAMPLE_RATE
sd.default.channels = 1

# --------------------------------------------------
# LOAD MODELS
# --------------------------------------------------
print("Loading Whisper model...")
stt_model = whisper.load_model("small")

print("Loading TTS model...")
tts = TTS(
    model_name="tts_models/en/vctk/vits",
    progress_bar=False,
    gpu=False
)

# --------------------------------------------------
# TTS SETTINGS
# --------------------------------------------------
SPEAKER_ID = "p225"

# --------------------------------------------------
# SPEAK (WINDOWS NATIVE)
# --------------------------------------------------
def speak(text: str):
    print(f"Jarvis: {text}")

    audio = tts.tts(text=text, speaker=SPEAKER_ID)
    sd.play(audio, samplerate=tts.synthesizer.output_sample_rate)
    sd.wait()

def speak_short(text: str):
    sentences = re.split(r'(?<=[.!?])\s+', text)
    for s in sentences[:2]:
        if s.strip():
            speak(s)

# --------------------------------------------------
# SYSTEM CONTROL (WINDOWS APPS)
# --------------------------------------------------
def execute_system_command(command: str) -> bool:
    command = command.lower()

    app_map = {
        "chrome": "chrome",
        "google chrome": "chrome",
        "edge": "msedge",
        "browser": "chrome",
        "vs code": "code",
        "vscode": "code",
        "visual studio code": "code",
        "notepad": "notepad",
        "calculator": "calc",
        "file explorer": "explorer",
        "explorer": "explorer",
        "spotify": "spotify",
        "whatsapp": "whatsapp"
    }

    for key, target in app_map.items():
        if key in command:
            speak(f"Opening {key}")
            subprocess.Popen(f'start "" {target}', shell=True)
            return True

    return False

# --------------------------------------------------
# SMART LISTEN (HIGH ACCURACY)
# --------------------------------------------------
def listen() -> str:
    start_threshold = 0.015
    silence_threshold = 0.01
    silence_duration = 0.6
    max_duration = 10

    print("🎙️ Waiting for you to speak...")

    audio_buffer = []
    pre_buffer = []
    recording = False
    silent_time = 0
    start_time = time.time()
    stop_flag = False

    def callback(indata, frames, time_info, status):
        nonlocal recording, silent_time, stop_flag

        volume = np.linalg.norm(indata)

        pre_buffer.append(indata.copy())
        if len(pre_buffer) > int(0.3 * SAMPLE_RATE / frames):
            pre_buffer.pop(0)

        if not recording and volume > start_threshold:
            recording = True
            audio_buffer.extend(pre_buffer)
            print("🟢 Recording started")

        if not recording:
            return

        audio_buffer.append(indata.copy())

        if volume < silence_threshold:
            silent_time += frames / SAMPLE_RATE
        else:
            silent_time = 0

        if silent_time >= silence_duration:
            stop_flag = True

        if time.time() - start_time > max_duration:
            stop_flag = True

    with sd.InputStream(callback=callback, samplerate=SAMPLE_RATE):
        while not stop_flag:
            time.sleep(0.05)

    if not audio_buffer:
        return ""

    audio = np.concatenate(audio_buffer, axis=0)
    audio = audio / (np.max(np.abs(audio)) + 1e-8)

    write("voice.wav", SAMPLE_RATE, audio)

    result = stt_model.transcribe(
        "voice.wav",
        language="en",
        fp16=False,
        temperature=0.0,
        condition_on_previous_text=False,
        no_speech_threshold=0.4,
        logprob_threshold=-1.0
    )

    text = result["text"].strip().lower()
    print(f"You: {text}")
    return text

# --------------------------------------------------
# INPUT FILTER
# --------------------------------------------------
def is_garbage(text: str) -> bool:
    return len(text) < 2 or text in ["um", "uh", "hmm", "noise"]

# --------------------------------------------------
# MAIN LOOP
# --------------------------------------------------
def main():
    speak("Jarvis online. I am listening.")

    memory_context = load_memory()

    while True:
        try:
            user_input = listen()

            if is_garbage(user_input):
                continue

            if user_input in ["hi", "hello", "hey jarvis", "hi jarvis"]:
                speak("Hello Swanand. How can I help you?")
                continue

            if user_input in ["bye", "bye jarvis", "exit", "quit", "stop jarvis"]:
                speak("Goodbye Swanand. Have a great day.")
                save_memory(user_input, "Session ended")
                break

            if user_input.startswith("open"):
                if execute_system_command(user_input):
                    save_memory(user_input, "Opened application")
                    memory_context["last_command"] = user_input
                    continue

            reply = think(user_input, memory_context)

            if reply:
                speak_short(reply)
                save_memory(user_input, reply)
                memory_context["last_command"] = user_input
                memory_context["last_response"] = reply

        except KeyboardInterrupt:
            print("\n🛑 Jarvis stopped by user.")
            break

        except Exception as e:
            print("⚠️ Error:", e)
            time.sleep(0.5)

# --------------------------------------------------
# ENTRY POINT
# --------------------------------------------------
if __name__ == "__main__":
    main()
