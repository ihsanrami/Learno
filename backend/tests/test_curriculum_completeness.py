"""
Comprehensive curriculum completeness tests:
- All 20 (grade × subject) combinations return exactly 6 topics
- All topic IDs are unique across the entire curriculum
- Topics have valid bilingual names
- Helper functions handle edge cases correctly
"""

import os
import sys

os.environ.setdefault("OPENAI_API_KEY", "sk-test-not-real")
os.environ.setdefault("DATABASE_URL", "sqlite:///:memory:")
os.environ.setdefault("JWT_SECRET_KEY", "test-secret-key-not-for-production")

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import pytest
from app.models.curriculum import (
    CURRICULUM, GradeLevel, SubjectType,
    get_topics, get_topic, find_topic_by_name, is_valid_topic,
    grade_int_to_enum, subject_str_to_enum, get_grade_display_name,
    GRADE_DISPLAY_NAMES, GRADE_AGE_RANGES,
)


# ---------------------------------------------------------------------------
# Completeness: every grade × subject pair has exactly 6 unique topics
# ---------------------------------------------------------------------------

@pytest.mark.parametrize("grade", [0, 1, 2, 3, 4])
@pytest.mark.parametrize("subject", ["math", "science", "english", "arabic"])
def test_each_combination_has_6_topics(grade, subject):
    topics = get_topics(grade, subject)
    assert len(topics) == 6, f"Grade {grade} {subject} has {len(topics)} topics, expected 6"


@pytest.mark.parametrize("grade", [0, 1, 2, 3, 4])
@pytest.mark.parametrize("subject", ["math", "science", "english", "arabic"])
def test_no_duplicate_topic_ids_per_combination(grade, subject):
    topics = get_topics(grade, subject)
    ids = [t.topic_id for t in topics]
    assert len(ids) == len(set(ids)), f"Duplicate topic_ids in Grade {grade} {subject}"


@pytest.mark.parametrize("grade", [0, 1, 2, 3, 4])
@pytest.mark.parametrize("subject", ["math", "science", "english", "arabic"])
def test_topics_ordered_sequentially(grade, subject):
    topics = get_topics(grade, subject)
    orders = [t.order for t in topics]
    assert orders == list(range(1, 7)), f"Non-sequential orders in Grade {grade} {subject}: {orders}"


@pytest.mark.parametrize("grade", [0, 1, 2, 3, 4])
@pytest.mark.parametrize("subject", ["math", "science", "english", "arabic"])
def test_topics_have_non_empty_english_names(grade, subject):
    for t in get_topics(grade, subject):
        assert t.name_en.strip(), f"Empty name_en: {t.topic_id}"


@pytest.mark.parametrize("grade", [0, 1, 2, 3, 4])
@pytest.mark.parametrize("subject", ["math", "science", "english", "arabic"])
def test_topics_have_non_empty_arabic_names(grade, subject):
    for t in get_topics(grade, subject):
        assert t.name_ar.strip(), f"Empty name_ar: {t.topic_id}"


# ---------------------------------------------------------------------------
# Global uniqueness: topic_ids should be unique within each (grade, subject)
# ---------------------------------------------------------------------------

def test_all_topic_ids_globally_within_grade_subject():
    for (grade_enum, subject_enum), topics in CURRICULUM.items():
        ids = [t.topic_id for t in topics]
        assert len(ids) == len(set(ids)), \
            f"Duplicate IDs in ({grade_enum}, {subject_enum}): {ids}"


# ---------------------------------------------------------------------------
# Difficulty levels match grade expectations
# ---------------------------------------------------------------------------

def test_kindergarten_topics_difficulty_1():
    for subject in ["math", "science", "english", "arabic"]:
        for t in get_topics(0, subject):
            assert t.difficulty_level == 1, f"{t.topic_id} has wrong difficulty {t.difficulty_level}"


def test_fourth_grade_topics_difficulty_4():
    for subject in ["math", "science", "english", "arabic"]:
        for t in get_topics(4, subject):
            assert t.difficulty_level == 4, f"{t.topic_id} has wrong difficulty {t.difficulty_level}"


# ---------------------------------------------------------------------------
# Helper functions — edge cases
# ---------------------------------------------------------------------------

def test_get_topics_case_insensitive_math():
    assert get_topics(0, "MATH") == get_topics(0, "math")


def test_get_topics_case_insensitive_science():
    assert get_topics(1, "Science") == get_topics(1, "science")


def test_get_topics_invalid_grade_minus_1():
    assert get_topics(-1, "math") == []


def test_get_topics_invalid_grade_5():
    assert get_topics(5, "math") == []


def test_get_topic_returns_correct_object():
    t = get_topic(0, "math", "numbers_to_3")
    assert t is not None
    assert t.topic_id == "numbers_to_3"
    assert t.grade == GradeLevel.KINDERGARTEN


def test_get_topic_wrong_subject_returns_none():
    assert get_topic(0, "science", "numbers_to_3") is None


def test_find_topic_exact_match():
    t = find_topic_by_name(0, "math", "Numbers to 3")
    assert t is not None
    assert t.topic_id == "numbers_to_3"


def test_find_topic_case_insensitive():
    t = find_topic_by_name(0, "math", "numbers to 3")
    assert t is not None


def test_find_topic_partial_match():
    t = find_topic_by_name(0, "math", "Numbers")
    assert t is not None


def test_find_topic_nonexistent_returns_none():
    assert find_topic_by_name(0, "math", "quantum mechanics") is None


def test_is_valid_topic_all_combinations():
    """Every topic in the curriculum should be considered valid."""
    for (grade_enum, subject_enum), topics in CURRICULUM.items():
        for t in topics:
            assert is_valid_topic(grade_enum.value, subject_enum.value, t.topic_id), \
                f"is_valid_topic failed for {t.topic_id}"


# ---------------------------------------------------------------------------
# Display names and age ranges are defined for all grades
# ---------------------------------------------------------------------------

@pytest.mark.parametrize("grade", [0, 1, 2, 3, 4])
def test_grade_display_name_defined(grade):
    name = get_grade_display_name(grade)
    assert name and name.strip()


@pytest.mark.parametrize("grade", [0, 1, 2, 3, 4])
def test_grade_age_range_defined(grade):
    assert grade in GRADE_AGE_RANGES
    assert GRADE_AGE_RANGES[grade]


def test_grade_display_name_unknown_grade_fallback():
    name = get_grade_display_name(99)
    assert "99" in name  # fallback should include the number


# ---------------------------------------------------------------------------
# API endpoint completeness — all 20 grade/subject combos return 6 topics
# ---------------------------------------------------------------------------

@pytest.mark.parametrize("grade", [0, 1, 2, 3, 4])
@pytest.mark.parametrize("subject", ["math", "science", "english", "arabic"])
def test_curriculum_endpoint_all_combinations(session_client, grade, subject):
    r = session_client.get(f"/api/v1/curriculum/topics?grade={grade}&subject={subject}")
    assert r.status_code == 200
    data = r.json()
    assert data["status"] == "success"
    assert len(data["data"]) == 6, \
        f"API returned {len(data['data'])} topics for grade={grade} subject={subject}"
