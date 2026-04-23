"""Integration tests for /api/v1/auth endpoints."""
import pytest


API = "/api/v1/auth"

VALID_PARENT = {
    "email": "parent@example.com",
    "password": "Secure123!",
    "full_name": "Test Parent",
}


# ---------- register ----------

def test_register_success(client):
    r = client.post(f"{API}/register", json=VALID_PARENT)
    assert r.status_code == 201
    data = r.json()
    assert data["email"] == VALID_PARENT["email"]
    assert data["full_name"] == VALID_PARENT["full_name"]
    assert "hashed_password" not in data


def test_register_duplicate_email(client):
    client.post(f"{API}/register", json=VALID_PARENT)
    r = client.post(f"{API}/register", json=VALID_PARENT)
    assert r.status_code == 409


def test_register_invalid_email(client):
    payload = {**VALID_PARENT, "email": "not-an-email"}
    r = client.post(f"{API}/register", json=payload)
    assert r.status_code == 422


def test_register_short_password(client):
    payload = {**VALID_PARENT, "email": "other@example.com", "password": "short"}
    r = client.post(f"{API}/register", json=payload)
    assert r.status_code == 422


def test_register_missing_full_name(client):
    payload = {"email": "x@example.com", "password": "password123"}
    r = client.post(f"{API}/register", json=payload)
    assert r.status_code == 422


# ---------- login ----------

def test_login_success(client):
    client.post(f"{API}/register", json=VALID_PARENT)
    r = client.post(f"{API}/login", json={"email": VALID_PARENT["email"], "password": VALID_PARENT["password"]})
    assert r.status_code == 200
    data = r.json()
    assert "access_token" in data
    assert "refresh_token" in data
    assert data["token_type"] == "bearer"


def test_login_wrong_password(client):
    client.post(f"{API}/register", json=VALID_PARENT)
    r = client.post(f"{API}/login", json={"email": VALID_PARENT["email"], "password": "wrongpass"})
    assert r.status_code == 401


def test_login_unknown_email(client):
    r = client.post(f"{API}/login", json={"email": "unknown@example.com", "password": "password123"})
    assert r.status_code == 401


def test_login_missing_fields(client):
    r = client.post(f"{API}/login", json={"email": "x@example.com"})
    assert r.status_code == 422


# ---------- refresh ----------

def _register_and_login(client):
    client.post(f"{API}/register", json=VALID_PARENT)
    r = client.post(f"{API}/login", json={"email": VALID_PARENT["email"], "password": VALID_PARENT["password"]})
    return r.json()


def test_refresh_returns_new_tokens(client):
    tokens = _register_and_login(client)
    r = client.post(f"{API}/refresh", json={"refresh_token": tokens["refresh_token"]})
    assert r.status_code == 200
    new_tokens = r.json()
    assert "access_token" in new_tokens
    assert new_tokens["access_token"] != tokens["access_token"]


def test_refresh_token_rotation(client):
    tokens = _register_and_login(client)
    r = client.post(f"{API}/refresh", json={"refresh_token": tokens["refresh_token"]})
    assert r.status_code == 200
    # Old refresh token should be revoked
    r2 = client.post(f"{API}/refresh", json={"refresh_token": tokens["refresh_token"]})
    assert r2.status_code == 401


def test_refresh_invalid_token(client):
    r = client.post(f"{API}/refresh", json={"refresh_token": "totally-fake-token"})
    assert r.status_code == 401


# ---------- logout ----------

def test_logout_success(client):
    tokens = _register_and_login(client)
    r = client.post(f"{API}/logout", json={"refresh_token": tokens["refresh_token"]})
    assert r.status_code == 204


def test_logout_then_refresh_fails(client):
    tokens = _register_and_login(client)
    client.post(f"{API}/logout", json={"refresh_token": tokens["refresh_token"]})
    r = client.post(f"{API}/refresh", json={"refresh_token": tokens["refresh_token"]})
    assert r.status_code == 401


# ---------- /me ----------

def test_me_authenticated(client):
    tokens = _register_and_login(client)
    r = client.get(f"{API}/me", headers={"Authorization": f"Bearer {tokens['access_token']}"})
    assert r.status_code == 200
    data = r.json()
    assert data["email"] == VALID_PARENT["email"]


def test_me_unauthenticated(client):
    r = client.get(f"{API}/me")
    assert r.status_code == 401


def test_me_invalid_token(client):
    r = client.get(f"{API}/me", headers={"Authorization": "Bearer invalid.jwt.token"})
    assert r.status_code == 401
