from datetime import datetime
from typing import Literal

from pydantic import BaseModel, EmailStr, Field, field_validator, model_validator


# ---------- Auth ----------

class ParentRegister(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8)
    full_name: str = Field(min_length=1, max_length=100)

    @field_validator("full_name", mode="before")
    @classmethod
    def full_name_not_blank(cls, v: str) -> str:
        if not str(v).strip():
            raise ValueError("full_name must not be blank or whitespace-only")
        return v


class ParentLogin(BaseModel):
    email: EmailStr
    password: str


class TokenPair(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class AccessToken(BaseModel):
    access_token: str
    token_type: str = "bearer"


class RefreshRequest(BaseModel):
    refresh_token: str


class ParentOut(BaseModel):
    id: int
    email: str
    full_name: str
    email_verified: bool
    created_at: datetime
    last_login: datetime | None

    model_config = {"from_attributes": True}


# ---------- Children ----------

class ChildCreate(BaseModel):
    name: str = Field(min_length=1, max_length=50)
    age: int = Field(ge=4, le=10)
    grade: Literal["kindergarten", "first", "second", "third", "fourth"]
    avatar: str = Field(default="fox", max_length=50)


class ChildUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=50)
    age: int | None = Field(default=None, ge=4, le=10)
    grade: Literal["kindergarten", "first", "second", "third", "fourth"] | None = None
    avatar: str | None = Field(default=None, max_length=50)


class ChildOut(BaseModel):
    id: int
    parent_id: int
    name: str
    age: int
    grade: str
    avatar: str
    created_at: datetime

    model_config = {"from_attributes": True}
