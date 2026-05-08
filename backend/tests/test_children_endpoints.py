"""Integration tests for /api/v1/children endpoints."""
import pytest


AUTH_API = "/api/v1/auth"
CHILD_API = "/api/v1/children"

PARENT_A = {"email": "parent_a@example.com", "password": "Password1!", "full_name": "Parent A"}
PARENT_B = {"email": "parent_b@example.com", "password": "Password2!", "full_name": "Parent B"}

VALID_CHILD = {"name": "Ali", "age": 7, "grade": "second", "avatar": "fox"}


def _register_and_login(client, parent=PARENT_A):
    client.post(f"{AUTH_API}/register", json=parent)
    r = client.post(f"{AUTH_API}/login", json={"email": parent["email"], "password": parent["password"]})
    return r.json()["access_token"]


def _auth(token):
    return {"Authorization": f"Bearer {token}"}


# ---------- list ----------

def test_list_children_empty(client):
    token = _register_and_login(client)
    r = client.get(CHILD_API + "/", headers=_auth(token))
    assert r.status_code == 200
    assert r.json() == []


def test_list_children_requires_auth(client):
    r = client.get(CHILD_API + "/")
    assert r.status_code == 401


# ---------- create ----------

def test_create_child_success(client):
    token = _register_and_login(client)
    r = client.post(CHILD_API + "/", json=VALID_CHILD, headers=_auth(token))
    assert r.status_code == 201
    data = r.json()
    assert data["name"] == VALID_CHILD["name"]
    assert data["age"] == VALID_CHILD["age"]
    assert data["grade"] == VALID_CHILD["grade"]
    assert "id" in data


def test_create_child_requires_auth(client):
    r = client.post(CHILD_API + "/", json=VALID_CHILD)
    assert r.status_code == 401


def test_create_child_age_too_young(client):
    token = _register_and_login(client)
    r = client.post(CHILD_API + "/", json={**VALID_CHILD, "age": 3}, headers=_auth(token))
    assert r.status_code == 422


def test_create_child_age_too_old(client):
    token = _register_and_login(client)
    r = client.post(CHILD_API + "/", json={**VALID_CHILD, "age": 11}, headers=_auth(token))
    assert r.status_code == 422


def test_create_child_invalid_grade(client):
    token = _register_and_login(client)
    r = client.post(CHILD_API + "/", json={**VALID_CHILD, "grade": "sixth"}, headers=_auth(token))
    assert r.status_code == 422


def test_create_child_empty_name(client):
    token = _register_and_login(client)
    r = client.post(CHILD_API + "/", json={**VALID_CHILD, "name": ""}, headers=_auth(token))
    assert r.status_code == 422


def test_create_multiple_children(client):
    token = _register_and_login(client)
    client.post(CHILD_API + "/", json=VALID_CHILD, headers=_auth(token))
    client.post(CHILD_API + "/", json={**VALID_CHILD, "name": "Sara"}, headers=_auth(token))
    r = client.get(CHILD_API + "/", headers=_auth(token))
    assert len(r.json()) == 2


# ---------- get ----------

def test_get_child_success(client):
    token = _register_and_login(client)
    created = client.post(CHILD_API + "/", json=VALID_CHILD, headers=_auth(token)).json()
    r = client.get(f"{CHILD_API}/{created['id']}", headers=_auth(token))
    assert r.status_code == 200
    assert r.json()["id"] == created["id"]


def test_get_child_not_found(client):
    token = _register_and_login(client)
    r = client.get(f"{CHILD_API}/99999", headers=_auth(token))
    assert r.status_code == 404


def test_get_other_parents_child(client):
    """Parent B cannot access Parent A's child."""
    token_a = _register_and_login(client, PARENT_A)
    token_b = _register_and_login(client, PARENT_B)
    child = client.post(CHILD_API + "/", json=VALID_CHILD, headers=_auth(token_a)).json()
    r = client.get(f"{CHILD_API}/{child['id']}", headers=_auth(token_b))
    assert r.status_code == 404


# ---------- update ----------

def test_update_child_name(client):
    token = _register_and_login(client)
    child = client.post(CHILD_API + "/", json=VALID_CHILD, headers=_auth(token)).json()
    r = client.put(f"{CHILD_API}/{child['id']}", json={"name": "Nora"}, headers=_auth(token))
    assert r.status_code == 200
    assert r.json()["name"] == "Nora"


def test_update_child_partial(client):
    token = _register_and_login(client)
    child = client.post(CHILD_API + "/", json=VALID_CHILD, headers=_auth(token)).json()
    r = client.put(f"{CHILD_API}/{child['id']}", json={"age": 8}, headers=_auth(token))
    assert r.status_code == 200
    assert r.json()["age"] == 8
    assert r.json()["name"] == VALID_CHILD["name"]


def test_update_other_parents_child(client):
    token_a = _register_and_login(client, PARENT_A)
    token_b = _register_and_login(client, PARENT_B)
    child = client.post(CHILD_API + "/", json=VALID_CHILD, headers=_auth(token_a)).json()
    r = client.put(f"{CHILD_API}/{child['id']}", json={"name": "Hacked"}, headers=_auth(token_b))
    assert r.status_code == 404


# ---------- delete ----------

def test_delete_child_success(client):
    token = _register_and_login(client)
    child = client.post(CHILD_API + "/", json=VALID_CHILD, headers=_auth(token)).json()
    r = client.delete(f"{CHILD_API}/{child['id']}", headers=_auth(token))
    assert r.status_code == 204
    r2 = client.get(f"{CHILD_API}/{child['id']}", headers=_auth(token))
    assert r2.status_code == 404


def test_delete_other_parents_child(client):
    token_a = _register_and_login(client, PARENT_A)
    token_b = _register_and_login(client, PARENT_B)
    child = client.post(CHILD_API + "/", json=VALID_CHILD, headers=_auth(token_a)).json()
    r = client.delete(f"{CHILD_API}/{child['id']}", headers=_auth(token_b))
    assert r.status_code == 404


# ---------- select ----------

def test_select_child_success(client):
    token = _register_and_login(client)
    child = client.post(CHILD_API + "/", json=VALID_CHILD, headers=_auth(token)).json()
    r = client.post(f"{CHILD_API}/{child['id']}/select", headers=_auth(token))
    assert r.status_code == 200
    assert r.json()["id"] == child["id"]


def test_select_nonexistent_child(client):
    token = _register_and_login(client)
    r = client.post(f"{CHILD_API}/99999/select", headers=_auth(token))
    assert r.status_code == 404
