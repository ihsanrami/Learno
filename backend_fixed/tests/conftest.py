"""
Shared fixtures for Learno backend tests.

IMPORTANT: OPENAI_API_KEY must be set before any app import because
app.config reads it at module-load time via os.getenv().
"""

import os
import sys

# Inject a fake key so LearnoAIClient doesn't raise on import
os.environ.setdefault("OPENAI_API_KEY", "sk-test-not-real")
os.environ.setdefault("OPENAI_MODEL", "gpt-4o")

# Allow `from app.xxx import ...` regardless of where pytest is invoked
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import pytest
from fastapi.testclient import TestClient


@pytest.fixture(scope="session")
def client():
    """FastAPI TestClient — created once per test session."""
    from app.main import app
    with TestClient(app) as c:
        yield c
