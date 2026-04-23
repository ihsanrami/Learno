import enum
from datetime import datetime, timezone

from sqlalchemy import Boolean, DateTime, Enum, ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

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


class RefreshToken(Base):
    __tablename__ = "refresh_tokens"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    parent_id: Mapped[int] = mapped_column(Integer, ForeignKey("parents.id"), nullable=False)
    token_hash: Mapped[str] = mapped_column(String, unique=True, index=True, nullable=False)
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    revoked: Mapped[bool] = mapped_column(Boolean, default=False)

    parent: Mapped["Parent"] = relationship("Parent", back_populates="refresh_tokens")
