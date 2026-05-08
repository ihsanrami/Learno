"""
Edge-case tests for analytics: streak calculation, achievement boundaries,
week_streak, subject_master, and timezone-safety of check_and_award_achievements.
"""

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
    parent = models.Parent(email="edge@test.com", hashed_password="x", full_name="Edge Parent")
    db.add(parent)
    db.flush()
    c = models.ChildProfile(parent_id=parent.id, name="EdgeKid", age=7, grade=models.GradeEnum.second)
    db.add(c)
    db.flush()
    return c


def _completed_session(db, child_id, days_ago=0, subject="math", correct=8, total=10):
    """Create a completed session started `days_ago` days before now."""
    started = datetime.now(timezone.utc) - timedelta(days=days_ago)
    s = models.LearningSession(
        child_id=child_id,
        grade="2",
        subject=subject,
        topic_id="counting",
        started_at=started,
        ended_at=started + timedelta(minutes=10),
        duration_seconds=600,
        questions_correct=correct,
        questions_total=total,
        concepts_completed=5,
        concepts_total=5,
        completed=True,
    )
    db.add(s)
    db.flush()
    return s


# ---------------------------------------------------------------------------
# Streak calculation
# ---------------------------------------------------------------------------

def test_streak_zero_when_no_sessions(db, child):
    assert svc._calculate_streak(db, child.id) == 0


def test_streak_one_today(db, child):
    _completed_session(db, child.id, days_ago=0)
    assert svc._calculate_streak(db, child.id) == 1


def test_streak_two_consecutive(db, child):
    _completed_session(db, child.id, days_ago=0)
    _completed_session(db, child.id, days_ago=1)
    assert svc._calculate_streak(db, child.id) == 2


def test_streak_five_consecutive(db, child):
    for i in range(5):
        _completed_session(db, child.id, days_ago=i)
    assert svc._calculate_streak(db, child.id) == 5


def test_streak_gap_breaks_streak(db, child):
    """A gap resets the streak from that day forward."""
    _completed_session(db, child.id, days_ago=0)
    _completed_session(db, child.id, days_ago=1)
    # gap at days_ago=2
    _completed_session(db, child.id, days_ago=3)
    _completed_session(db, child.id, days_ago=4)
    # Streak from today = only 2 (today + yesterday), then gap breaks it
    assert svc._calculate_streak(db, child.id) == 2


def test_streak_old_history_doesnt_count_without_recent(db, child):
    """Sessions 10 days ago should not contribute to current streak."""
    _completed_session(db, child.id, days_ago=10)
    _completed_session(db, child.id, days_ago=11)
    assert svc._calculate_streak(db, child.id) == 0


def test_streak_multiple_sessions_same_day_count_once(db, child):
    """Multiple sessions in one day count as 1 streak day."""
    _completed_session(db, child.id, days_ago=0)
    _completed_session(db, child.id, days_ago=0)
    _completed_session(db, child.id, days_ago=0)
    _completed_session(db, child.id, days_ago=1)
    assert svc._calculate_streak(db, child.id) == 2


def test_streak_incomplete_sessions_not_counted(db, child):
    """Incomplete sessions do NOT contribute to streak."""
    started = datetime.now(timezone.utc)
    s = models.LearningSession(
        child_id=child.id,
        grade="2", subject="math", topic_id="counting",
        started_at=started,
        completed=False,
    )
    db.add(s)
    db.flush()
    assert svc._calculate_streak(db, child.id) == 0


# ---------------------------------------------------------------------------
# week_streak achievement (requires 5+ consecutive days)
# ---------------------------------------------------------------------------

def test_week_streak_achievement_at_5_days(db, child):
    for i in range(5):
        _completed_session(db, child.id, days_ago=i)
    awarded = svc.check_and_award_achievements(db, child.id)
    assert "week_streak" in awarded


def test_week_streak_not_awarded_at_4_days(db, child):
    for i in range(4):
        _completed_session(db, child.id, days_ago=i)
    awarded = svc.check_and_award_achievements(db, child.id)
    assert "week_streak" not in awarded


def test_week_streak_awarded_at_7_days(db, child):
    for i in range(7):
        _completed_session(db, child.id, days_ago=i)
    awarded = svc.check_and_award_achievements(db, child.id)
    assert "week_streak" in awarded


# ---------------------------------------------------------------------------
# subject_master achievement (10+ lessons, 80%+ accuracy in one subject)
# ---------------------------------------------------------------------------

def test_subject_master_at_10_lessons_high_accuracy(db, child):
    for _ in range(10):
        _completed_session(db, child.id, subject="math", correct=9, total=10)
    awarded = svc.check_and_award_achievements(db, child.id)
    assert "subject_master" in awarded


def test_subject_master_not_awarded_with_9_lessons(db, child):
    for _ in range(9):
        _completed_session(db, child.id, subject="science", correct=9, total=10)
    awarded = svc.check_and_award_achievements(db, child.id)
    assert "subject_master" not in awarded


def test_subject_master_not_awarded_with_low_accuracy(db, child):
    for _ in range(10):
        _completed_session(db, child.id, subject="english", correct=5, total=10)
    awarded = svc.check_and_award_achievements(db, child.id)
    assert "subject_master" not in awarded


def test_subject_master_boundary_exactly_80_pct(db, child):
    """Exactly 80% accuracy qualifies for subject_master."""
    for _ in range(10):
        _completed_session(db, child.id, subject="arabic", correct=8, total=10)
    awarded = svc.check_and_award_achievements(db, child.id)
    assert "subject_master" in awarded


def test_subject_master_mixed_subjects_no_cross_contamination(db, child):
    """8 math + 8 science sessions should NOT award subject_master for either."""
    for _ in range(8):
        _completed_session(db, child.id, subject="math", correct=9, total=10)
    for _ in range(8):
        _completed_session(db, child.id, subject="science", correct=9, total=10)
    awarded = svc.check_and_award_achievements(db, child.id)
    assert "subject_master" not in awarded


# ---------------------------------------------------------------------------
# check_and_award_achievements timezone safety
# ---------------------------------------------------------------------------

def test_speed_learner_today_with_tz_aware_sessions(db, child):
    """speed_learner requires 3 completed sessions today; _tz() fix must handle aware datetimes."""
    for _ in range(3):
        _completed_session(db, child.id, days_ago=0)
    awarded = svc.check_and_award_achievements(db, child.id)
    assert "speed_learner" in awarded


def test_speed_learner_not_awarded_for_yesterday_sessions(db, child):
    """Sessions from yesterday should NOT count toward today's speed_learner."""
    for _ in range(3):
        _completed_session(db, child.id, days_ago=1)
    awarded = svc.check_and_award_achievements(db, child.id)
    assert "speed_learner" not in awarded


# ---------------------------------------------------------------------------
# Weekly activity edge cases
# ---------------------------------------------------------------------------

def test_weekly_activity_empty_returns_7_zeros(db, child):
    weekly = svc.get_weekly_activity(db, child.id)
    assert len(weekly) == 7
    assert all(entry["minutes"] == 0 for entry in weekly)
    assert all(entry["lessons_completed"] == 0 for entry in weekly)


def test_weekly_activity_custom_days_parameter(db, child):
    weekly = svc.get_weekly_activity(db, child.id, days=3)
    assert len(weekly) == 3


def test_weekly_activity_session_5_days_ago_appears(db, child):
    _completed_session(db, child.id, days_ago=5)
    weekly = svc.get_weekly_activity(db, child.id)
    # Entry at index 1 corresponds to 5 days ago in a 7-day window
    assert weekly[1]["lessons_completed"] == 1


def test_weekly_activity_minutes_accumulated_correctly(db, child):
    """Two 600-second sessions today = 20 minutes total."""
    s1 = _completed_session(db, child.id, days_ago=0)
    s2 = _completed_session(db, child.id, days_ago=0)
    weekly = svc.get_weekly_activity(db, child.id)
    today_entry = weekly[-1]
    assert today_entry["minutes"] == 20


# ---------------------------------------------------------------------------
# get_child_overview edge cases
# ---------------------------------------------------------------------------

def test_overview_total_accuracy_across_sessions(db, child):
    _completed_session(db, child.id, correct=10, total=10)
    _completed_session(db, child.id, correct=0, total=10)
    overview = svc.get_child_overview(db, child.id)
    assert overview["overall_accuracy"] == 50.0


def test_overview_total_minutes_accumulates(db, child):
    for _ in range(3):
        _completed_session(db, child.id)
    overview = svc.get_child_overview(db, child.id)
    assert overview["total_learning_minutes"] == 30  # 3 × 600 seconds


def test_overview_goal_progress_capped_at_100(db, child):
    svc.set_daily_goal(db, child.id, 5)  # 5-minute goal
    _completed_session(db, child.id)     # 10-minute session
    overview = svc.get_child_overview(db, child.id)
    assert overview["goal_progress_percent"] == 100


def test_overview_accuracy_zero_when_no_questions(db, child):
    """Sessions with no questions should produce 0.0 accuracy, not a division error."""
    s = models.LearningSession(
        child_id=child.id, grade="2", subject="math", topic_id="test",
        completed=True, questions_correct=0, questions_total=0, duration_seconds=300,
    )
    db.add(s)
    db.flush()
    overview = svc.get_child_overview(db, child.id)
    assert overview["today_accuracy"] == 0.0
    assert overview["overall_accuracy"] == 0.0
