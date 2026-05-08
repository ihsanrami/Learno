"""Tests for analytics service and parent endpoints."""

import os
import sys

os.environ.setdefault("OPENAI_API_KEY", "sk-test-not-real")
os.environ.setdefault("DATABASE_URL", "sqlite:///:memory:")
os.environ.setdefault("JWT_SECRET_KEY", "test-secret-key-not-for-production")

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import pytest
from datetime import datetime, timezone, timedelta
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.database.base import Base
import app.auth.models as models
import app.services.analytics_service as svc


@pytest.fixture(scope="module")
def engine():
    eng = create_engine("sqlite:///:memory:", connect_args={"check_same_thread": False})
    Base.metadata.create_all(bind=eng)
    yield eng
    Base.metadata.drop_all(bind=eng)


@pytest.fixture
def db(engine):
    conn = engine.connect()
    txn = conn.begin()
    Session = sessionmaker(bind=conn)
    session = Session()
    yield session
    session.close()
    txn.rollback()
    conn.close()


@pytest.fixture
def child(db):
    parent = models.Parent(
        email="parent@test.com",
        hashed_password="x",
        full_name="Test Parent",
    )
    db.add(parent)
    db.flush()

    child = models.ChildProfile(
        parent_id=parent.id,
        name="Alice",
        age=7,
        grade=models.GradeEnum.second,
    )
    db.add(child)
    db.flush()
    return child


# ---------------------------------------------------------------------------
# start_session / end_session
# ---------------------------------------------------------------------------

def test_start_session_creates_record(db, child):
    session = svc.start_session(db, child.id, "2", "math", "counting")
    assert session.id is not None
    assert session.child_id == child.id
    assert session.grade == "2"
    assert session.subject == "math"
    assert session.topic_id == "counting"
    assert session.completed is False
    assert session.ended_at is None


def test_end_session_sets_fields(db, child):
    session = svc.start_session(db, child.id, "2", "math", "counting")
    ended = svc.end_session(
        db,
        session_id=session.id,
        questions_correct=8,
        questions_total=10,
        concepts_completed=3,
        concepts_total=5,
        completed=True,
    )
    assert ended.questions_correct == 8
    assert ended.questions_total == 10
    assert ended.concepts_completed == 3
    assert ended.completed is True
    assert ended.ended_at is not None
    assert ended.duration_seconds >= 0


def test_end_session_missing_id_returns_none(db):
    result = svc.end_session(db, 99999, 0, 0, 0, 5, False)
    assert result is None


# ---------------------------------------------------------------------------
# get_child_overview
# ---------------------------------------------------------------------------

def test_overview_empty_child(db, child):
    overview = svc.get_child_overview(db, child.id)
    assert overview["today_minutes"] == 0
    assert overview["today_lessons_completed"] == 0
    assert overview["streak_days"] == 0
    assert overview["total_lessons"] == 0
    assert overview["target_minutes"] == 15  # default goal


def test_overview_with_session(db, child):
    session = svc.start_session(db, child.id, "2", "math", "counting")
    svc.end_session(db, session.id, 8, 10, 5, 5, True)
    overview = svc.get_child_overview(db, child.id)
    assert overview["today_lessons_completed"] == 1
    assert overview["total_lessons"] == 1
    assert overview["today_accuracy"] == 80.0


def test_overview_goal_progress(db, child):
    svc.set_daily_goal(db, child.id, 30)
    # Add a 15-minute session
    session = svc.start_session(db, child.id, "2", "math", "counting")
    session.duration_seconds = 900  # 15 minutes
    session.completed = True
    db.flush()
    overview = svc.get_child_overview(db, child.id)
    assert overview["target_minutes"] == 30
    assert overview["goal_progress_percent"] == 50


# ---------------------------------------------------------------------------
# get_weekly_activity
# ---------------------------------------------------------------------------

def test_weekly_activity_returns_7_days(db, child):
    weekly = svc.get_weekly_activity(db, child.id)
    assert len(weekly) == 7


def test_weekly_activity_includes_today(db, child):
    session = svc.start_session(db, child.id, "2", "math", "counting")
    svc.end_session(db, session.id, 5, 5, 5, 5, True)
    weekly = svc.get_weekly_activity(db, child.id)
    today_entry = weekly[-1]
    assert today_entry["lessons_completed"] == 1


# ---------------------------------------------------------------------------
# get_topics_mastered
# ---------------------------------------------------------------------------

def test_topics_mastered_empty(db, child):
    topics = svc.get_topics_mastered(db, child.id)
    assert topics == []


def test_topics_mastered_high_accuracy(db, child):
    session = svc.start_session(db, child.id, "2", "math", "addition")
    svc.end_session(db, session.id, 9, 10, 5, 5, True)
    topics = svc.get_topics_mastered(db, child.id)
    assert len(topics) == 1
    assert topics[0]["mastered"] is True
    assert topics[0]["accuracy"] == 90.0


def test_topics_mastered_low_accuracy_not_mastered(db, child):
    session = svc.start_session(db, child.id, "2", "math", "division")
    svc.end_session(db, session.id, 3, 10, 2, 5, True)
    topics = svc.get_topics_mastered(db, child.id)
    div = next(t for t in topics if t["topic_id"] == "division")
    assert div["mastered"] is False


# ---------------------------------------------------------------------------
# get_subject_breakdown
# ---------------------------------------------------------------------------

def test_subject_breakdown_empty(db, child):
    result = svc.get_subject_breakdown(db, child.id)
    assert result == []


def test_subject_breakdown_single_subject(db, child):
    session = svc.start_session(db, child.id, "2", "math", "counting")
    session.duration_seconds = 600
    db.flush()
    result = svc.get_subject_breakdown(db, child.id)
    assert len(result) == 1
    assert result[0]["subject"] == "math"
    assert result[0]["minutes"] == 10
    assert result[0]["percent"] == 100.0


# ---------------------------------------------------------------------------
# achievements
# ---------------------------------------------------------------------------

def test_no_achievements_initially(db, child):
    achievements = svc.get_achievements(db, child.id)
    assert len(achievements) == len(svc.ACHIEVEMENT_DEFINITIONS)
    for a in achievements:
        assert a["earned"] is False


def test_first_lesson_achievement(db, child):
    session = svc.start_session(db, child.id, "2", "math", "counting")
    svc.end_session(db, session.id, 5, 10, 5, 5, True)
    awarded = svc.check_and_award_achievements(db, child.id)
    assert "first_lesson" in awarded


def test_achievement_not_awarded_twice(db, child):
    session = svc.start_session(db, child.id, "2", "math", "counting")
    svc.end_session(db, session.id, 5, 10, 5, 5, True)
    svc.check_and_award_achievements(db, child.id)
    awarded2 = svc.check_and_award_achievements(db, child.id)
    assert "first_lesson" not in awarded2


def test_correct_streak_achievement(db, child):
    session = svc.start_session(db, child.id, "2", "math", "counting")
    svc.end_session(db, session.id, 10, 10, 5, 5, True)
    awarded = svc.check_and_award_achievements(db, child.id)
    assert "correct_streak" in awarded


def test_speed_learner_achievement(db, child):
    for _ in range(3):
        s = svc.start_session(db, child.id, "2", "math", "counting")
        svc.end_session(db, s.id, 5, 10, 5, 5, True)
    awarded = svc.check_and_award_achievements(db, child.id)
    assert "speed_learner" in awarded


def test_get_achievements_shows_earned(db, child):
    session = svc.start_session(db, child.id, "2", "math", "counting")
    svc.end_session(db, session.id, 5, 10, 5, 5, True)
    svc.check_and_award_achievements(db, child.id)
    achievements = svc.get_achievements(db, child.id)
    earned = [a for a in achievements if a["earned"]]
    assert len(earned) >= 1


# ---------------------------------------------------------------------------
# daily goals
# ---------------------------------------------------------------------------

def test_get_or_create_goal_default(db, child):
    goal = svc.get_or_create_goal(db, child.id)
    assert goal.target_minutes == 15
    assert goal.active is True


def test_set_daily_goal(db, child):
    goal = svc.set_daily_goal(db, child.id, 30)
    assert goal.target_minutes == 30


def test_set_daily_goal_deactivates_previous(db, child):
    svc.set_daily_goal(db, child.id, 20)
    svc.set_daily_goal(db, child.id, 45)
    goal = svc.get_or_create_goal(db, child.id)
    assert goal.target_minutes == 45
