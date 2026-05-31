"""Tests for analytics service functions (direct DB calls, no HTTP)."""

from app.auth.models import Parent, ChildProfile
from app.services.analytics_service import (
    start_session,
    end_session,
    set_daily_goal,
    get_or_create_goal,
    check_and_award_achievements,
)


def _make_child(db):
    """Create a parent + child in the DB and return the child."""
    parent = Parent(
        email="analytics@test.com",
        hashed_password="not-a-real-hash",
        full_name="Analytics Parent",
    )
    db.add(parent)
    db.flush()
    child = ChildProfile(
        parent_id=parent.id,
        name="TestChild",
        age=7,
        grade="second",
    )
    db.add(child)
    db.flush()
    return child


# ── start_session ─────────────────────────────────────────────────────────────

def test_start_session_creates_db_record(db_session):
    child = _make_child(db_session)
    session = start_session(db_session, child.id, "second", "math", "even_and_odd")
    assert session.id is not None
    assert session.child_id == child.id
    assert session.grade == "second"
    assert session.subject == "math"
    assert session.topic_id == "even_and_odd"
    assert session.completed is False


# ── end_session ───────────────────────────────────────────────────────────────

def test_end_session_updates_fields(db_session):
    child = _make_child(db_session)
    session = start_session(db_session, child.id, "first", "science", "heating_and_cooling")

    result = end_session(
        db_session,
        session_id=session.id,
        questions_correct=8,
        questions_total=10,
        concepts_completed=5,
        concepts_total=5,
        completed=True,
    )

    assert result.completed is True
    assert result.questions_correct == 8
    assert result.questions_total == 10
    assert result.duration_seconds >= 0
    assert result.ended_at is not None


# ── set_daily_goal ────────────────────────────────────────────────────────────

def test_set_daily_goal(db_session):
    child = _make_child(db_session)

    goal1 = set_daily_goal(db_session, child.id, target_minutes=20)
    assert goal1.target_minutes == 20
    assert goal1.active is True

    goal2 = set_daily_goal(db_session, child.id, target_minutes=30)
    assert goal2.target_minutes == 30
    assert goal2.active is True

    # Old goal must be deactivated after a new one is set
    db_session.refresh(goal1)
    assert goal1.active is False


# ── get_or_create_goal ────────────────────────────────────────────────────────

def test_get_or_create_goal(db_session):
    child = _make_child(db_session)

    # First call creates a goal with default 15 minutes
    goal = get_or_create_goal(db_session, child.id)
    assert goal.id is not None
    assert goal.target_minutes == 15

    # Second call returns the existing goal (same id)
    goal2 = get_or_create_goal(db_session, child.id)
    assert goal2.id == goal.id


# ── check_and_award_achievements ──────────────────────────────────────────────

def test_check_and_award_first_lesson(db_session):
    child = _make_child(db_session)

    # No completed sessions → no achievement awarded
    awarded = check_and_award_achievements(db_session, child.id)
    assert "first_lesson" not in awarded

    # Create and complete a session
    session = start_session(db_session, child.id, "kindergarten", "english", "letters_a_to_h")
    end_session(
        db_session,
        session_id=session.id,
        questions_correct=5,
        questions_total=5,
        concepts_completed=3,
        concepts_total=3,
        completed=True,
    )

    awarded = check_and_award_achievements(db_session, child.id)
    assert "first_lesson" in awarded

    # Running again must not re-award an already-earned achievement
    awarded_again = check_and_award_achievements(db_session, child.id)
    assert "first_lesson" not in awarded_again
