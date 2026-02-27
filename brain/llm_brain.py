import subprocess
import json

SYSTEM_PROMPT = """
You are Jarvis, a calm, intelligent, polite personal AI assistant.
You help Swanand with daily tasks, learning, planning, and system control.
Be concise, helpful, and human-like.
"""

def think(user_input: str, memory_context: dict) -> str:
    prompt = {
        "system": SYSTEM_PROMPT,
        "memory": memory_context.get("history", [])[-5:],  # last 5 interactions
        "user": user_input
    }

    process = subprocess.run(
        ["ollama", "run", "mistral"],
        input=json.dumps(prompt),
        text=True,
        capture_output=True
    )

    return process.stdout.strip()
