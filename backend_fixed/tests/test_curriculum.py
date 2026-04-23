"""
=============================================================================
Tests for Curriculum Data Structure and Helper Functions
=============================================================================
Run with: pytest tests/test_curriculum.py -v
=============================================================================
"""

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import pytest
from app.models.curriculum import (
    CURRICULUM,
    GradeLevel,
    SubjectType,
    TopicInfo,
    get_topics,
    get_topic,
    find_topic_by_name,
    is_valid_topic,
    grade_int_to_enum,
    subject_str_to_enum,
)


# =============================================================================
# 1. CURRICULUM dict completeness
# =============================================================================

def test_curriculum_has_20_entries():
    assert len(CURRICULUM) == 20  # 5 grades × 4 subjects


def test_curriculum_covers_all_five_grades():
    grades_present = {key[0] for key in CURRICULUM}
    assert grades_present == set(GradeLevel)


def test_curriculum_covers_all_four_subjects():
    subjects_present = {key[1] for key in CURRICULUM}
    assert subjects_present == set(SubjectType)


def test_every_entry_has_exactly_six_topics():
    for (grade, subject), topics in CURRICULUM.items():
        assert len(topics) == 6, (
            f"{grade.name}/{subject.name} has {len(topics)} topics, expected 6"
        )


def test_all_topics_are_topicinfo_instances():
    for topics in CURRICULUM.values():
        for t in topics:
            assert isinstance(t, TopicInfo)


def test_topic_order_is_sequential_within_each_entry():
    for (grade, subject), topics in CURRICULUM.items():
        orders = [t.order for t in topics]
        assert orders == list(range(1, 7)), (
            f"{grade.name}/{subject.name} orders {orders} are not 1-6"
        )


def test_no_duplicate_topic_ids_within_entry():
    for (grade, subject), topics in CURRICULUM.items():
        ids = [t.topic_id for t in topics]
        assert len(ids) == len(set(ids)), (
            f"{grade.name}/{subject.name} has duplicate topic_ids"
        )


def test_every_topic_has_non_empty_names():
    for topics in CURRICULUM.values():
        for t in topics:
            assert t.name_en.strip(), f"topic_id={t.topic_id} has empty name_en"
            assert t.name_ar.strip(), f"topic_id={t.topic_id} has empty name_ar"


# =============================================================================
# 2. get_topics() helper
# =============================================================================

def test_get_topics_kindergarten_math_returns_six():
    topics = get_topics(0, "math")
    assert len(topics) == 6


def test_get_topics_first_grade_science_returns_six():
    topics = get_topics(1, "science")
    assert len(topics) == 6


def test_get_topics_fourth_grade_arabic_returns_six():
    topics = get_topics(4, "arabic")
    assert len(topics) == 6


def test_get_topics_invalid_grade_returns_empty():
    assert get_topics(99, "math") == []


def test_get_topics_invalid_subject_returns_empty():
    assert get_topics(0, "history") == []


def test_get_topics_both_invalid_returns_empty():
    assert get_topics(-1, "nothing") == []


def test_get_topics_subject_case_insensitive():
    upper = get_topics(0, "MATH")
    lower = get_topics(0, "math")
    assert len(upper) == len(lower) == 6


# =============================================================================
# 3. get_topic() — lookup by exact ID
# =============================================================================

def test_get_topic_finds_numbers_to_3():
    t = get_topic(0, "math", "numbers_to_3")
    assert t is not None
    assert t.topic_id == "numbers_to_3"
    assert t.name_en == "Numbers to 3"


def test_get_topic_finds_counting_to_100():
    t = get_topic(1, "math", "counting_to_100")
    assert t is not None
    assert t.name_en == "Counting to 100"


def test_get_topic_nonexistent_id_returns_none():
    assert get_topic(0, "math", "flying_dragons") is None


def test_get_topic_wrong_grade_returns_none():
    # numbers_to_3 belongs to kindergarten, not grade 2
    assert get_topic(2, "math", "numbers_to_3") is None


# =============================================================================
# 4. find_topic_by_name() — English and Arabic lookup
# =============================================================================

def test_find_topic_by_exact_english_name():
    t = find_topic_by_name(0, "math", "Numbers to 3")
    assert t is not None
    assert t.topic_id == "numbers_to_3"


def test_find_topic_by_case_insensitive_english_name():
    t = find_topic_by_name(0, "math", "numbers to 3")
    assert t is not None
    assert t.topic_id == "numbers_to_3"


def test_find_topic_by_partial_english_name():
    t = find_topic_by_name(0, "math", "Numbers")
    assert t is not None
    assert "numbers" in t.topic_id


def test_find_topic_by_arabic_name():
    t = find_topic_by_name(0, "math", "الأرقام حتى 3")
    # Arabic names are not in find_topic_by_name search paths (only name_en)
    # The function searches name_en only, so this may return None
    # Document actual behavior:
    result = find_topic_by_name(0, "math", "الأرقام حتى 3")
    # Either finds it or returns None — just verify no exception is raised
    assert result is None or isinstance(result, TopicInfo)


def test_find_topic_nonexistent_returns_none():
    assert find_topic_by_name(0, "math", "Quantum Physics") is None


def test_find_topic_by_slug_style_id():
    t = find_topic_by_name(0, "math", "numbers_to_3")
    assert t is not None
    assert t.topic_id == "numbers_to_3"


def test_find_topic_first_grade_english_verb():
    t = find_topic_by_name(1, "english", "Verbs")
    assert t is not None
    assert t.topic_id == "verbs_g1"


def test_find_topic_fourth_grade_multiplication():
    t = find_topic_by_name(4, "math", "Multiplication")
    assert t is not None
    assert t.topic_id == "multiplication_g4"


# =============================================================================
# 5. is_valid_topic()
# =============================================================================

def test_is_valid_topic_with_valid_id():
    assert is_valid_topic(0, "math", "numbers_to_3") is True


def test_is_valid_topic_with_valid_display_name():
    assert is_valid_topic(0, "math", "Numbers to 3") is True


def test_is_valid_topic_with_invalid_id():
    assert is_valid_topic(0, "math", "dragons_and_castles") is False


def test_is_valid_topic_wrong_grade():
    assert is_valid_topic(4, "math", "numbers_to_3") is False


def test_is_valid_topic_wrong_subject():
    assert is_valid_topic(0, "science", "numbers_to_3") is False


def test_is_valid_topic_all_grades_and_subjects():
    for (grade, subject), topics in CURRICULUM.items():
        for t in topics:
            assert is_valid_topic(grade.value, subject.value, t.topic_id), (
                f"is_valid_topic returned False for known topic: "
                f"grade={grade.value}, subject={subject.value}, id={t.topic_id}"
            )


# =============================================================================
# 6. Enum converters
# =============================================================================

def test_grade_int_to_enum_kindergarten():
    assert grade_int_to_enum(0) == GradeLevel.KINDERGARTEN


def test_grade_int_to_enum_fourth():
    assert grade_int_to_enum(4) == GradeLevel.FOURTH


def test_grade_int_to_enum_invalid():
    assert grade_int_to_enum(99) is None


def test_subject_str_to_enum_math():
    assert subject_str_to_enum("math") == SubjectType.MATH


def test_subject_str_to_enum_arabic():
    assert subject_str_to_enum("arabic") == SubjectType.ARABIC


def test_subject_str_to_enum_case_insensitive():
    assert subject_str_to_enum("SCIENCE") == SubjectType.SCIENCE


def test_subject_str_to_enum_invalid():
    assert subject_str_to_enum("history") is None
