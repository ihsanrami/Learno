import os

# Must be set before any app module is imported.
# load_dotenv() inside config.py does NOT override existing env vars,
# so these values take priority over the .env file.
os.environ["DATABASE_URL"] = "sqlite://"
os.environ["JWT_SECRET_KEY"] = "test-secret-key-for-pytest-12345678901234"

import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool
from fastapi.testclient import TestClient

import app.auth.models  # registers all ORM models with Base metadata — must come first
from app.database.base import Base
from app.database.session import get_db
from app.main import app  # imported last so 'app' name = FastAPI instance, not the package

# Single in-memory SQLite shared across the session via StaticPool.
# StaticPool forces all connections to reuse the same underlying DBAPI connection,
# which is required for SQLite in-memory DBs to persist across sessions.
_TEST_ENGINE = create_engine(
    "sqlite://",
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
Base.metadata.create_all(bind=_TEST_ENGINE)
_TestSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=_TEST_ENGINE)


@pytest.fixture()
def db_session():
    session = _TestSessionLocal()
    yield session
    session.rollback()
    # Wipe all rows after each test so the next test starts with a clean DB.
    for table in reversed(Base.metadata.sorted_tables):
        session.execute(table.delete())
    session.commit()
    session.close()


@pytest.fixture()
def client(db_session):
    def _override_get_db():
        yield db_session

    app.dependency_overrides[get_db] = _override_get_db
    with TestClient(app) as c:
        yield c
    app.dependency_overrides.clear()
