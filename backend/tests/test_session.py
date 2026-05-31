"""Tests for in-memory SessionService and curriculum helpers (no HTTP, no DB)."""

import time
import pytest

from app.services.session_service import Session, SessionService
from app.models.curriculum import get_topics, is_valid_topic
from app.utils.exceptions import SessionNotFoundError


# ── SessionService ────────────────────────────────────────────────────────────

def test_create_session_unique_ids():
    svc = SessionService()
    s1 = svc.create_session(grade=1, subject="math", lesson="counting")
    s2 = svc.create_session(grade=1, subject="math", lesson="counting")
    assert s1.session_id != s2.session_id
    assert len(s1.session_id) > 0


def test_get_session_not_found():
    svc = SessionService()
    with pytest.raises(SessionNotFoundError):
        svc.get_session("non-existent-session-id-xyz")


def test_session_update_activity():
    session = Session(grade=2, subject="science", lesson="light")
    before = session.last_activity
    time.sleep(0.05)
    session.update_activity()
    assert session.last_activity > before


# ── Curriculum ────────────────────────────────────────────────────────────────

def test_get_topics_valid():
    topics = get_topics(0, "math")  # Kindergarten Math
    assert len(topics) > 0
    assert all(t.subject.value == "math" for t in topics)


def test_get_topics_invalid():
    topics = get_topics(99, "magic")
    assert topics == []


def test_is_valid_topic():
    # Valid by topic_id slug
    assert is_valid_topic(0, "math", "numbers_to_3")
    # Valid by English display name
    assert is_valid_topic(0, "math", "Numbers to 3")
    # Invalid
    assert not is_valid_topic(0, "math", "nonexistent_topic_xyz_abc")
