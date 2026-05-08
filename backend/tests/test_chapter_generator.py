"""
=============================================================================
Tests for Chapter Generator (GPT-4 mocked — no real API calls)
=============================================================================
Run with: pytest tests/test_chapter_generator.py -v
=============================================================================
"""

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import json
from unittest.mock import MagicMock, patch

import pytest

from app.models.lesson_content import ChapterContent


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _make_mock_concept(idx: int, topic: str) -> dict:
    return {
        "concept_id": f"concept_{idx}",
        "concept_name": f"{topic} Part {idx}",
        "learning_objective": f"Learn {topic} step {idx}",
        "introduction": f"Today we learn {topic} step {idx}!",
        "explanation": f"Here is how {topic} works in step {idx}.",
        "key_points": [f"Point {idx}a", f"Point {idx}b"],
        "image_description": f"Colorful cartoon showing {topic}",
        "guided_questions": [
            {
                "question": f"Guided question {idx}?",
                "expected_answer": f"answer {idx}",
                "acceptable_answers": [f"answer {idx}", f"ans{idx}"],
                "hint": "Think about it!",
            }
        ],
        "independent_questions": [
            {
                "question": f"Independent question {idx}?",
                "expected_answer": f"ind answer {idx}",
                "acceptable_answers": [f"ind answer {idx}"],
                "hint": "You got this!",
            }
        ],
        "mastery_question": f"What did you learn in step {idx}?",
        "mastery_answer": f"I learned step {idx}",
        "mastery_acceptable": [f"I learned step {idx}", "step"],
    }


def _make_gpt4_json(topic: str) -> str:
    """Build a realistic GPT-4 JSON response for chapter generation."""
    return json.dumps({
        "chapter_title": f"Learning {topic}",
        "welcome_message": f"Hello! Let's learn about {topic}! 🌟",
        "concepts": [_make_mock_concept(i + 1, topic) for i in range(5)],
        "review_questions": [
            {
                "question": f"Review question {i + 1} about {topic}?",
                "expected_answer": f"review answer {i + 1}",
                "acceptable_answers": [f"review answer {i + 1}"],
                "hint": "Think back!",
            }
            for i in range(4)
        ],
        "completion_message": f"Amazing! You've learned all about {topic}! 🎉",
    })


def _make_mock_ai_client(json_str: str) -> MagicMock:
    mock = MagicMock()
    mock.generate_json_response.return_value = json_str
    return mock


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

@pytest.fixture(autouse=True)
def clear_chapter_cache():
    """Ensure the in-memory cache is empty before every test."""
    from app.ai.chapter_generator import clear_cache
    clear_cache()
    yield
    clear_cache()


# =============================================================================
# 1. Successful chapter generation
# =============================================================================

def test_generate_chapter_returns_chapter_content():
    from app.ai.chapter_generator import generate_chapter

    json_str = _make_gpt4_json("Numbers to 3")
    mock_client = _make_mock_ai_client(json_str)

    with patch("app.ai.openai_client.get_ai_client", return_value=mock_client):
        chapter = generate_chapter(0, "math", "numbers_to_3", "Numbers to 3")

    assert isinstance(chapter, ChapterContent)


def test_generate_chapter_has_five_concepts():
    from app.ai.chapter_generator import generate_chapter

    json_str = _make_gpt4_json("Numbers to 3")
    mock_client = _make_mock_ai_client(json_str)

    with patch("app.ai.openai_client.get_ai_client", return_value=mock_client):
        chapter = generate_chapter(0, "math", "numbers_to_3", "Numbers to 3")

    assert len(chapter.concepts) == 5


def test_generate_chapter_has_four_review_questions():
    from app.ai.chapter_generator import generate_chapter

    json_str = _make_gpt4_json("Numbers to 3")
    mock_client = _make_mock_ai_client(json_str)

    with patch("app.ai.openai_client.get_ai_client", return_value=mock_client):
        chapter = generate_chapter(0, "math", "numbers_to_3", "Numbers to 3")

    assert len(chapter.review_questions) == 4


def test_generate_chapter_sets_correct_grade():
    from app.ai.chapter_generator import generate_chapter

    json_str = _make_gpt4_json("Counting to 100")
    mock_client = _make_mock_ai_client(json_str)

    with patch("app.ai.openai_client.get_ai_client", return_value=mock_client):
        chapter = generate_chapter(1, "math", "counting_to_100", "Counting to 100")

    assert chapter.grade_level == 1


def test_generate_chapter_sets_correct_subject():
    from app.ai.chapter_generator import generate_chapter

    json_str = _make_gpt4_json("Materials")
    mock_client = _make_mock_ai_client(json_str)

    with patch("app.ai.openai_client.get_ai_client", return_value=mock_client):
        chapter = generate_chapter(0, "science", "materials_kg", "Materials")

    assert chapter.subject.lower() == "science"


def test_generate_chapter_uses_welcome_from_gpt4():
    from app.ai.chapter_generator import generate_chapter

    json_str = _make_gpt4_json("Numbers to 3")
    mock_client = _make_mock_ai_client(json_str)

    with patch("app.ai.openai_client.get_ai_client", return_value=mock_client):
        chapter = generate_chapter(0, "math", "numbers_to_3", "Numbers to 3")

    assert "Numbers to 3" in chapter.welcome_script


def test_generate_chapter_each_concept_has_guided_question():
    from app.ai.chapter_generator import generate_chapter

    json_str = _make_gpt4_json("Numbers to 3")
    mock_client = _make_mock_ai_client(json_str)

    with patch("app.ai.openai_client.get_ai_client", return_value=mock_client):
        chapter = generate_chapter(0, "math", "numbers_to_3", "Numbers to 3")

    for concept in chapter.concepts:
        assert len(concept.guided_questions) >= 1


def test_generate_chapter_each_concept_has_independent_question():
    from app.ai.chapter_generator import generate_chapter

    json_str = _make_gpt4_json("Numbers to 3")
    mock_client = _make_mock_ai_client(json_str)

    with patch("app.ai.openai_client.get_ai_client", return_value=mock_client):
        chapter = generate_chapter(0, "math", "numbers_to_3", "Numbers to 3")

    for concept in chapter.concepts:
        assert len(concept.independent_questions) >= 1


# =============================================================================
# 2. Cache behavior
# =============================================================================

def test_cache_hit_does_not_call_gpt4_again():
    from app.ai.chapter_generator import generate_chapter

    json_str = _make_gpt4_json("Numbers to 3")
    mock_client = _make_mock_ai_client(json_str)

    with patch("app.ai.openai_client.get_ai_client", return_value=mock_client):
        generate_chapter(0, "math", "numbers_to_3", "Numbers to 3")
        generate_chapter(0, "math", "numbers_to_3", "Numbers to 3")

    assert mock_client.generate_json_response.call_count == 1


def test_cache_returns_same_object_on_second_call():
    from app.ai.chapter_generator import generate_chapter

    json_str = _make_gpt4_json("Numbers to 3")
    mock_client = _make_mock_ai_client(json_str)

    with patch("app.ai.openai_client.get_ai_client", return_value=mock_client):
        chapter1 = generate_chapter(0, "math", "numbers_to_3", "Numbers to 3")
        chapter2 = generate_chapter(0, "math", "numbers_to_3", "Numbers to 3")

    assert chapter1 is chapter2


def test_cache_miss_for_different_topic():
    from app.ai.chapter_generator import generate_chapter

    json_str = _make_gpt4_json("Topic")
    mock_client = _make_mock_ai_client(json_str)

    with patch("app.ai.openai_client.get_ai_client", return_value=mock_client):
        generate_chapter(0, "math", "numbers_to_3", "Numbers to 3")
        generate_chapter(0, "math", "counting_to_3", "Counting to 3")

    assert mock_client.generate_json_response.call_count == 2


def test_cache_miss_for_different_grade():
    from app.ai.chapter_generator import generate_chapter

    json_str = _make_gpt4_json("Topic")
    mock_client = _make_mock_ai_client(json_str)

    with patch("app.ai.openai_client.get_ai_client", return_value=mock_client):
        generate_chapter(0, "math", "counting_to_5", "Counting to 5")
        generate_chapter(1, "math", "counting_to_5", "Counting to 5")

    assert mock_client.generate_json_response.call_count == 2


def test_cache_miss_for_different_subject():
    from app.ai.chapter_generator import generate_chapter

    json_str = _make_gpt4_json("Materials")
    mock_client = _make_mock_ai_client(json_str)

    with patch("app.ai.openai_client.get_ai_client", return_value=mock_client):
        generate_chapter(0, "math", "materials_kg", "Materials")
        generate_chapter(0, "science", "materials_kg", "Materials")

    assert mock_client.generate_json_response.call_count == 2


# =============================================================================
# 3. Fallback behavior when GPT-4 fails
# =============================================================================

def test_fallback_chapter_returned_when_gpt4_raises():
    from app.ai.chapter_generator import generate_chapter
    from app.utils.exceptions import AIServiceError

    mock_client = MagicMock()
    mock_client.generate_json_response.side_effect = AIServiceError("rate limit")

    with patch("app.ai.openai_client.get_ai_client", return_value=mock_client):
        chapter = generate_chapter(0, "math", "numbers_to_3", "Numbers to 3")

    assert isinstance(chapter, ChapterContent)
    assert chapter.chapter_id == "numbers_to_3"


def test_fallback_chapter_has_five_concepts():
    from app.ai.chapter_generator import generate_chapter
    from app.utils.exceptions import AIServiceError

    mock_client = MagicMock()
    mock_client.generate_json_response.side_effect = AIServiceError("timeout")

    with patch("app.ai.openai_client.get_ai_client", return_value=mock_client):
        chapter = generate_chapter(0, "math", "numbers_to_3", "Numbers to 3")

    assert len(chapter.concepts) == 5


def test_fallback_chapter_returned_when_json_is_invalid():
    from app.ai.chapter_generator import generate_chapter

    mock_client = _make_mock_ai_client("this is not json {{{{")

    with patch("app.ai.openai_client.get_ai_client", return_value=mock_client):
        chapter = generate_chapter(0, "math", "numbers_to_3", "Numbers to 3")

    assert isinstance(chapter, ChapterContent)
    assert len(chapter.concepts) == 5


def test_fallback_chapter_cached_so_gpt4_not_retried():
    from app.ai.chapter_generator import generate_chapter
    from app.utils.exceptions import AIServiceError

    mock_client = MagicMock()
    mock_client.generate_json_response.side_effect = AIServiceError("down")

    with patch("app.ai.openai_client.get_ai_client", return_value=mock_client):
        generate_chapter(0, "math", "numbers_to_3", "Numbers to 3")
        generate_chapter(0, "math", "numbers_to_3", "Numbers to 3")

    # Even fallback is cached — only one real attempt
    assert mock_client.generate_json_response.call_count == 1


# =============================================================================
# 4. JSON with markdown code fence (real GPT-4 sometimes wraps in ```)
# =============================================================================

def test_chapter_parsed_when_response_wrapped_in_code_fence():
    from app.ai.chapter_generator import generate_chapter

    inner = _make_gpt4_json("Numbers to 3")
    fenced = f"```json\n{inner}\n```"
    mock_client = _make_mock_ai_client(fenced)

    with patch("app.ai.openai_client.get_ai_client", return_value=mock_client):
        chapter = generate_chapter(0, "math", "numbers_to_3", "Numbers to 3")

    assert isinstance(chapter, ChapterContent)
    assert len(chapter.concepts) == 5


# =============================================================================
# 5. GPT-4 returns fewer than 5 concepts — padded to 5
# =============================================================================

def test_chapter_padded_to_five_concepts_when_gpt4_returns_three():
    from app.ai.chapter_generator import generate_chapter

    partial = {
        "chapter_title": "Numbers to 3",
        "welcome_message": "Hello! 🌟",
        "concepts": [_make_mock_concept(i + 1, "Numbers to 3") for i in range(3)],
        "review_questions": [_make_mock_concept(i, "Numbers to 3")["guided_questions"][0] for i in range(4)],
        "completion_message": "Done! 🎉",
    }
    mock_client = _make_mock_ai_client(json.dumps(partial))

    with patch("app.ai.openai_client.get_ai_client", return_value=mock_client):
        chapter = generate_chapter(0, "math", "numbers_to_3", "Numbers to 3")

    assert len(chapter.concepts) == 5
