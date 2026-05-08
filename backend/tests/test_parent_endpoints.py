"""Integration tests for /api/v1/parent endpoints."""
import pytest

AUTH_API = "/api/v1/auth"
CHILD_API = "/api/v1/children"
PARENT_API = "/api/v1/parent"

PARENT_A = {"email": "pa_parent@example.com", "password": "Password1!", "full_name": "Parent A"}
PARENT_B = {"email": "pb_parent@example.com", "password": "Password2!", "full_name": "Parent B"}
VALID_CHILD = {"name": "Ali", "age": 7, "grade": "second", "avatar": "fox"}


def _register_and_login(client, parent=PARENT_A):
    client.post(f"{AUTH_API}/register", json=parent)
    r = client.post(f"{AUTH_API}/login", json={"email": parent["email"], "password": parent["password"]})
    return r.json()["access_token"]


def _auth(token):
    return {"Authorization": f"Bearer {token}"}


def _setup(client, parent=PARENT_A):
    token = _register_and_login(client, parent)
    child = client.post(CHILD_API + "/", json=VALID_CHILD, headers=_auth(token)).json()
    return token, child["id"]


# ---------------------------------------------------------------------------
# Dashboard
# ---------------------------------------------------------------------------

def test_dashboard_requires_auth(client):
    r = client.get(f"{PARENT_API}/dashboard")
    assert r.status_code == 401


def test_dashboard_empty(client):
    token = _register_and_login(client)
    r = client.get(f"{PARENT_API}/dashboard", headers=_auth(token))
    assert r.status_code == 200
    assert r.json()["data"] == []


def test_dashboard_shows_children(client):
    token, child_id = _setup(client)
    r = client.get(f"{PARENT_API}/dashboard", headers=_auth(token))
    assert r.status_code == 200
    data = r.json()["data"]
    assert len(data) == 1
    assert data[0]["id"] == child_id
    assert data[0]["name"] == VALID_CHILD["name"]
    assert "today_minutes" in data[0]
    assert "streak_days" in data[0]


# ---------------------------------------------------------------------------
# Child overview
# ---------------------------------------------------------------------------

def test_child_overview_requires_auth(client):
    r = client.get(f"{PARENT_API}/children/1/overview")
    assert r.status_code == 401


def test_child_overview_success(client):
    token, child_id = _setup(client)
    r = client.get(f"{PARENT_API}/children/{child_id}/overview", headers=_auth(token))
    assert r.status_code == 200
    data = r.json()["data"]
    assert "today_minutes" in data
    assert "streak_days" in data
    assert "total_lessons" in data
    assert "overall_accuracy" in data


def test_child_overview_cross_parent_forbidden(client):
    token_a, child_id_a = _setup(client, PARENT_A)
    token_b = _register_and_login(client, PARENT_B)
    r = client.get(f"{PARENT_API}/children/{child_id_a}/overview", headers=_auth(token_b))
    assert r.status_code == 403


# ---------------------------------------------------------------------------
# Weekly activity
# ---------------------------------------------------------------------------

def test_weekly_requires_auth(client):
    r = client.get(f"{PARENT_API}/children/1/weekly")
    assert r.status_code == 401


def test_weekly_returns_7_entries(client):
    token, child_id = _setup(client)
    r = client.get(f"{PARENT_API}/children/{child_id}/weekly", headers=_auth(token))
    assert r.status_code == 200
    data = r.json()["data"]
    assert len(data) == 7
    for entry in data:
        assert "date" in entry
        assert "minutes" in entry
        assert "lessons_completed" in entry


def test_weekly_cross_parent_forbidden(client):
    token_a, child_id_a = _setup(client, PARENT_A)
    token_b = _register_and_login(client, PARENT_B)
    r = client.get(f"{PARENT_API}/children/{child_id_a}/weekly", headers=_auth(token_b))
    assert r.status_code == 403


# ---------------------------------------------------------------------------
# Topics
# ---------------------------------------------------------------------------

def test_topics_requires_auth(client):
    r = client.get(f"{PARENT_API}/children/1/topics")
    assert r.status_code == 401


def test_topics_empty(client):
    token, child_id = _setup(client)
    r = client.get(f"{PARENT_API}/children/{child_id}/topics", headers=_auth(token))
    assert r.status_code == 200
    assert r.json()["data"] == []


def test_topics_cross_parent_forbidden(client):
    token_a, child_id_a = _setup(client, PARENT_A)
    token_b = _register_and_login(client, PARENT_B)
    r = client.get(f"{PARENT_API}/children/{child_id_a}/topics", headers=_auth(token_b))
    assert r.status_code == 403


# ---------------------------------------------------------------------------
# Subjects
# ---------------------------------------------------------------------------

def test_subjects_requires_auth(client):
    r = client.get(f"{PARENT_API}/children/1/subjects")
    assert r.status_code == 401


def test_subjects_empty(client):
    token, child_id = _setup(client)
    r = client.get(f"{PARENT_API}/children/{child_id}/subjects", headers=_auth(token))
    assert r.status_code == 200
    assert r.json()["data"] == []


# ---------------------------------------------------------------------------
# Achievements
# ---------------------------------------------------------------------------

def test_achievements_requires_auth(client):
    r = client.get(f"{PARENT_API}/children/1/achievements")
    assert r.status_code == 401


def test_achievements_shows_all_locked(client):
    token, child_id = _setup(client)
    r = client.get(f"{PARENT_API}/children/{child_id}/achievements", headers=_auth(token))
    assert r.status_code == 200
    data = r.json()["data"]
    assert len(data) == 5
    for a in data:
        assert a["earned"] is False
        assert "title" in a
        assert "icon" in a


def test_achievements_cross_parent_forbidden(client):
    token_a, child_id_a = _setup(client, PARENT_A)
    token_b = _register_and_login(client, PARENT_B)
    r = client.get(f"{PARENT_API}/children/{child_id_a}/achievements", headers=_auth(token_b))
    assert r.status_code == 403


# ---------------------------------------------------------------------------
# Daily goal
# ---------------------------------------------------------------------------

def test_get_goal_requires_auth(client):
    r = client.get(f"{PARENT_API}/children/1/goal")
    assert r.status_code == 401


def test_get_goal_default(client):
    token, child_id = _setup(client)
    r = client.get(f"{PARENT_API}/children/{child_id}/goal", headers=_auth(token))
    assert r.status_code == 200
    data = r.json()["data"]
    assert data["target_minutes"] == 15
    assert data["today_minutes"] == 0
    assert data["progress_percent"] == 0


def test_set_goal(client):
    token, child_id = _setup(client)
    r = client.post(
        f"{PARENT_API}/children/{child_id}/goal",
        json={"target_minutes": 30},
        headers=_auth(token),
    )
    assert r.status_code == 200
    assert r.json()["data"]["target_minutes"] == 30


def test_set_goal_updates_get(client):
    token, child_id = _setup(client)
    client.post(
        f"{PARENT_API}/children/{child_id}/goal",
        json={"target_minutes": 45},
        headers=_auth(token),
    )
    r = client.get(f"{PARENT_API}/children/{child_id}/goal", headers=_auth(token))
    assert r.json()["data"]["target_minutes"] == 45


def test_set_goal_too_low(client):
    token, child_id = _setup(client)
    r = client.post(
        f"{PARENT_API}/children/{child_id}/goal",
        json={"target_minutes": 2},
        headers=_auth(token),
    )
    assert r.status_code == 422


def test_set_goal_too_high(client):
    token, child_id = _setup(client)
    r = client.post(
        f"{PARENT_API}/children/{child_id}/goal",
        json={"target_minutes": 200},
        headers=_auth(token),
    )
    assert r.status_code == 422


def test_set_goal_cross_parent_forbidden(client):
    token_a, child_id_a = _setup(client, PARENT_A)
    token_b = _register_and_login(client, PARENT_B)
    r = client.post(
        f"{PARENT_API}/children/{child_id_a}/goal",
        json={"target_minutes": 20},
        headers=_auth(token_b),
    )
    assert r.status_code == 403
