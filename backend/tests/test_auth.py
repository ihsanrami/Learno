"""Tests for authentication endpoints and password utilities."""

from app.auth.password import hash_password, verify_password


def _register(client, email="user@test.com", password="Password1!", full_name="Test User"):
    return client.post("/api/v1/auth/register", json={
        "email": email,
        "password": password,
        "full_name": full_name,
    })


def _login(client, email="user@test.com", password="Password1!"):
    return client.post("/api/v1/auth/login", json={
        "email": email,
        "password": password,
    })


# ── Register ──────────────────────────────────────────────────────────────────

def test_register_parent_success(client):
    resp = _register(client)
    assert resp.status_code == 201
    data = resp.json()
    assert data["email"] == "user@test.com"
    assert data["full_name"] == "Test User"
    assert "id" in data
    assert "hashed_password" not in data


def test_register_duplicate_email(client):
    _register(client)
    resp = _register(client)  # same email second time
    assert resp.status_code == 409


def test_register_short_password(client):
    # min_length=8 in ParentRegister — 7-char password must be rejected
    resp = _register(client, password="1234567")
    assert resp.status_code == 422


# ── Login ─────────────────────────────────────────────────────────────────────

def test_login_success(client):
    _register(client)
    resp = _login(client)
    assert resp.status_code == 200
    data = resp.json()
    assert "access_token" in data
    assert "refresh_token" in data
    assert data["token_type"] == "bearer"


def test_login_wrong_password(client):
    _register(client)
    resp = _login(client, password="WrongPassword!")
    assert resp.status_code == 401


# ── Password utilities (unit test — no HTTP) ──────────────────────────────────

def test_hash_and_verify_password():
    plain = "MySecret42!"
    hashed = hash_password(plain)
    assert hashed != plain
    assert verify_password(plain, hashed)
    assert not verify_password("WrongPassword", hashed)


# ── Refresh token rotation ────────────────────────────────────────────────────

def test_refresh_token_rotation(client):
    _register(client)
    login_resp = _login(client)
    assert login_resp.status_code == 200
    tokens = login_resp.json()

    # Use the refresh token to get new tokens
    resp = client.post("/api/v1/auth/refresh", json={
        "refresh_token": tokens["refresh_token"],
    })
    assert resp.status_code == 200
    new_tokens = resp.json()
    assert "access_token" in new_tokens
    assert "refresh_token" in new_tokens

    # Old refresh token is now revoked — second use must be rejected
    resp2 = client.post("/api/v1/auth/refresh", json={
        "refresh_token": tokens["refresh_token"],
    })
    assert resp2.status_code == 401
