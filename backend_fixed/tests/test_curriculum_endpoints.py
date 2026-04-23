"""
=============================================================================
Tests for Curriculum HTTP Endpoints
=============================================================================
Uses the session-scoped TestClient from conftest.py.
Run with: pytest tests/test_curriculum_endpoints.py -v
=============================================================================
"""

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import pytest

BASE = "/api/v1/curriculum"


# =============================================================================
# 1. GET /grades
# =============================================================================

def test_grades_returns_200(client):
    r = client.get(f"{BASE}/grades")
    assert r.status_code == 200


def test_grades_returns_success_status(client):
    r = client.get(f"{BASE}/grades")
    assert r.json()["status"] == "success"


def test_grades_returns_five_grades(client):
    r = client.get(f"{BASE}/grades")
    data = r.json()["data"]
    assert len(data) == 5


def test_grades_include_kindergarten(client):
    r = client.get(f"{BASE}/grades")
    names = [g["name"] for g in r.json()["data"]]
    assert "Kindergarten" in names


def test_grades_include_fourth_grade(client):
    r = client.get(f"{BASE}/grades")
    names = [g["name"] for g in r.json()["data"]]
    assert "Fourth Grade" in names


def test_grades_have_required_fields(client):
    r = client.get(f"{BASE}/grades")
    for grade in r.json()["data"]:
        assert "grade" in grade
        assert "name" in grade
        assert "age_range" in grade


def test_grades_age_ranges_are_strings(client):
    r = client.get(f"{BASE}/grades")
    for grade in r.json()["data"]:
        assert isinstance(grade["age_range"], str)
        assert "-" in grade["age_range"]


def test_grades_are_numbered_zero_to_four(client):
    r = client.get(f"{BASE}/grades")
    grade_nums = sorted(g["grade"] for g in r.json()["data"])
    assert grade_nums == [0, 1, 2, 3, 4]


# =============================================================================
# 2. GET /subjects
# =============================================================================

def test_subjects_returns_200_for_valid_grade(client):
    r = client.get(f"{BASE}/subjects", params={"grade": 0})
    assert r.status_code == 200


def test_subjects_returns_four_subjects_for_kindergarten(client):
    r = client.get(f"{BASE}/subjects", params={"grade": 0})
    data = r.json()["data"]
    assert len(data) == 4


def test_subjects_returns_four_subjects_for_grade_four(client):
    r = client.get(f"{BASE}/subjects", params={"grade": 4})
    data = r.json()["data"]
    assert len(data) == 4


def test_subjects_include_all_four_types(client):
    r = client.get(f"{BASE}/subjects", params={"grade": 1})
    subjects = {s["subject"] for s in r.json()["data"]}
    assert subjects == {"math", "science", "english", "arabic"}


def test_subjects_have_required_fields(client):
    r = client.get(f"{BASE}/subjects", params={"grade": 0})
    for s in r.json()["data"]:
        assert "subject" in s
        assert "display_name" in s


def test_subjects_invalid_grade_too_high_returns_422(client):
    r = client.get(f"{BASE}/subjects", params={"grade": 99})
    assert r.status_code == 422


def test_subjects_invalid_grade_negative_returns_422(client):
    r = client.get(f"{BASE}/subjects", params={"grade": -1})
    assert r.status_code == 422


def test_subjects_missing_grade_returns_422(client):
    r = client.get(f"{BASE}/subjects")
    assert r.status_code == 422


# =============================================================================
# 3. GET /topics
# =============================================================================

def test_topics_returns_200_for_valid_params(client):
    r = client.get(f"{BASE}/topics", params={"grade": 0, "subject": "math"})
    assert r.status_code == 200


def test_topics_kindergarten_math_returns_six(client):
    r = client.get(f"{BASE}/topics", params={"grade": 0, "subject": "math"})
    data = r.json()["data"]
    assert len(data) == 6


def test_topics_first_grade_science_returns_six(client):
    r = client.get(f"{BASE}/topics", params={"grade": 1, "subject": "science"})
    data = r.json()["data"]
    assert len(data) == 6


def test_topics_all_grades_all_subjects_return_six(client):
    subjects = ["math", "science", "english", "arabic"]
    for grade in range(5):
        for subject in subjects:
            r = client.get(f"{BASE}/topics", params={"grade": grade, "subject": subject})
            assert r.status_code == 200
            data = r.json()["data"]
            assert len(data) == 6, (
                f"grade={grade} subject={subject} returned {len(data)} topics"
            )


def test_topics_have_required_fields(client):
    r = client.get(f"{BASE}/topics", params={"grade": 0, "subject": "math"})
    for t in r.json()["data"]:
        assert "topic_id" in t
        assert "name_en" in t
        assert "name_ar" in t
        assert "order" in t
        assert "difficulty_level" in t


def test_topics_ordered_one_to_six(client):
    r = client.get(f"{BASE}/topics", params={"grade": 0, "subject": "math"})
    orders = [t["order"] for t in r.json()["data"]]
    assert orders == [1, 2, 3, 4, 5, 6]


def test_topics_kindergarten_math_first_is_numbers_to_3(client):
    r = client.get(f"{BASE}/topics", params={"grade": 0, "subject": "math"})
    first = r.json()["data"][0]
    assert first["topic_id"] == "numbers_to_3"


def test_topics_invalid_subject_returns_error_status(client):
    r = client.get(f"{BASE}/topics", params={"grade": 0, "subject": "history"})
    body = r.json()
    assert body["status"] == "error"
    assert body["data"] == []


def test_topics_invalid_grade_too_high_returns_422(client):
    r = client.get(f"{BASE}/topics", params={"grade": 10, "subject": "math"})
    assert r.status_code == 422


def test_topics_missing_grade_returns_422(client):
    r = client.get(f"{BASE}/topics", params={"subject": "math"})
    assert r.status_code == 422


def test_topics_missing_subject_returns_422(client):
    r = client.get(f"{BASE}/topics", params={"grade": 0})
    assert r.status_code == 422


# =============================================================================
# 4. Health / root sanity (quick smoke test)
# =============================================================================

def test_health_endpoint_returns_200(client):
    r = client.get("/health")
    assert r.status_code == 200
    assert r.json()["status"] == "success"


def test_root_endpoint_returns_200(client):
    r = client.get("/")
    assert r.status_code == 200
    assert r.json()["status"] == "success"
