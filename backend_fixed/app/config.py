"""
Configuration for Learno Educational Backend
"""

import os
import secrets
from dotenv import load_dotenv

load_dotenv()


class Settings:
    """Application settings"""

    OPENAI_API_KEY: str = os.getenv("OPENAI_API_KEY", "")
    OPENAI_MODEL: str = os.getenv("OPENAI_MODEL", "gpt-4o")
    OPENAI_MAX_TOKENS: int = int(os.getenv("OPENAI_MAX_TOKENS", "500"))
    OPENAI_TEMPERATURE: float = float(os.getenv("OPENAI_TEMPERATURE", "0.7"))

    SESSION_TIMEOUT_SECONDS: int = int(os.getenv("SESSION_TIMEOUT_SECONDS", "1800"))
    SILENCE_THRESHOLD_SECONDS: int = int(os.getenv("SILENCE_THRESHOLD_SECONDS", "12"))

    API_VERSION: str = "v1"
    APP_TITLE: str = "Learno Educational Backend"
    DEBUG: bool = os.getenv("DEBUG", "true").lower() == "true"

    # Database — set DATABASE_URL env var to use PostgreSQL in production
    DATABASE_URL: str = os.getenv("DATABASE_URL", "sqlite:///./learno.db")

    # JWT — MUST be overridden via JWT_SECRET_KEY env var in production
    JWT_SECRET_KEY: str = os.getenv("JWT_SECRET_KEY", secrets.token_hex(32))
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 15
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7


settings = Settings()
