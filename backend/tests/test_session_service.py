"""
Tests for SessionService lifecycle — create, get, expire, cleanup.
"""

import time
import pytest
from unittest.mock import patch
from datetime import timedelta, datetime, timezone

from app.services.session_service import Session, SessionService
from app.utils.exceptions import SessionNotFoundError, SessionExpiredError


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def make_service() -> SessionService:
    return SessionService()


def make_session(service: SessionService) -> Session:
    return service.create_session(grade=2, subject="math", lesson="counting")


# ---------------------------------------------------------------------------
# Session creation
# ---------------------------------------------------------------------------

class TestSessionCreation:
    def test_create_returns_session(self):
        svc = make_service()
        session = make_session(svc)
        assert session.session_id
        assert session.grade == 2
        assert session.subject == "math"
        assert session.lesson == "counting"

    def test_session_id_is_uuid_like(self):
        svc = make_service()
        s = make_session(svc)
        assert len(s.session_id) == 36
        assert s.session_id.count("-") == 4

    def test_two_sessions_have_different_ids(self):
        svc = make_service()
        s1 = make_session(svc)
        s2 = make_session(svc)
        assert s1.session_id != s2.session_id

    def test_new_session_not_expired(self):
        svc = make_service()
        s = make_session(svc)
        assert not s.is_expired()

    def test_new_session_not_complete(self):
        svc = make_service()
        s = make_session(svc)
        assert not s.is_complete


# ---------------------------------------------------------------------------
# Session retrieval
# ---------------------------------------------------------------------------

class TestSessionRetrieval:
    def test_get_existing_session(self):
        svc = make_service()
        created = make_session(svc)
        fetched = svc.get_session(created.session_id)
        assert fetched.session_id == created.session_id

    def test_get_nonexistent_raises_not_found(self):
        svc = make_service()
        with pytest.raises(SessionNotFoundError):
            svc.get_session("nonexistent-id")

    def test_get_updates_last_activity(self):
        svc = make_service()
        s = make_session(svc)
        original_time = s.last_activity
        # Shift last_activity back slightly to detect the update
        s.last_activity = original_time - timedelta(seconds=5)
        svc.get_session(s.session_id)
        updated = svc._sessions[s.session_id]
        assert updated.last_activity >= original_time - timedelta(seconds=1)


# ---------------------------------------------------------------------------
# Session expiry
# ---------------------------------------------------------------------------

class TestSessionExpiry:
    def test_expired_session_raises_expired(self):
        svc = make_service()
        s = make_session(svc)
        # Force expiry by backdating last_activity
        s.last_activity = datetime.now(timezone.utc) - timedelta(seconds=99999)
        with pytest.raises(SessionExpiredError):
            svc.get_session(s.session_id)

    def test_expired_session_removed_from_store(self):
        svc = make_service()
        s = make_session(svc)
        s.last_activity = datetime.now(timezone.utc) - timedelta(seconds=99999)
        with pytest.raises(SessionExpiredError):
            svc.get_session(s.session_id)
        assert s.session_id not in svc._sessions

    def test_is_expired_false_for_fresh_session(self):
        svc = make_service()
        s = make_session(svc)
        assert not s.is_expired()

    def test_is_expired_true_when_timeout_exceeded(self):
        svc = make_service()
        s = make_session(svc)
        s.last_activity = datetime.now(timezone.utc) - timedelta(seconds=99999)
        assert s.is_expired()


# ---------------------------------------------------------------------------
# Session deletion
# ---------------------------------------------------------------------------

class TestSessionDeletion:
    def test_delete_removes_session(self):
        svc = make_service()
        s = make_session(svc)
        svc.delete_session(s.session_id)
        with pytest.raises(SessionNotFoundError):
            svc.get_session(s.session_id)

    def test_delete_nonexistent_is_noop(self):
        svc = make_service()
        svc.delete_session("does-not-exist")  # should not raise


# ---------------------------------------------------------------------------
# Cleanup
# ---------------------------------------------------------------------------

class TestCleanupExpired:
    def test_cleanup_removes_expired_sessions(self):
        svc = make_service()
        alive = make_session(svc)
        dead = make_session(svc)
        dead.last_activity = datetime.now(timezone.utc) - timedelta(seconds=99999)

        removed = svc.cleanup_expired()
        assert removed == 1
        assert alive.session_id in svc._sessions
        assert dead.session_id not in svc._sessions

    def test_cleanup_returns_zero_when_nothing_expired(self):
        svc = make_service()
        make_session(svc)
        make_session(svc)
        assert svc.cleanup_expired() == 0

    def test_cleanup_all_expired(self):
        svc = make_service()
        for _ in range(5):
            s = make_session(svc)
            s.last_activity = datetime.now(timezone.utc) - timedelta(seconds=99999)
        assert svc.cleanup_expired() == 5
        assert len(svc._sessions) == 0


# ---------------------------------------------------------------------------
# Active count
# ---------------------------------------------------------------------------

class TestActiveCount:
    def test_active_count_correct(self):
        svc = make_service()
        s1 = make_session(svc)
        s2 = make_session(svc)
        dead = make_session(svc)
        dead.last_activity = datetime.now(timezone.utc) - timedelta(seconds=99999)
        assert svc.active_count == 2


# ---------------------------------------------------------------------------
# Update session
# ---------------------------------------------------------------------------

class TestUpdateSession:
    def test_update_persists_changes(self):
        svc = make_service()
        s = make_session(svc)
        s.is_complete = True
        svc.update_session(s)
        fetched = svc.get_session(s.session_id)
        assert fetched.is_complete
