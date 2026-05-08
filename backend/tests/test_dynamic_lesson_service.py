"""
Tests for DynamicLessonService — lesson flow state machine (OpenAI mocked).
"""

import pytest
from unittest.mock import MagicMock, patch

from app.services.dynamic_lesson_service import DynamicLessonService, TeachingState
from app.services.session_service import SessionService
from app.models.lesson_content import LessonPhase, ConceptPhase
from app.utils.exceptions import LessonNotAvailableError


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

@pytest.fixture
def ai_mock():
    """A mocked LearnoAIClient that always returns a short canned text."""
    mock = MagicMock()
    mock.generate_response.return_value = "Great! Let's learn counting."
    mock.generate_json_response.return_value = '{"title": "Counting"}'
    return mock


@pytest.fixture
def service(ai_mock):
    """DynamicLessonService with all external dependencies mocked."""
    with patch("app.services.dynamic_lesson_service.get_ai_client", return_value=ai_mock), \
         patch("app.services.dynamic_lesson_service.get_image_service") as img_mock, \
         patch("app.services.dynamic_lesson_service.generate_chapter") as gen_mock, \
         patch("app.services.dynamic_lesson_service.SessionLocal"):

        # Image service stub
        img_svc = MagicMock()
        img_svc.extract_image_request.return_value = None
        img_svc.remove_image_marker.return_value = "Great! Let's learn counting."
        img_svc.generate_image_sync.return_value = (None, None)
        img_mock.return_value = img_svc

        # Use a real chapter for Grade 2 math / counting
        gen_mock.return_value = None  # will use static path for counting

        svc = DynamicLessonService()
        yield svc


# ---------------------------------------------------------------------------
# start_lesson
# ---------------------------------------------------------------------------

class TestStartLesson:
    def test_start_lesson_returns_session_and_response(self, service):
        session, response = service.start_lesson(grade=2, subject="math", lesson="counting")
        assert session.session_id
        assert response.text
        assert response.response_type == "welcome"

    def test_start_lesson_unknown_topic_raises(self, service):
        with pytest.raises(LessonNotAvailableError):
            service.start_lesson(grade=2, subject="math", lesson="nonexistent_topic_xyz")

    def test_start_lesson_creates_teaching_state(self, service):
        session, _ = service.start_lesson(grade=2, subject="math", lesson="counting")
        state = service._get_state(session.session_id)
        assert state.lesson_phase == LessonPhase.TEACHING
        assert state.current_concept_index == 0
        # start_lesson emits the welcome; first concept begins on next continue_teaching call
        assert state.concept_phase == ConceptPhase.INTRODUCTION

    def test_start_lesson_progress_info_populated(self, service):
        _, response = service.start_lesson(grade=2, subject="math", lesson="counting")
        assert response.progress_info is not None
        assert response.progress_info["total_concepts"] > 0

    def test_start_lesson_messages_chunked(self, service):
        _, response = service.start_lesson(grade=2, subject="math", lesson="counting")
        # Response may have 1+ chunks
        assert len(response.messages) >= 1


# ---------------------------------------------------------------------------
# continue_teaching
# ---------------------------------------------------------------------------

class TestContinueTeaching:
    def test_continue_advances_concept_phase(self, service):
        session, _ = service.start_lesson(grade=2, subject="math", lesson="counting")
        state = service._get_state(session.session_id)
        assert state.concept_phase == ConceptPhase.INTRODUCTION
        # First continue_teaching call runs the introduction phase → advances to EXPLANATION
        response = service.continue_teaching(session.session_id)
        assert response.text
        assert response.response_type in (
            "explanation", "visual_example", "guided_practice",
            "independent_practice", "mastery_check", "concept_introduction",
        )
        assert state.concept_phase == ConceptPhase.EXPLANATION

    def test_continue_nonexistent_session_raises(self, service):
        from app.utils.exceptions import SessionNotFoundError
        with pytest.raises(SessionNotFoundError):
            service.continue_teaching("nonexistent-session-id")


# ---------------------------------------------------------------------------
# process_response — answer evaluation
# ---------------------------------------------------------------------------

class TestProcessResponse:
    def _start(self, service):
        session, _ = service.start_lesson(grade=2, subject="math", lesson="counting")
        # Advance to a question phase by continuing until _waitingForAnswer would be true
        state = service._get_state(session.session_id)
        # Manually set an expected answer for testing
        state.current_expected_answer = "5"
        state.current_acceptable_answers = ["five", "5"]
        state.current_hint = "Think about five apples"
        state.concept_phase = ConceptPhase.GUIDED_PRACTICE
        return session

    def test_correct_answer_records_correct(self, service):
        session = self._start(service)
        state = service._get_state(session.session_id)
        service.process_response(session.session_id, "5")
        assert state.total_correct == 1

    def test_wrong_answer_records_wrong(self, service):
        session = self._start(service)
        state = service._get_state(session.session_id)
        service.process_response(session.session_id, "99")
        assert state.total_wrong == 1

    def test_wrong_answer_returns_hint_type(self, service):
        session = self._start(service)
        response = service.process_response(session.session_id, "99")
        assert response.response_type == "hint"

    def test_acceptable_answer_counts_as_correct(self, service):
        session = self._start(service)
        state = service._get_state(session.session_id)
        service.process_response(session.session_id, "five")
        assert state.total_correct == 1

    def test_number_in_transcript_matches(self, service):
        session = self._start(service)
        state = service._get_state(session.session_id)
        service.process_response(session.session_id, "I think it is 5 apples")
        assert state.total_correct == 1

    def test_three_wrong_sets_needs_extra_help(self, service):
        session = self._start(service)
        state = service._get_state(session.session_id)
        for _ in range(3):
            state.current_expected_answer = "5"
            service.process_response(session.session_id, "wrong_answer_xyz")
        assert state.needs_extra_help


# ---------------------------------------------------------------------------
# handle_silence
# ---------------------------------------------------------------------------

class TestHandleSilence:
    def test_silence_returns_hint(self, service):
        session, _ = service.start_lesson(grade=2, subject="math", lesson="counting")
        state = service._get_state(session.session_id)
        state.current_expected_answer = "5"
        state.current_hint = "Think!"
        response = service.handle_silence(session.session_id, 12.0)
        assert response.response_type == "silence_hint"
        assert response.text


# ---------------------------------------------------------------------------
# end_lesson
# ---------------------------------------------------------------------------

class TestEndLesson:
    def test_end_lesson_returns_summary(self, service):
        session, _ = service.start_lesson(grade=2, subject="math", lesson="counting")
        summary, message = service.end_lesson(session.session_id)
        assert "is_complete" in summary
        assert message

    def test_end_lesson_cleans_up_state(self, service):
        session, _ = service.start_lesson(grade=2, subject="math", lesson="counting")
        service.end_lesson(session.session_id)
        assert session.session_id not in service._teaching_states


# ---------------------------------------------------------------------------
# TeachingState helpers
# ---------------------------------------------------------------------------

class TestTeachingState:
    def test_record_correct_resets_consecutive_wrong(self):
        state = TeachingState()
        state.consecutive_wrong = 2
        state.record_correct()
        assert state.consecutive_wrong == 0
        assert state.total_correct == 1

    def test_record_wrong_increments(self):
        state = TeachingState()
        state.record_wrong()
        assert state.total_wrong == 1
        assert state.current_attempts == 1

    def test_needs_extra_help_after_3_wrong(self):
        state = TeachingState()
        state.record_wrong()
        state.record_wrong()
        assert not state.needs_extra_help
        state.record_wrong()
        assert state.needs_extra_help

    def test_reset_attempts_clears_counts(self):
        state = TeachingState()
        state.record_wrong()
        state.record_wrong()
        state.reset_attempts()
        assert state.current_attempts == 0
        assert state.consecutive_wrong == 0
