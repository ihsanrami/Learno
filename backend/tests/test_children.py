"""Tests for children management endpoints."""


def _register_and_login(client, email, password="Password1!", full_name="Parent"):
    client.post("/api/v1/auth/register", json={
        "email": email,
        "password": password,
        "full_name": full_name,
    })
    resp = client.post("/api/v1/auth/login", json={"email": email, "password": password})
    return resp.json()["access_token"]


def _auth(token):
    return {"Authorization": f"Bearer {token}"}


# ── Create child ──────────────────────────────────────────────────────────────

def test_create_child_success(client):
    token = _register_and_login(client, "parent@example.com")
    resp = client.post("/api/v1/children/", json={
        "name": "Ali",
        "age": 6,
        "grade": "first",
        "avatar": "fox",
    }, headers=_auth(token))
    assert resp.status_code == 201
    data = resp.json()
    assert data["name"] == "Ali"
    assert data["age"] == 6
    assert data["grade"] == "first"


# ── Auth guard ────────────────────────────────────────────────────────────────

def test_list_children_no_token(client):
    resp = client.get("/api/v1/children/")
    assert resp.status_code == 401


# ── Validation ────────────────────────────────────────────────────────────────

def test_create_child_invalid_age(client):
    # age field has le=10; age=11 must be rejected by Pydantic with 422
    token = _register_and_login(client, "parent2@example.com")
    resp = client.post("/api/v1/children/", json={
        "name": "Sara",
        "age": 11,
        "grade": "first",
    }, headers=_auth(token))
    assert resp.status_code == 422


# ── Isolation ─────────────────────────────────────────────────────────────────

def test_parent_isolation(client):
    token_a = _register_and_login(client, "parentA@example.com")
    token_b = _register_and_login(client, "parentB@example.com")

    # Parent A creates a child
    client.post("/api/v1/children/", json={
        "name": "ChildOfA",
        "age": 7,
        "grade": "second",
    }, headers=_auth(token_a))

    # Parent B must not see Parent A's child
    resp = client.get("/api/v1/children/", headers=_auth(token_b))
    assert resp.status_code == 200
    names = [c["name"] for c in resp.json()]
    assert "ChildOfA" not in names
