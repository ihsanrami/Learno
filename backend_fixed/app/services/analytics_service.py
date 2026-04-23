"""Analytics service for tracking child learning progress."""

import logging
from datetime import datetime, timezone, timedelta
from typing import Optional
from sqlalchemy.orm import Session
from sqlalchemy import func, and_

from app.auth.models import LearningSession, DailyGoal, Achievement, ChildProfile

logger = logging.getLogger(__name__)

ACHIEVEMENT_DEFINITIONS = {
    "first_lesson": {
        "title": "First Steps!",
        "description": "Completed your very first lesson",
        "icon": "🌟",
    },
    "week_streak": {
        "title": "Week Warrior",
        "description": "Learned 5 or more days in a row",
        "icon": "🔥",
    },
    "subject_master": {
        "title": "Subject Master",
        "description": "Achieved 80%+ accuracy in 10+ lessons of the same subject",
        "icon": "🏆",
    },
    "speed_learner": {
        "title": "Speed Learner",
        "description": "Completed 3 lessons in a single day",
        "icon": "⚡",
    },
    "correct_streak": {
        "title": "Perfect Run",
        "description": "Got 10 correct answers in a row",
        "icon": "💯",
    },
}


def start_session(
    db: Session,
    child_id: int,
    grade: str,
    subject: str,
    topic_id: str,
) -> LearningSession:
    session = LearningSession(
        child_id=child_id,
        grade=grade,
        subject=subject,
        topic_id=topic_id,
    )
    db.add(session)
    db.commit()
    db.refresh(session)
    return session


def end_session(
    db: Session,
    session_id: int,
    questions_correct: int,
    questions_total: int,
    concepts_completed: int,
    concepts_total: int,
    completed: bool,
) -> LearningSession:
    session = db.query(LearningSession).filter(LearningSession.id == session_id).first()
    if not session:
        return None

    now = datetime.now(timezone.utc)
    started = session.started_at
    if started.tzinfo is None:
        started = started.replace(tzinfo=timezone.utc)

    session.ended_at = now
    session.duration_seconds = int((now - started).total_seconds())
    session.questions_correct = questions_correct
    session.questions_total = questions_total
    session.concepts_completed = concepts_completed
    session.concepts_total = concepts_total
    session.completed = completed

    db.commit()
    db.refresh(session)
    return session


def get_child_overview(db: Session, child_id: int) -> dict:
    today = datetime.now(timezone.utc).date()
    today_start = datetime(today.year, today.month, today.day, tzinfo=timezone.utc)
    today_end = today_start + timedelta(days=1)

    today_sessions = (
        db.query(LearningSession)
        .filter(
            LearningSession.child_id == child_id,
            LearningSession.started_at >= today_start,
            LearningSession.started_at < today_end,
        )
        .all()
    )

    today_minutes = sum(s.duration_seconds for s in today_sessions) // 60
    today_lessons = len([s for s in today_sessions if s.completed])
    today_correct = sum(s.questions_correct for s in today_sessions)
    today_total = sum(s.questions_total for s in today_sessions)
    today_accuracy = (today_correct / today_total * 100) if today_total > 0 else 0.0

    streak = _calculate_streak(db, child_id)
    goal = _get_active_goal(db, child_id)
    target_minutes = goal.target_minutes if goal else 15

    all_sessions = db.query(LearningSession).filter(LearningSession.child_id == child_id).all()
    total_correct = sum(s.questions_correct for s in all_sessions)
    total_questions = sum(s.questions_total for s in all_sessions)
    overall_accuracy = (total_correct / total_questions * 100) if total_questions > 0 else 0.0
    total_minutes = sum(s.duration_seconds for s in all_sessions) // 60

    return {
        "today_minutes": today_minutes,
        "today_lessons_completed": today_lessons,
        "today_accuracy": round(today_accuracy, 1),
        "streak_days": streak,
        "target_minutes": target_minutes,
        "goal_progress_percent": min(100, int(today_minutes / target_minutes * 100)) if target_minutes > 0 else 0,
        "total_lessons": len([s for s in all_sessions if s.completed]),
        "overall_accuracy": round(overall_accuracy, 1),
        "total_learning_minutes": total_minutes,
    }


def get_weekly_activity(db: Session, child_id: int, days: int = 7) -> list:
    now = datetime.now(timezone.utc)
    result = []

    for i in range(days - 1, -1, -1):
        day = now - timedelta(days=i)
        day_start = datetime(day.year, day.month, day.day, tzinfo=timezone.utc)
        day_end = day_start + timedelta(days=1)

        sessions = (
            db.query(LearningSession)
            .filter(
                LearningSession.child_id == child_id,
                LearningSession.started_at >= day_start,
                LearningSession.started_at < day_end,
            )
            .all()
        )

        minutes = sum(s.duration_seconds for s in sessions) // 60
        lessons = len([s for s in sessions if s.completed])

        result.append({
            "date": day_start.date().isoformat(),
            "day_label": day_start.strftime("%a"),
            "minutes": minutes,
            "lessons_completed": lessons,
        })

    return result


def get_topics_mastered(db: Session, child_id: int) -> list:
    sessions = (
        db.query(LearningSession)
        .filter(LearningSession.child_id == child_id, LearningSession.completed == True)
        .all()
    )

    topic_stats: dict[str, dict] = {}
    for s in sessions:
        key = f"{s.subject}:{s.topic_id}"
        if key not in topic_stats:
            topic_stats[key] = {
                "subject": s.subject,
                "topic_id": s.topic_id,
                "correct": 0,
                "total": 0,
                "attempts": 0,
            }
        topic_stats[key]["correct"] += s.questions_correct
        topic_stats[key]["total"] += s.questions_total
        topic_stats[key]["attempts"] += 1

    result = []
    for stats in topic_stats.values():
        accuracy = (stats["correct"] / stats["total"] * 100) if stats["total"] > 0 else 0
        result.append({
            "subject": stats["subject"],
            "topic_id": stats["topic_id"],
            "accuracy": round(accuracy, 1),
            "attempts": stats["attempts"],
            "mastered": accuracy >= 80,
        })

    result.sort(key=lambda x: x["accuracy"], reverse=True)
    return result


def get_subject_breakdown(db: Session, child_id: int) -> list:
    sessions = (
        db.query(LearningSession)
        .filter(LearningSession.child_id == child_id)
        .all()
    )

    subject_minutes: dict[str, int] = {}
    for s in sessions:
        subject_minutes[s.subject] = subject_minutes.get(s.subject, 0) + s.duration_seconds // 60

    total = sum(subject_minutes.values())
    return [
        {
            "subject": subj,
            "minutes": mins,
            "percent": round(mins / total * 100, 1) if total > 0 else 0,
        }
        for subj, mins in subject_minutes.items()
    ]


def get_achievements(db: Session, child_id: int) -> list:
    earned = db.query(Achievement).filter(Achievement.child_id == child_id).all()
    earned_types = {a.type for a in earned}

    result = []
    for atype, defn in ACHIEVEMENT_DEFINITIONS.items():
        entry = {
            "type": atype,
            "title": defn["title"],
            "description": defn["description"],
            "icon": defn["icon"],
            "earned": atype in earned_types,
            "earned_at": None,
        }
        if atype in earned_types:
            ach = next(a for a in earned if a.type == atype)
            entry["earned_at"] = ach.earned_at.isoformat()
        result.append(entry)

    return result


def check_and_award_achievements(db: Session, child_id: int) -> list:
    newly_awarded = []
    earned_types = {a.type for a in db.query(Achievement).filter(Achievement.child_id == child_id).all()}

    def _award(atype: str, metadata: Optional[dict] = None):
        if atype in earned_types:
            return
        defn = ACHIEVEMENT_DEFINITIONS[atype]
        ach = Achievement(
            child_id=child_id,
            type=atype,
            title=defn["title"],
            description=defn["description"],
            icon=defn["icon"],
            extra_data=metadata,
        )
        db.add(ach)
        newly_awarded.append(atype)

    all_sessions = db.query(LearningSession).filter(LearningSession.child_id == child_id).all()
    completed_sessions = [s for s in all_sessions if s.completed]

    # first_lesson
    if completed_sessions:
        _award("first_lesson")

    # speed_learner: 3+ completed lessons in one day
    today = datetime.now(timezone.utc).date()
    today_completed = [
        s for s in completed_sessions
        if s.started_at.replace(tzinfo=timezone.utc).date() == today
    ]
    if len(today_completed) >= 3:
        _award("speed_learner")

    # week_streak: 5+ consecutive days with at least one completed lesson
    streak = _calculate_streak(db, child_id)
    if streak >= 5:
        _award("week_streak")

    # subject_master: 80%+ accuracy in 10+ completed lessons of same subject
    subject_stats: dict[str, dict] = {}
    for s in completed_sessions:
        if s.subject not in subject_stats:
            subject_stats[s.subject] = {"correct": 0, "total": 0, "count": 0}
        subject_stats[s.subject]["correct"] += s.questions_correct
        subject_stats[s.subject]["total"] += s.questions_total
        subject_stats[s.subject]["count"] += 1

    for subj, stats in subject_stats.items():
        if stats["count"] >= 10 and stats["total"] > 0:
            acc = stats["correct"] / stats["total"] * 100
            if acc >= 80:
                _award("subject_master", {"subject": subj})

    # correct_streak: total correct in any single session >= 10
    for s in completed_sessions:
        if s.questions_correct >= 10 and s.questions_total > 0:
            _award("correct_streak")
            break

    if newly_awarded:
        db.commit()

    return newly_awarded


def get_or_create_goal(db: Session, child_id: int) -> DailyGoal:
    goal = _get_active_goal(db, child_id)
    if not goal:
        goal = DailyGoal(child_id=child_id, target_minutes=15)
        db.add(goal)
        db.commit()
        db.refresh(goal)
    return goal


def set_daily_goal(db: Session, child_id: int, target_minutes: int) -> DailyGoal:
    db.query(DailyGoal).filter(
        DailyGoal.child_id == child_id,
        DailyGoal.active == True,
    ).update({"active": False})

    goal = DailyGoal(child_id=child_id, target_minutes=target_minutes)
    db.add(goal)
    db.commit()
    db.refresh(goal)
    return goal


def _get_active_goal(db: Session, child_id: int) -> Optional[DailyGoal]:
    return (
        db.query(DailyGoal)
        .filter(DailyGoal.child_id == child_id, DailyGoal.active == True)
        .order_by(DailyGoal.created_at.desc())
        .first()
    )


def _calculate_streak(db: Session, child_id: int) -> int:
    now = datetime.now(timezone.utc)
    streak = 0

    for i in range(365):
        day = now - timedelta(days=i)
        day_start = datetime(day.year, day.month, day.day, tzinfo=timezone.utc)
        day_end = day_start + timedelta(days=1)

        count = (
            db.query(LearningSession)
            .filter(
                LearningSession.child_id == child_id,
                LearningSession.completed == True,
                LearningSession.started_at >= day_start,
                LearningSession.started_at < day_end,
            )
            .count()
        )

        if count > 0:
            streak += 1
        else:
            break

    return streak
