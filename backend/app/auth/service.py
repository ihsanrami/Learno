import hashlib
import logging
import random
import secrets
from datetime import datetime, timedelta, timezone

from sqlalchemy.orm import Session

from app.auth.models import ChildProfile, Parent, PasswordResetToken, RefreshToken
from app.auth.password import hash_password, verify_password
from app.auth.jwt_handler import (
    create_access_token,
    create_refresh_token,
    create_reset_token,
    decode_reset_token,
    hash_refresh_token,
)
from app.auth.schemas import ChildCreate, ChildUpdate, ParentRegister, TokenPair
from app.config import settings

logger = logging.getLogger(__name__)


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


# ---------- Password reset ----------

def _hash_reset_code(code: str) -> str:
    return hashlib.sha256(code.encode()).hexdigest()


def request_password_reset(db: Session, email: str) -> tuple[str, str | None, str | None]:
    """
    Returns (public_message, raw_code_for_email_or_None, debug_code_or_None).
    - raw_code_for_email_or_None: plaintext code when a parent was found (for email dispatch)
    - debug_code_or_None: same code only when DEBUG=True (included in API response)
    Always returns the same public_message to prevent email enumeration.
    """
    _SAFE_MESSAGE = "If this email is registered, you'll receive a reset code."
    raw_code: str | None = None
    debug_code: str | None = None

    parent = db.query(Parent).filter(Parent.email == email).first()
    if parent:
        # Invalidate any existing unused tokens for this parent
        db.query(PasswordResetToken).filter(
            PasswordResetToken.parent_id == parent.id,
            PasswordResetToken.used == False,  # noqa: E712
        ).update({"used": True})
        db.flush()

        raw_code = f"{random.SystemRandom().randint(0, 999999):06d}"
        token_hash = _hash_reset_code(raw_code)
        expires_at = datetime.now(timezone.utc) + timedelta(
            minutes=settings.PASSWORD_RESET_CODE_EXPIRE_MINUTES
        )

        reset_token = PasswordResetToken(
            parent_id=parent.id,
            token_hash=token_hash,
            expires_at=expires_at,
        )
        db.add(reset_token)
        db.commit()

        if settings.DEBUG:
            debug_code = raw_code

        logger.info("Password reset requested for parent_id=%d", parent.id)

    return _SAFE_MESSAGE, raw_code, debug_code


def verify_reset_code(db: Session, email: str, code: str) -> str:
    """
    Validates the code. Raises AuthError on failure.
    Returns a short-lived reset JWT on success.
    """
    logger.info("verify_reset_code called: email=%r code_len=%d code_repr=%r",
                email, len(code), code)

    parent = db.query(Parent).filter(Parent.email == email).first()
    if not parent:
        logger.warning("verify_reset_code: no parent found for email=%r", email)
        raise AuthError("Invalid or expired code")

    token_hash = _hash_reset_code(code)
    logger.info("verify_reset_code: parent_id=%d hash_prefix=%s", parent.id, token_hash[:16])

    reset_token = db.query(PasswordResetToken).filter(
        PasswordResetToken.parent_id == parent.id,
        PasswordResetToken.token_hash == token_hash,
        PasswordResetToken.used == False,  # noqa: E712
    ).first()

    if not reset_token:
        # Log all unused tokens to make hash mismatches visible
        unused = db.query(PasswordResetToken).filter(
            PasswordResetToken.parent_id == parent.id,
            PasswordResetToken.used == False,
        ).all()
        logger.warning(
            "verify_reset_code: hash not matched. submitted_hash_prefix=%s "
            "unused_token_hashes=%s",
            token_hash[:16],
            [t.token_hash[:16] for t in unused],
        )
        raise AuthError("Invalid or expired code")

    expires_aware = (
        reset_token.expires_at.replace(tzinfo=timezone.utc)
        if reset_token.expires_at.tzinfo is None
        else reset_token.expires_at
    )
    now_utc = datetime.now(timezone.utc)
    if expires_aware < now_utc:
        logger.warning("verify_reset_code: token expired (expires=%s now=%s)", expires_aware, now_utc)
        raise AuthError("Invalid or expired code")

    reset_token.used = True
    db.commit()
    logger.info("verify_reset_code: SUCCESS for parent_id=%d", parent.id)
    return create_reset_token(parent.id, reset_token.id)


def reset_password(db: Session, reset_token_jwt: str, new_password: str) -> None:
    """Decodes the reset JWT and updates the parent's password."""
    import jwt as pyjwt

    try:
        payload = decode_reset_token(reset_token_jwt)
    except pyjwt.PyJWTError:
        raise AuthError("Invalid or expired reset token")

    parent_id = int(payload["sub"])
    parent = db.query(Parent).filter(Parent.id == parent_id).first()
    if not parent:
        raise AuthError("Invalid or expired reset token")

    parent.hashed_password = hash_password(new_password)
    db.commit()
    logger.info("Password reset completed for parent_id=%d", parent_id)
