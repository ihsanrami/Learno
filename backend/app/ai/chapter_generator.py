"""
=============================================================================
Dynamic Chapter Generator for Learno Educational Backend
=============================================================================
Generates ChapterContent from (grade, subject, topic) via GPT-4.
Results are cached in-memory with key (grade, subject, topic_id).
=============================================================================
"""

import json
import logging
import time
from collections import OrderedDict
from typing import Dict, Optional, Tuple

from app.models.lesson_content import (
    ChapterContent, ConceptContent, PracticeQuestion,
)
from app.models.curriculum import get_grade_display_name, get_grade_age_range
from app.utils.exceptions import AIServiceError

logger = logging.getLogger(__name__)

_CACHE_MAX_SIZE = 100   # max cached chapters (80 total curriculum topics)
_CACHE_TTL = 86400      # 24 hours in seconds

# Cache key: (grade: int, subject: str, topic_id: str)
# Value: (ChapterContent, expires_at_monotonic)
_chapter_cache: OrderedDict[Tuple[int, str, str], Tuple[ChapterContent, float]] = OrderedDict()
_cache_hits = 0
_cache_misses = 0


def get_cache_stats() -> dict:
    total = _cache_hits + _cache_misses
    return {
        "size": len(_chapter_cache),
        "max_size": _CACHE_MAX_SIZE,
        "hits": _cache_hits,
        "misses": _cache_misses,
        "hit_rate_pct": round(_cache_hits / total * 100, 1) if total > 0 else 0.0,
    }


# =============================================================================
# PUBLIC API
# =============================================================================

def generate_chapter(
    grade: int,
    subject: str,
    topic_id: str,
    topic_name: str,
) -> ChapterContent:
    """Return a ChapterContent for the given topic, generating via GPT-4 if not cached."""
    global _cache_hits, _cache_misses

    cache_key = (grade, subject.lower(), topic_id)
    now = time.monotonic()

    if cache_key in _chapter_cache:
        chapter, expires_at = _chapter_cache[cache_key]
        if now < expires_at:
            _cache_hits += 1
            _chapter_cache.move_to_end(cache_key)  # LRU: mark as recently used
            logger.info(f"Chapter cache hit: {cache_key}")
            return chapter
        # Expired entry — remove and regenerate
        del _chapter_cache[cache_key]

    _cache_misses += 1
    logger.info(f"Generating chapter via GPT-4: {cache_key}")

    from app.ai.openai_client import get_ai_client
    from app.ai.dynamic_prompt_builder import build_chapter_generation_prompt

    messages = build_chapter_generation_prompt(grade, subject, topic_name)
    ai_client = get_ai_client()

    try:
        raw = ai_client.generate_json_response(messages)
        chapter = _parse_chapter_json(raw, grade, subject, topic_id, topic_name)
    except Exception as exc:
        logger.exception(f"Chapter generation failed for {cache_key}: {exc}")
        chapter = _make_fallback_chapter(grade, subject, topic_id, topic_name)

    # Evict oldest entry if at capacity
    if len(_chapter_cache) >= _CACHE_MAX_SIZE:
        _chapter_cache.popitem(last=False)

    _chapter_cache[cache_key] = (chapter, now + _CACHE_TTL)
    return chapter


def clear_cache() -> None:
    """Clear the in-memory chapter cache (useful for testing)."""
    global _cache_hits, _cache_misses
    _chapter_cache.clear()
    _cache_hits = 0
    _cache_misses = 0


# =============================================================================
# PRIVATE HELPERS
# =============================================================================

def _parse_chapter_json(
    raw_json: str,
    grade: int,
    subject: str,
    topic_id: str,
    topic_name: str,
) -> ChapterContent:
    """Convert GPT-4 JSON string into a ChapterContent object."""
    try:
        # Strip possible markdown code fences
        cleaned = raw_json.strip()
        if cleaned.startswith("```"):
            lines = cleaned.splitlines()
            cleaned = "\n".join(
                line for line in lines if not line.startswith("```")
            ).strip()
        data = json.loads(cleaned)
    except json.JSONDecodeError as exc:
        logger.error(f"JSON decode error: {exc} | snippet: {raw_json[:300]}")
        return _make_fallback_chapter(grade, subject, topic_id, topic_name)

    concepts: list[ConceptContent] = []
    for i, c in enumerate(data.get("concepts", [])[:5]):
        guided = [
            _make_question(q)
            for q in c.get("guided_questions", [])[:2]
        ]
        independent = [
            _make_question(q)
            for q in c.get("independent_questions", [])[:3]
        ]

        # Ensure we always have at least one of each
        if not guided:
            guided = [_placeholder_question(topic_name, i + 1, "guided")]
        if not independent:
            independent = [_placeholder_question(topic_name, i + 1, "independent")]

        concepts.append(ConceptContent(
            concept_id=c.get("concept_id", f"concept_{i + 1}"),
            concept_name=c.get("concept_name", f"Part {i + 1}"),
            order=i + 1,
            learning_objective=c.get("learning_objective", ""),
            introduction_script=c.get("introduction", ""),
            explanation_script=c.get("explanation", ""),
            key_points=c.get("key_points", []),
            visual_description=c.get(
                "image_description",
                f"Child-friendly cartoon illustration for {topic_name}, colorful, educational",
            ),
            visual_explanation=(
                f"Look at this picture! It helps us understand "
                f"{c.get('concept_name', topic_name)}! 🖼️✨"
            ),
            examples=[],
            guided_questions=guided,
            independent_questions=independent,
            mastery_check_question=c.get("mastery_question", "What did you learn?"),
            mastery_answer=c.get("mastery_answer", ""),
            mastery_acceptable=c.get("mastery_acceptable", [c.get("mastery_answer", "")]),
            common_mistakes=[],
            encouragement_phrases=[
                "Great job! 🌟",
                "You're doing amazing! 🎉",
                "Excellent work! 👏",
            ],
            struggle_hints=[
                "Take your time! 😊",
                "Think carefully!",
                "You can do it! 💪",
            ],
        ))

    # Ensure exactly 5 concepts
    while len(concepts) < 5:
        idx = len(concepts) + 1
        concepts.append(_make_placeholder_concept(topic_name, idx))

    review_questions = [
        _make_question(q)
        for q in data.get("review_questions", [])[:4]
    ]
    while len(review_questions) < 4:
        review_questions.append(_placeholder_question(topic_name, len(review_questions) + 1, "review"))

    grade_name = get_grade_display_name(grade)

    return ChapterContent(
        chapter_id=topic_id,
        chapter_title=data.get("chapter_title", topic_name),
        chapter_description=f"Learn about {topic_name}",
        grade_level=grade,
        subject=subject.title(),
        welcome_script=data.get(
            "welcome_message",
            f"Hello! 😊🌟 Today we're learning about {topic_name}! Let's go! 🚀",
        ),
        chapter_overview=f"We'll explore {topic_name} together! 🚀",
        concepts=concepts,
        review_questions=review_questions,
        completion_script=data.get(
            "completion_message",
            f"🎉 Amazing work! You've learned all about {topic_name}! You are a superstar! 🌟⭐",
        ),
        certificate_text=(
            f"🏆 Certificate of Achievement\n"
            f"Completed: {topic_name}\n"
            f"{grade_name} — You are a superstar! ⭐"
        ),
    )


def _make_question(q: dict) -> PracticeQuestion:
    answer = q.get("expected_answer", "")
    acceptable = q.get("acceptable_answers", [answer]) or [answer]
    return PracticeQuestion(
        question_text=q.get("question", ""),
        expected_answer=answer,
        acceptable_answers=acceptable,
        hint_text=q.get("hint", "Think about it! 😊"),
        difficulty=1,
    )


def _placeholder_question(topic_name: str, idx: int, qtype: str) -> PracticeQuestion:
    return PracticeQuestion(
        question_text=f"Question {idx} about {topic_name}?",
        expected_answer="",
        acceptable_answers=[],
        hint_text="Think about what we just learned!",
        difficulty=1,
    )


def _make_placeholder_concept(topic_name: str, idx: int) -> ConceptContent:
    return ConceptContent(
        concept_id=f"concept_{idx}",
        concept_name=f"{topic_name} — Part {idx}",
        order=idx,
        learning_objective=f"Learn about {topic_name}",
        introduction_script="",
        explanation_script="",
        key_points=[],
        visual_description=f"Educational cartoon illustration of {topic_name}",
        visual_explanation=f"Look at this picture! 🖼️",
        examples=[],
        guided_questions=[_placeholder_question(topic_name, 1, "guided")],
        independent_questions=[_placeholder_question(topic_name, 1, "independent")],
        mastery_check_question=f"What did you learn about {topic_name}?",
        mastery_answer="",
        mastery_acceptable=[],
        common_mistakes=[],
        encouragement_phrases=["Great job! 🌟"],
        struggle_hints=["You can do it! 💪"],
    )


def _make_fallback_chapter(
    grade: int, subject: str, topic_id: str, topic_name: str
) -> ChapterContent:
    """Minimal fallback chapter used when GPT-4 generation fails."""
    grade_name = get_grade_display_name(grade)
    concepts = [_make_placeholder_concept(topic_name, i + 1) for i in range(5)]
    review_qs = [_placeholder_question(topic_name, i + 1, "review") for i in range(4)]

    return ChapterContent(
        chapter_id=topic_id,
        chapter_title=topic_name,
        chapter_description=f"Learn about {topic_name}",
        grade_level=grade,
        subject=subject.title(),
        welcome_script=f"Hello! 😊 Today we learn about {topic_name}! 🌟",
        chapter_overview=f"We'll explore {topic_name} together! 🚀",
        concepts=concepts,
        review_questions=review_qs,
        completion_script=f"🎉 Great work! You finished {topic_name}! 🌟",
        certificate_text=f"🏆 Completed: {topic_name}\n{grade_name} Superstar! ⭐",
    )
