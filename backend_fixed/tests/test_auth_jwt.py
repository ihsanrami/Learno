"""Tests for JWT generation and verification."""
import time
from datetime import datetime, timedelta, timezone
from unittest.mock import patch

import jwt
import pytest

from app.auth.jwt_handler import (
    create_access_token,
    create_refresh_token,
    decode_access_token,
    hash_refresh_token,
)
from app.config import settings


def test_create_access_token_returns_string():
    token = create_access_token(parent_id=1)
    assert isinstance(token, str)
    assert len(token) > 0


def test_decode_access_token_returns_correct_sub():
    token = create_access_token(parent_id=42)
    payload = decode_access_token(token)
    assert payload["sub"] == "42"


def test_decode_access_token_has_type_access():
    token = create_access_token(parent_id=1)
    payload = decode_access_token(token)
    assert payload["type"] == "access"


def test_decode_expired_token_raises():
    with patch("app.auth.jwt_handler._utcnow") as mock_now:
        past = datetime.now(timezone.utc) - timedelta(minutes=30)
        mock_now.return_value = past
        token = create_access_token(parent_id=1)
    with pytest.raises(jwt.PyJWTError):
        decode_access_token(token)


def test_decode_tampered_token_raises():
    token = create_access_token(parent_id=1)
    tampered = token[:-5] + "XXXXX"
    with pytest.raises(jwt.PyJWTError):
        decode_access_token(tampered)


def test_decode_token_with_wrong_secret_raises():
    bad_token = jwt.encode(
        {"sub": "1", "type": "access", "exp": datetime.now(timezone.utc) + timedelta(minutes=5)},
        "wrong-secret",
        algorithm="HS256",
    )
    with pytest.raises(jwt.PyJWTError):
        decode_access_token(bad_token)


def test_decode_non_access_type_raises():
    payload = {
        "sub": "1",
        "type": "other",
        "exp": datetime.now(timezone.utc) + timedelta(minutes=5),
    }
    token = jwt.encode(payload, settings.JWT_SECRET_KEY, algorithm=settings.JWT_ALGORITHM)
    with pytest.raises(jwt.PyJWTError):
        decode_access_token(token)


def test_create_refresh_token_returns_three_values():
    raw, token_hash, expires_at = create_refresh_token()
    assert isinstance(raw, str)
    assert isinstance(token_hash, str)
    assert isinstance(expires_at, datetime)


def test_refresh_token_hash_is_deterministic():
    raw, token_hash, _ = create_refresh_token()
    assert hash_refresh_token(raw) == token_hash


def test_refresh_tokens_are_unique():
    raw1, hash1, _ = create_refresh_token()
    raw2, hash2, _ = create_refresh_token()
    assert raw1 != raw2
    assert hash1 != hash2


def test_refresh_token_expires_in_future():
    _, _, expires_at = create_refresh_token()
    assert expires_at > datetime.now(timezone.utc)


def test_refresh_token_expires_in_7_days():
    _, _, expires_at = create_refresh_token()
    delta = expires_at - datetime.now(timezone.utc)
    assert 6 <= delta.days <= 7
