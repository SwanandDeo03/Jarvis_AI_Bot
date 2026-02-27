import json
from pathlib import Path
from datetime import datetime

MEMORY_FILE = Path("memory.json")

# -------------------------------
# LOAD MEMORY
# -------------------------------
def load_memory() -> dict:
    if MEMORY_FILE.exists():
        try:
            return json.loads(MEMORY_FILE.read_text())
        except json.JSONDecodeError:
            return _default_memory()
    return _default_memory()

# -------------------------------
# SAVE MEMORY
# -------------------------------
def save_memory(user_input: str, response: str):
    memory = load_memory()

    memory["last_command"] = user_input
    memory["last_response"] = response
    memory["last_updated"] = datetime.now().isoformat()

    # Ensure history exists
    if "history" not in memory:
        memory["history"] = []

    # Save conversation history (last 20)
    memory["history"].append({
        "user": user_input,
        "jarvis": response,
        "time": memory["last_updated"]
    })

    memory["history"] = memory["history"][-20:]

    MEMORY_FILE.write_text(json.dumps(memory, indent=2))

# -------------------------------
# DEFAULT MEMORY STRUCTURE
# -------------------------------
def _default_memory() -> dict:
    return {
        "user_name": "Swanand",
        "last_command": "",
        "last_response": "",
        "last_updated": "",
        "history": []
    }
    