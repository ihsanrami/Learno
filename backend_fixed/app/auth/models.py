import enum
from datetime import datetime, timezone

from sqlalchemy import Boolean, DateTime, Enum, ForeignKey, Index, Integer, JSON, String
from sqlalchemy.orm import Mapped, mapped_column, relationship
from typing import Optional

from app.database.base import Base


class GradeEnum(str, enum.Enum):
    kindergarten = "kindergarten"
    first = "first"
    second = "second"
    third = "third"
    fourth = "fourth"


class Parent(Base):
    __tablename__ = "parents"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    email: Mapped[str] = mapped_column(String, unique=True, index=True, nullable=False)
    hashed_password: Mapped[str] = mapped_column(String, nullable=False)
    full_name: Mapped[str] = mapped_column(String, nullable=False)
    email_verified: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )
    last_login: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    children: Mapped[list["ChildProfile"]] = relationship("ChildProfile", back_populates="parent", cascade="all, delete-orphan")
    refresh_tokens: Mapped[list["RefreshToken"]] = relationship("RefreshToken", back_populates="parent", cascade="all, delete-orphan")


class ChildProfile(Base):
    __tablename__ = "child_profiles"
    __table_args__ = (
        Index("ix_child_profiles_parent_id", "parent_id"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    parent_id: Mapped[int] = mapped_column(Integer, ForeignKey("parents.id"), nullable=False)
    name: Mapped[str] = mapped_column(String, nullable=False)
    age: Mapped[int] = mapped_column(Integer, nullable=False)
    grade: Mapped[GradeEnum] = mapped_column(Enum(GradeEnum), nullable=False)
    avatar: Mapped[str] = mapped_column(String, default="fox")
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )

    parent: Mapped["Parent"] = relationship("Parent", back_populates="children")
    learning_sessions: Mapped[list["LearningSession"]] = relationship(
        "LearningSession", back_populates="child", cascade="all, delete-orphan"
    )
    daily_goals: Mapped[list["DailyGoal"]] = relationship(
        "DailyGoal", back_populates="child", cascade="all, delete-orphan"
    )
    achievements: Mapped[list["Achievement"]] = relationship(
        "Achievement", back_populates="child", cascade="all, delete-orphan"
    )


class LearningSession(Base):
    __tablename__ = "learning_sessions"
    __table_args__ = (
        Index("ix_learning_sessions_child_id", "child_id"),
        Index("ix_learning_sessions_child_started", "child_id", "started_at"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    child_id: Mapped[int] = mapped_column(Integer, ForeignKey("child_profiles.id"), nullable=False)
    grade: Mapped[str] = mapped_column(String, nullable=False)
    subject: Mapped[str] = mapped_column(String, nullable=False)
    topic_id: Mapped[str] = mapped_column(String, nullable=False)
    started_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )
    ended_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    duration_seconds: Mapped[int] = mapped_column(Integer, default=0)
    questions_total: Mapped[int] = mapped_column(Integer, default=0)
    questions_correct: Mapped[int] = mapped_column(Integer, default=0)
    concepts_completed: Mapped[int] = mapped_column(Integer, default=0)
    concepts_total: Mapped[int] = mapped_column(Integer, default=5)
    completed: Mapped[bool] = mapped_column(Boolean, default=False)

    child: Mapped["ChildProfile"] = relationship("ChildProfile", back_populates="learning_sessions")


class DailyGoal(Base):
    __tablename__ = "daily_goals"
    __table_args__ = (
        Index("ix_daily_goals_child_id", "child_id"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    child_id: Mapped[int] = mapped_column(Integer, ForeignKey("child_profiles.id"), nullable=False)
    target_minutes: Mapped[int] = mapped_column(Integer, default=15)
    active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )

    child: Mapped["ChildProfile"] = relationship("ChildProfile", back_populates="daily_goals")


class Achievement(Base):
    __tablename__ = "achievements"
    __table_args__ = (
        Index("ix_achievements_child_id", "child_id"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    child_id: Mapped[int] = mapped_column(Integer, ForeignKey("child_profiles.id"), nullable=False)
    type: Mapped[str] = mapped_column(String, nullable=False)
    title: Mapped[str] = mapped_column(String, nullable=False)
    description: Mapped[str] = mapped_column(String, nullable=False)
    icon: Mapped[str] = mapped_column(String, nullable=False)
    earned_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )
    extra_data: Mapped[Optional[dict]] = mapped_column(JSON, nullable=True)

    child: Mapped["ChildProfile"] = relationship("ChildProfile", back_populates="achievements")


class RefreshToken(Base):
    __tablename__ = "refresh_tokens"
    __table_args__ = (
        Index("ix_refresh_tokens_expires_at", "expires_at"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    parent_id: Mapped[int] = mapped_column(Integer, ForeignKey("parents.id"), nullable=False)
    token_hash: Mapped[str] = mapped_column(String, unique=True, index=True, nullable=False)
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    revoked: Mapped[bool] = mapped_column(Boolean, default=False)

    parent: Mapped["Parent"] = relationship("Parent", back_populates="refresh_tokens")
