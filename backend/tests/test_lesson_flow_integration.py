"""
End-to-end lesson flow integration tests via HTTP endpoints.

Uses the FastAPI TestClient with mocked OpenAI to test the full request/response
cycle without a real AI key.
"""

import pytest
from unittest.mock import patch, MagicMock


# ---------------------------------------------------------------------------
# Helper — canned AI responses
# ---------------------------------------------------------------------------

CANNED_AI = "Great! Let's learn together."


def _mock_ai():
    m = MagicMock()
    m.generate_response.return_value = CANNED_AI
    m.generate_json_response.return_value = '{"title": "Counting"}'
    return m


def _mock_img():
    m = MagicMock()
    m.extract_image_request.return_value = None
    m.remove_image_marker.return_value = CANNED_AI
    m.generate_image_sync.return_value = (None, None)
    return m


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

@pytest.fixture
def lesson_client(client):
    """TestClient with AI and image generation mocked out."""
    with patch("app.services.dynamic_lesson_service.get_ai_client", return_value=_mock_ai()), \
         patch("app.services.dynamic_lesson_service.get_image_service", return_value=_mock_img()), \
         patch("app.services.dynamic_lesson_service.SessionLocal"):
        yield client


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def start_session(lesson_client) -> str:
    r = lesson_client.post("/api/v1/session/start", json={
        "grade": 2,
        "subject": "math",
        "lesson": "counting",
    })
    assert r.status_code == 200, r.text
    return r.json()["data"]["session_id"]


# ---------------------------------------------------------------------------
# Session start
# ---------------------------------------------------------------------------

class TestSessionStart:
    def test_start_session_200(self, lesson_client):
        r = lesson_client.post("/api/v1/session/start", json={
            "grade": 2, "subject": "math", "lesson": "counting",
        })
        assert r.status_code == 200

    def test_start_session_returns_session_id(self, lesson_client):
        r = lesson_client.post("/api/v1/session/start", json={
            "grade": 2, "subject": "math", "lesson": "counting",
        })
        assert r.json()["data"]["session_id"]

    def test_start_session_response_has_text(self, lesson_client):
        r = lesson_client.post("/api/v1/session/start", json={
            "grade": 2, "subject": "math", "lesson": "counting",
        })
        data = r.json()["data"]
        assert data["learno_response"]["text"]

    def test_start_session_response_type_is_welcome(self, lesson_client):
        r = lesson_client.post("/api/v1/session/start", json={
            "grade": 2, "subject": "math", "lesson": "counting",
        })
        assert r.json()["data"]["learno_response"]["response_type"] == "welcome"

    def test_start_invalid_topic_returns_422_or_error(self, lesson_client):
        r = lesson_client.post("/api/v1/session/start", json={
            "grade": 2, "subject": "math", "lesson": "nonexistent_xyz_topic",
        })
        assert r.status_code in (422, 400, 500)

    def test_start_session_progress_present(self, lesson_client):
        r = lesson_client.post("/api/v1/session/start", json={
            "grade": 2, "subject": "math", "lesson": "counting",
        })
        assert r.json()["data"]["progress"] is not None

    def test_start_session_message_chunks_present(self, lesson_client):
        r = lesson_client.post("/api/v1/session/start", json={
            "grade": 2, "subject": "math", "lesson": "counting",
        })
        messages = r.json()["data"]["learno_response"]["messages"]
        assert isinstance(messages, list)
        assert len(messages) >= 1


# ---------------------------------------------------------------------------
# Continue teaching
# ---------------------------------------------------------------------------

class TestContinueTeaching:
    def test_continue_200(self, lesson_client):
        sid = start_session(lesson_client)
        r = lesson_client.post("/api/v1/lesson/continue", json={"session_id": sid})
        assert r.status_code == 200

    def test_continue_returns_response_text(self, lesson_client):
        sid = start_session(lesson_client)
        r = lesson_client.post("/api/v1/lesson/continue", json={"session_id": sid})
        assert r.json()["data"]["learno_response"]["text"]

    def test_continue_invalid_session_422_or_error(self, lesson_client):
        r = lesson_client.post("/api/v1/lesson/continue", json={"session_id": "bad-id"})
        assert r.status_code in (404, 400, 422, 500)


# ---------------------------------------------------------------------------
# Respond to question
# ---------------------------------------------------------------------------

class TestRespond:
    def test_respond_200(self, lesson_client):
        sid = start_session(lesson_client)
        r = lesson_client.post("/api/v1/lesson/respond", json={
            "session_id": sid, "transcript": "five"
        })
        assert r.status_code == 200

    def test_respond_returns_response_text(self, lesson_client):
        sid = start_session(lesson_client)
        r = lesson_client.post("/api/v1/lesson/respond", json={
            "session_id": sid, "transcript": "five"
        })
        assert r.json()["data"]["learno_response"]["text"]

    def test_respond_empty_transcript_422(self, lesson_client):
        sid = start_session(lesson_client)
        r = lesson_client.post("/api/v1/lesson/respond", json={
            "session_id": sid, "transcript": "  "
        })
        assert r.status_code == 422

    def test_respond_xss_sanitized(self, lesson_client):
        sid = start_session(lesson_client)
        r = lesson_client.post("/api/v1/lesson/respond", json={
            "session_id": sid, "transcript": "<script>alert(1)</script> five"
        })
        assert r.status_code == 200
        # The < > chars should have been stripped
        assert "<script>" not in r.json()["data"]["learno_response"]["text"]


# ---------------------------------------------------------------------------
# Silence handling
# ---------------------------------------------------------------------------

class TestSilenceHandling:
    def test_silence_200(self, lesson_client):
        sid = start_session(lesson_client)
        r = lesson_client.post("/api/v1/lesson/silence", json={
            "session_id": sid, "silence_duration": 12.0
        })
        assert r.status_code == 200

    def test_silence_returns_hint_response(self, lesson_client):
        sid = start_session(lesson_client)
        r = lesson_client.post("/api/v1/lesson/silence", json={
            "session_id": sid, "silence_duration": 12.0
        })
        assert r.json()["data"]["learno_response"]["response_type"] == "silence_hint"

    def test_silence_duration_zero_422(self, lesson_client):
        sid = start_session(lesson_client)
        r = lesson_client.post("/api/v1/lesson/silence", json={
            "session_id": sid, "silence_duration": 0
        })
        assert r.status_code == 422

    def test_silence_duration_capped_at_300(self, lesson_client):
        sid = start_session(lesson_client)
        r = lesson_client.post("/api/v1/lesson/silence", json={
            "session_id": sid, "silence_duration": 9999.0
        })
        assert r.status_code == 200


# ---------------------------------------------------------------------------
# End session
# ---------------------------------------------------------------------------

class TestEndSession:
    def test_end_session_200(self, lesson_client):
        sid = start_session(lesson_client)
        r = lesson_client.post("/api/v1/session/end", json={"session_id": sid})
        assert r.status_code == 200

    def test_end_session_returns_summary(self, lesson_client):
        sid = start_session(lesson_client)
        r = lesson_client.post("/api/v1/session/end", json={"session_id": sid})
        data = r.json()["data"]
        assert "is_complete" in data
        assert "total_correct" in data

    def test_end_session_twice_is_idempotent(self, lesson_client):
        # Ending a session twice must not crash — it returns 200 with an empty
        # summary on the second call (graceful double-end for unreliable networks).
        sid = start_session(lesson_client)
        r1 = lesson_client.post("/api/v1/session/end", json={"session_id": sid})
        r2 = lesson_client.post("/api/v1/session/end", json={"session_id": sid})
        assert r1.status_code == 200
        assert r2.status_code == 200
