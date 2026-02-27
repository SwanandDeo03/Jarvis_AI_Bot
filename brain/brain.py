import time

def think(user_input: str, memory_context: dict) -> str:
    user_input = user_input.lower()

    if "how are you" in user_input:
        return "I am functioning perfectly and ready to assist you."

    if "your name" in user_input:
        return "I am Jarvis, your personal assistant."

    if "time" in user_input:
        return time.strftime("The time is %I:%M %p.")

    if "plan my day" in user_input:
        return "Start with one important task, then we will build momentum together."

    if "thank" in user_input:
        return "You're welcome. I am always here."

    # Intelligent fallback
    if memory_context.get("last_command"):
        return "Would you like to continue with your previous task?"

    return "Tell me what you would like me to do."
