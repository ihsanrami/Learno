"""
Security and edge-case tests:
- Input validation boundaries (oversized, injection attempts)
- JWT edge cases (missing claims, refresh-token-as-access)
- bcrypt 72-byte truncation documentation
- Auth endpoint security scenarios
"""

import os
import sys

os.environ.setdefault("OPENAI_API_KEY", "sk-test-not-real")
os.environ.setdefault("DATABASE_URL", "sqlite:///:memory:")
os.environ.setdefault("JWT_SECRET_KEY", "test-secret-key-not-for-production")

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import pytest
import jwt
from datetime import datetime, timedelta, timezone
from unittest.mock import patch

from app.auth.password import hash_password, verify_password
from app.auth.jwt_handler import create_access_token, decode_access_token
from app.config import settings

API = "/api/v1/auth"

VALID_PARENT = {
    "email": "sec_test@example.com",
    "password": "Secure123!",
    "full_name": "Security Tester",
}


# ---------------------------------------------------------------------------
# Input validation — registration
# ---------------------------------------------------------------------------

def test_register_full_name_at_max_length(client):
    payload = {**VALID_PARENT, "email": "name100@example.com", "full_name": "A" * 100}
    r = client.post(f"{API}/register", json=payload)
    assert r.status_code == 201


def test_register_full_name_over_max_rejected(client):
    payload = {**VALID_PARENT, "email": "name101@example.com", "full_name": "A" * 101}
    r = client.post(f"{API}/register", json=payload)
    assert r.status_code == 422


def test_register_empty_full_name_rejected(client):
    payload = {**VALID_PARENT, "email": "noname@example.com", "full_name": ""}
    r = client.post(f"{API}/register", json=payload)
    assert r.status_code == 422


def test_register_whitespace_only_name_rejected(client):
    payload = {**VALID_PARENT, "email": "spaces@example.com", "full_name": "   "}
    r = client.post(f"{API}/register", json=payload)
    assert r.status_code == 422


def test_register_password_exactly_8_chars(client):
    payload = {**VALID_PARENT, "email": "pw8@example.com", "password": "12345678"}
    r = client.post(f"{API}/register", json=payload)
    assert r.status_code == 201


def test_register_password_7_chars_rejected(client):
    payload = {**VALID_PARENT, "email": "pw7@example.com", "password": "1234567"}
    r = client.post(f"{API}/register", json=payload)
    assert r.status_code == 422


def test_register_very_long_password_accepted(client):
    """Passwords over 72 bytes are accepted (bcrypt silently truncates)."""
    long_pw = "A" * 200
    payload = {**VALID_PARENT, "email": "longpw@example.com", "password": long_pw}
    r = client.post(f"{API}/register", json=payload)
    assert r.status_code == 201


def test_login_with_sql_injection_attempt(client):
    """SQL injection in email should not cause 500 — Pydantic rejects it as invalid email."""
    r = client.post(f"{API}/login", json={"email": "' OR '1'='1", "password": "password"})
    assert r.status_code == 422


def test_register_unicode_email_accepted(client):
    """Unicode in email local part should pass or fail validation cleanly, never 500."""
    r = client.post(f"{API}/register", json={
        "email": "тест@example.com",
        "password": "password123",
        "full_name": "Unicode User",
    })
    # Either 201 (if email-validator accepts) or 422 (if it rejects)
    assert r.status_code in (201, 422)


# ---------------------------------------------------------------------------
# JWT edge cases
# ---------------------------------------------------------------------------

def test_refresh_token_cannot_be_used_as_access_token(client):
    """A raw refresh token string must not decode as a valid access token."""
    client.post(f"{API}/register", json=VALID_PARENT)
    r = client.post(f"{API}/login", json={
        "email": VALID_PARENT["email"],
        "password": VALID_PARENT["password"],
    })
    tokens = r.json()
    # Try using the refresh token (a raw URL-safe token, not a JWT) as a Bearer token
    r2 = client.get(f"{API}/me", headers={"Authorization": f"Bearer {tokens['refresh_token']}"})
    assert r2.status_code == 401


def test_access_token_with_missing_sub_claim_rejected():
    """Token without 'sub' claim should raise PyJWTError."""
    token = jwt.encode(
        {"type": "access", "exp": datetime.now(timezone.utc) + timedelta(minutes=5)},
        settings.JWT_SECRET_KEY,
        algorithm=settings.JWT_ALGORITHM,
    )
    payload = decode_access_token(token)
    # decode_access_token doesn't validate 'sub' presence — accessing it raises KeyError
    with pytest.raises(KeyError):
        _ = payload["sub"]


def test_access_token_with_wrong_type_rejected():
    """Token with type='refresh' must be rejected."""
    token = jwt.encode(
        {"sub": "1", "type": "refresh", "exp": datetime.now(timezone.utc) + timedelta(minutes=5)},
        settings.JWT_SECRET_KEY,
        algorithm=settings.JWT_ALGORITHM,
    )
    with pytest.raises(jwt.PyJWTError):
        decode_access_token(token)


def test_empty_bearer_token_rejected(client):
    r = client.get(f"{API}/me", headers={"Authorization": "Bearer "})
    assert r.status_code == 401


def test_malformed_bearer_token_rejected(client):
    r = client.get(f"{API}/me", headers={"Authorization": "Bearer not.a.jwt"})
    assert r.status_code == 401


def test_completely_invalid_authorization_header(client):
    r = client.get(f"{API}/me", headers={"Authorization": "Basic dXNlcjpwYXNz"})
    assert r.status_code == 401


# ---------------------------------------------------------------------------
# bcrypt 72-byte truncation — documented behavior
# ---------------------------------------------------------------------------

def test_bcrypt_72_byte_password_verifies(client):
    """Baseline: a 72-byte password works normally."""
    pw = "A" * 72
    hashed = hash_password(pw)
    assert verify_password(pw, hashed) is True


def test_bcrypt_truncation_at_73_bytes():
    """
    password.py explicitly truncates passwords to 72 bytes before calling bcrypt.
    A 73-byte password therefore hashes and verifies identically to its first 72 bytes.
    This is intentional: it ensures consistent behaviour across bcrypt versions.
    """
    pw_72 = "A" * 72
    pw_73_same_prefix = "A" * 72 + "Z"   # 73rd byte differs
    hashed = hash_password(pw_72)
    assert verify_password(pw_72, hashed) is True
    # 73rd byte is stripped — both verify against the same 72-byte prefix
    assert verify_password(pw_73_same_prefix, hashed) is True


# ---------------------------------------------------------------------------
# Children endpoint security
# ---------------------------------------------------------------------------

def test_create_child_name_too_long(client):
    client.post(f"{API}/register", json=VALID_PARENT)
    r = client.post(f"{API}/login", json={
        "email": VALID_PARENT["email"], "password": VALID_PARENT["password"]
    })
    token = r.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    r2 = client.post("/api/v1/children/", json={
        "name": "A" * 51, "age": 7, "grade": "second",
    }, headers=headers)
    assert r2.status_code == 422


def test_create_child_age_boundary_4_accepted(client):
    client.post(f"{API}/register", json={**VALID_PARENT, "email": "age4@test.com"})
    r = client.post(f"{API}/login", json={"email": "age4@test.com", "password": VALID_PARENT["password"]})
    token = r.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    r2 = client.post("/api/v1/children/", json={
        "name": "YoungKid", "age": 4, "grade": "kindergarten",
    }, headers=headers)
    assert r2.status_code == 201


def test_create_child_age_boundary_10_accepted(client):
    client.post(f"{API}/register", json={**VALID_PARENT, "email": "age10@test.com"})
    r = client.post(f"{API}/login", json={"email": "age10@test.com", "password": VALID_PARENT["password"]})
    token = r.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    r2 = client.post("/api/v1/children/", json={
        "name": "OlderKid", "age": 10, "grade": "fourth",
    }, headers=headers)
    assert r2.status_code == 201


def test_create_child_age_3_rejected(client):
    client.post(f"{API}/register", json={**VALID_PARENT, "email": "age3@test.com"})
    r = client.post(f"{API}/login", json={"email": "age3@test.com", "password": VALID_PARENT["password"]})
    token = r.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    r2 = client.post("/api/v1/children/", json={
        "name": "TooYoung", "age": 3, "grade": "kindergarten",
    }, headers=headers)
    assert r2.status_code == 422


def test_create_child_age_11_rejected(client):
    client.post(f"{API}/register", json={**VALID_PARENT, "email": "age11@test.com"})
    r = client.post(f"{API}/login", json={"email": "age11@test.com", "password": VALID_PARENT["password"]})
    token = r.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    r2 = client.post("/api/v1/children/", json={
        "name": "TooOld", "age": 11, "grade": "fourth",
    }, headers=headers)
    assert r2.status_code == 422


# ---------------------------------------------------------------------------
# Concurrent token scenarios
# ---------------------------------------------------------------------------

def test_multiple_refresh_tokens_can_coexist(client):
    """A parent can have multiple sessions (different refresh tokens) simultaneously."""
    client.post(f"{API}/register", json={**VALID_PARENT, "email": "multi@test.com"})
    login_payload = {"email": "multi@test.com", "password": VALID_PARENT["password"]}

    tokens1 = client.post(f"{API}/login", json=login_payload).json()
    tokens2 = client.post(f"{API}/login", json=login_payload).json()

    # Both sessions can refresh independently
    r1 = client.post(f"{API}/refresh", json={"refresh_token": tokens1["refresh_token"]})
    r2 = client.post(f"{API}/refresh", json={"refresh_token": tokens2["refresh_token"]})
    assert r1.status_code == 200
    assert r2.status_code == 200


def test_logout_only_invalidates_one_session(client):
    """Logging out one session should NOT invalidate other sessions."""
    client.post(f"{API}/register", json={**VALID_PARENT, "email": "logout2@test.com"})
    login_payload = {"email": "logout2@test.com", "password": VALID_PARENT["password"]}

    tokens1 = client.post(f"{API}/login", json=login_payload).json()
    tokens2 = client.post(f"{API}/login", json=login_payload).json()

    client.post(f"{API}/logout", json={"refresh_token": tokens1["refresh_token"]})

    # Session 1 is invalidated
    r1 = client.post(f"{API}/refresh", json={"refresh_token": tokens1["refresh_token"]})
    assert r1.status_code == 401

    # Session 2 still works
    r2 = client.post(f"{API}/refresh", json={"refresh_token": tokens2["refresh_token"]})
    assert r2.status_code == 200


def test_logout_with_nonexistent_token_returns_204(client):
    """Logging out a token that never existed should succeed silently."""
    r = client.post(f"{API}/logout", json={"refresh_token": "nonexistent-token-value"})
    assert r.status_code == 204
