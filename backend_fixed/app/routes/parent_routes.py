"""Parent panel routes — analytics, goals, achievements."""

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session
from typing import Optional

from app.auth.dependencies import get_current_parent
from app.auth.models import Parent
from app.auth import service as auth_service
from app.database.session import get_db
import app.services.analytics_service as analytics_svc

router = APIRouter(prefix="/parent", tags=["Parent Panel"])


def _assert_owns_child(db: Session, child_id: int, parent: Parent):
    try:
        auth_service.get_child(db, child_id, parent.id)
    except auth_service.AuthError:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")


# ---------------------------------------------------------------------------
# Dashboard
# ---------------------------------------------------------------------------

@router.get("/dashboard")
def get_dashboard(
    db: Session = Depends(get_db),
    parent: Parent = Depends(get_current_parent),
):
    children = auth_service.list_children(db, parent.id)
    result = []
    for child in children:
        overview = analytics_svc.get_child_overview(db, child.id)
        result.append({
            "id": child.id,
            "name": child.name,
            "age": child.age,
            "grade": child.grade.value if hasattr(child.grade, "value") else child.grade,
            "avatar": child.avatar,
            **overview,
        })
    return {"status": "success", "data": result}


# ---------------------------------------------------------------------------
# Child overview
# ---------------------------------------------------------------------------

@router.get("/children/{child_id}/overview")
def get_child_overview(
    child_id: int,
    db: Session = Depends(get_db),
    parent: Parent = Depends(get_current_parent),
):
    _assert_owns_child(db, child_id, parent)
    overview = analytics_svc.get_child_overview(db, child_id)
    return {"status": "success", "data": overview}


# ---------------------------------------------------------------------------
# Weekly activity
# ---------------------------------------------------------------------------

@router.get("/children/{child_id}/weekly")
def get_weekly_activity(
    child_id: int,
    db: Session = Depends(get_db),
    parent: Parent = Depends(get_current_parent),
):
    _assert_owns_child(db, child_id, parent)
    weekly = analytics_svc.get_weekly_activity(db, child_id)
    return {"status": "success", "data": weekly}


# ---------------------------------------------------------------------------
# Topics progress
# ---------------------------------------------------------------------------

@router.get("/children/{child_id}/topics")
def get_topics(
    child_id: int,
    db: Session = Depends(get_db),
    parent: Parent = Depends(get_current_parent),
):
    _assert_owns_child(db, child_id, parent)
    topics = analytics_svc.get_topics_mastered(db, child_id)
    return {"status": "success", "data": topics}


# ---------------------------------------------------------------------------
# Subject breakdown
# ---------------------------------------------------------------------------

@router.get("/children/{child_id}/subjects")
def get_subjects(
    child_id: int,
    db: Session = Depends(get_db),
    parent: Parent = Depends(get_current_parent),
):
    _assert_owns_child(db, child_id, parent)
    breakdown = analytics_svc.get_subject_breakdown(db, child_id)
    return {"status": "success", "data": breakdown}


# ---------------------------------------------------------------------------
# Achievements
# ---------------------------------------------------------------------------

@router.get("/children/{child_id}/achievements")
def get_achievements(
    child_id: int,
    db: Session = Depends(get_db),
    parent: Parent = Depends(get_current_parent),
):
    _assert_owns_child(db, child_id, parent)
    achievements = analytics_svc.get_achievements(db, child_id)
    return {"status": "success", "data": achievements}


# ---------------------------------------------------------------------------
# Daily goal
# ---------------------------------------------------------------------------

class GoalRequest(BaseModel):
    target_minutes: int = Field(..., ge=5, le=120)


@router.post("/children/{child_id}/goal")
def set_goal(
    child_id: int,
    body: GoalRequest,
    db: Session = Depends(get_db),
    parent: Parent = Depends(get_current_parent),
):
    _assert_owns_child(db, child_id, parent)
    goal = analytics_svc.set_daily_goal(db, child_id, body.target_minutes)
    return {"status": "success", "data": {"id": goal.id, "target_minutes": goal.target_minutes}}


@router.get("/children/{child_id}/goal")
def get_goal(
    child_id: int,
    db: Session = Depends(get_db),
    parent: Parent = Depends(get_current_parent),
):
    _assert_owns_child(db, child_id, parent)
    goal = analytics_svc.get_or_create_goal(db, child_id)
    overview = analytics_svc.get_child_overview(db, child_id)
    return {
        "status": "success",
        "data": {
            "target_minutes": goal.target_minutes,
            "today_minutes": overview["today_minutes"],
            "progress_percent": overview["goal_progress_percent"],
        },
    }
