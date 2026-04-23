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
# Use in-memory SQLite for tests — must be set before app imports
os.environ.setdefault("DATABASE_URL", "sqlite:///:memory:")
os.environ.setdefault("JWT_SECRET_KEY", "test-secret-key-not-for-production")

# Allow `from app.xxx import ...` regardless of where pytest is invoked
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.database.base import Base
from app.database.session import get_db


@pytest.fixture(scope="session")
def db_engine():
    engine = create_engine(
        "sqlite:///:memory:",
        connect_args={"check_same_thread": False},
    )
    import app.auth.models  # noqa: F401
    Base.metadata.create_all(bind=engine)
    yield engine
    Base.metadata.drop_all(bind=engine)


@pytest.fixture(scope="function")
def db_session(db_engine):
    """Fresh DB session per test, rolled back after each test."""
    connection = db_engine.connect()
    transaction = connection.begin()
    TestingSession = sessionmaker(bind=connection)
    session = TestingSession()
    yield session
    session.close()
    transaction.rollback()
    connection.close()


@pytest.fixture(scope="function")
def client(db_session):
    """TestClient with DB override per test function and rate limiting disabled."""
    from app.main import app

    def override_get_db():
        try:
            yield db_session
        finally:
            pass

    app.dependency_overrides[get_db] = override_get_db
    # Disable slowapi rate limiting so auth tests don't hit per-minute limits
    app.state.limiter.enabled = False
    with TestClient(app) as c:
        yield c
    app.state.limiter.enabled = True
    app.dependency_overrides.clear()


@pytest.fixture(scope="session")
def session_client():
    """Legacy session-scoped client for existing tests that don't need per-test DB isolation."""
    from app.main import app
    with TestClient(app) as c:
        yield c
