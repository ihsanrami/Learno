import os
from dotenv import load_dotenv

load_dotenv()


class Settings:

    OPENAI_API_KEY: str = os.getenv("OPENAI_API_KEY", "")
    OPENAI_MODEL: str = os.getenv("OPENAI_MODEL", "gpt-4o")
    OPENAI_MAX_TOKENS: int = int(os.getenv("OPENAI_MAX_TOKENS", "500"))
    OPENAI_TEMPERATURE: float = float(os.getenv("OPENAI_TEMPERATURE", "0.7"))

    SESSION_TIMEOUT_SECONDS: int = int(os.getenv("SESSION_TIMEOUT_SECONDS", "1800"))
    SILENCE_THRESHOLD_SECONDS: int = int(os.getenv("SILENCE_THRESHOLD_SECONDS", "12"))

    API_VERSION: str = "v1"
    APP_TITLE: str = "Learno Educational Backend"
    DEBUG: bool = os.getenv("DEBUG", "true").lower() == "true"


settings = Settings()
