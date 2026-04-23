from datetime import datetime, timezone

from sqlalchemy.orm import Session

from app.auth.models import ChildProfile, Parent, RefreshToken
from app.auth.password import hash_password, verify_password
from app.auth.jwt_handler import create_access_token, create_refresh_token, hash_refresh_token
from app.auth.schemas import ChildCreate, ChildUpdate, ParentRegister, TokenPair


class AuthError(Exception):
    pass


def register_parent(db: Session, data: ParentRegister) -> Parent:
    if db.query(Parent).filter(Parent.email == data.email).first():
        raise AuthError("Email already registered")
    parent = Parent(
        email=data.email,
        hashed_password=hash_password(data.password),
        full_name=data.full_name,
    )
    db.add(parent)
    db.commit()
    db.refresh(parent)
    return parent


def login_parent(db: Session, email: str, password: str) -> tuple[Parent, TokenPair]:
    parent = db.query(Parent).filter(Parent.email == email).first()
    if not parent or not verify_password(password, parent.hashed_password):
        raise AuthError("Invalid email or password")

    parent.last_login = datetime.now(timezone.utc)
    db.commit()

    raw_refresh, token_hash, expires_at = create_refresh_token()
    rt = RefreshToken(parent_id=parent.id, token_hash=token_hash, expires_at=expires_at)
    db.add(rt)
    db.commit()

    tokens = TokenPair(
        access_token=create_access_token(parent.id),
        refresh_token=raw_refresh,
    )
    return parent, tokens


def refresh_access_token(db: Session, raw_refresh: str) -> TokenPair:
    token_hash = hash_refresh_token(raw_refresh)
    rt = db.query(RefreshToken).filter(
        RefreshToken.token_hash == token_hash,
        RefreshToken.revoked == False,
    ).first()

    if not rt:
        raise AuthError("Invalid refresh token")
    if rt.expires_at.replace(tzinfo=timezone.utc) < datetime.now(timezone.utc):
        raise AuthError("Refresh token expired")

    # Token rotation: revoke old, issue new
    rt.revoked = True
    new_raw, new_hash, new_expires = create_refresh_token()
    new_rt = RefreshToken(parent_id=rt.parent_id, token_hash=new_hash, expires_at=new_expires)
    db.add(new_rt)
    db.commit()

    return TokenPair(
        access_token=create_access_token(rt.parent_id),
        refresh_token=new_raw,
    )


def logout_parent(db: Session, raw_refresh: str) -> None:
    token_hash = hash_refresh_token(raw_refresh)
    rt = db.query(RefreshToken).filter(RefreshToken.token_hash == token_hash).first()
    if rt:
        rt.revoked = True
        db.commit()


# ---------- Children ----------

def list_children(db: Session, parent_id: int) -> list[ChildProfile]:
    return db.query(ChildProfile).filter(ChildProfile.parent_id == parent_id).all()


def get_child(db: Session, child_id: int, parent_id: int) -> ChildProfile:
    child = db.query(ChildProfile).filter(
        ChildProfile.id == child_id,
        ChildProfile.parent_id == parent_id,
    ).first()
    if not child:
        raise AuthError("Child not found")
    return child


def create_child(db: Session, parent_id: int, data: ChildCreate) -> ChildProfile:
    child = ChildProfile(
        parent_id=parent_id,
        name=data.name,
        age=data.age,
        grade=data.grade,
        avatar=data.avatar,
    )
    db.add(child)
    db.commit()
    db.refresh(child)
    return child


def update_child(db: Session, child_id: int, parent_id: int, data: ChildUpdate) -> ChildProfile:
    child = get_child(db, child_id, parent_id)
    for field, value in data.model_dump(exclude_none=True).items():
        setattr(child, field, value)
    db.commit()
    db.refresh(child)
    return child


def delete_child(db: Session, child_id: int, parent_id: int) -> None:
    child = get_child(db, child_id, parent_id)
    db.delete(child)
    db.commit()
