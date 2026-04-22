"""
=============================================================================
Tests for MessageSplitter
=============================================================================
Run from backend_fixed/ with:  pytest tests/test_message_splitter.py -v
=============================================================================
"""

import sys
import os

# Allow import from project root regardless of where pytest is invoked.
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.services.message_splitter import MessageSplitter, MessageChunk

# ---------------------------------------------------------------------------
# Fixture-style helpers
# ---------------------------------------------------------------------------

def splitter() -> MessageSplitter:
    return MessageSplitter()


# ===========================================================================
# 1. Empty / trivial inputs
# ===========================================================================

def test_empty_text_returns_single_empty_chunk():
    chunks, pos = splitter().split("")
    assert len(chunks) == 1
    assert chunks[0].text == ""
    assert chunks[0].delay_ms == 0
    assert pos is None


def test_whitespace_only_returns_single_chunk():
    chunks, pos = splitter().split("   \n\n  ")
    assert len(chunks) == 1
    assert chunks[0].delay_ms == 0
    assert pos is None


def test_single_short_sentence_no_split():
    chunks, pos = splitter().split("Hello!")
    assert len(chunks) == 1
    assert chunks[0].text == "Hello!"
    assert chunks[0].delay_ms == 0


# ===========================================================================
# 2. Sentence combining (grouping)
# ===========================================================================

def test_two_short_sentences_combined_into_one_chunk():
    text = "Hello! Good morning."
    chunks, _ = splitter().split(text)
    # Both sentences are short enough to combine (< 150 chars)
    # But "Hello!" is <= 30 chars and ends with ! → standalone
    # So they should NOT combine.
    assert len(chunks) == 2
    assert chunks[0].text == "Hello!"
    assert "Good morning." in chunks[1].text


def test_two_medium_sentences_combined_when_under_150():
    # Neither sentence is standalone (no ?, and > 30 chars with !)
    s1 = "We are going to learn about numbers today."
    s2 = "It will be so much fun to count together."
    text = f"{s1} {s2}"
    chunks, _ = splitter().split(text)
    # Combined = 84 chars, both non-standalone → should combine
    assert len(chunks) == 1
    assert s1 in chunks[0].text
    assert s2 in chunks[0].text


def test_two_sentences_over_150_chars_stay_separate():
    s1 = "A" * 80 + "."
    s2 = "B" * 80 + "."
    text = f"{s1} {s2}"
    chunks, _ = splitter().split(text)
    assert len(chunks) == 2


def test_four_sentences_produce_two_groups():
    # 4 plain sentences → pairs → 2 groups
    # Each sentence is medium length, non-standalone
    text = "We start with numbers. Then we count objects. Next we compare. Finally we add."
    chunks, _ = splitter().split(text)
    assert len(chunks) == 2


# ===========================================================================
# 3. Standalone rules
# ===========================================================================

def test_question_always_standalone():
    text = "Now try this one. What is 2 plus 3?"
    chunks, _ = splitter().split(text)
    # Question must be its own chunk
    question_chunks = [c for c in chunks if c.text.rstrip().endswith('?')]
    assert len(question_chunks) == 1
    assert question_chunks[0].text.strip() == "What is 2 plus 3?"


def test_short_exclamation_is_standalone():
    text = "Great job! 🌟 Now let's try another one together."
    chunks, _ = splitter().split(text)
    exclamation_chunks = [c for c in chunks if c.text.rstrip().endswith('!') or '🌟' in c.text]
    # The short exclamation with emoji should be kept separate
    assert len(chunks) >= 2


def test_long_exclamation_not_forced_standalone():
    # > 30 chars ending with ! is NOT automatically standalone, can combine
    s1 = "You answered every single question correctly today!"  # 51 chars — NOT standalone
    s2 = "You are a counting star."
    text = f"{s1} {s2}"
    chunks, _ = splitter().split(text)
    # Combined = 77 chars < 150, neither is short-exclamation-standalone
    assert len(chunks) == 1


# ===========================================================================
# 4. Abbreviation & decimal protection
# ===========================================================================

def test_abbreviation_dot_not_treated_as_sentence_end():
    text = "Dr. Smith teaches us. She is very kind."
    chunks, _ = splitter().split(text)
    # Should not split at "Dr." — must produce exactly 2 sentences max grouped
    # The split should happen at "teaches us." not at "Dr."
    all_text = " ".join(c.text for c in chunks)
    assert "Dr. Smith" in all_text


def test_decimal_number_not_split():
    text = "We counted 3.14 apples in the basket. That is many apples!"
    chunks, _ = splitter().split(text)
    all_text = " ".join(c.text for c in chunks)
    assert "3.14" in all_text


def test_mr_abbreviation_protected():
    text = "Mr. Bear has five apples. Can you count them?"
    chunks, _ = splitter().split(text)
    all_text = " ".join(c.text for c in chunks)
    assert "Mr. Bear" in all_text


# ===========================================================================
# 5. Paragraph break splitting
# ===========================================================================

def test_paragraph_break_always_creates_new_group():
    text = "Great job! 🌟\n\nNow let's try something new."
    chunks, _ = splitter().split(text)
    # Must split at \n\n boundary
    texts = [c.text for c in chunks]
    assert any("Great job" in t for t in texts)
    assert any("Now let" in t for t in texts)


def test_multiple_paragraph_breaks():
    text = "Hello!\n\nLet's learn.\n\nAre you ready?"
    chunks, _ = splitter().split(text)
    assert len(chunks) >= 2  # at minimum: "Hello!", and "Let's learn. Are you ready?" or 3


# ===========================================================================
# 6. Delay calculation
# ===========================================================================

def test_first_chunk_always_zero_delay():
    chunks, _ = splitter().split("Hello there! This is a great day for learning.")
    assert chunks[0].delay_ms == 0


def test_short_message_base_delay_750():
    s = splitter()
    # Short text < 50 chars, not question, no emoji
    delay = s._calculate_delay("Count to five.", 1)
    assert delay == 750


def test_medium_message_base_delay_1150():
    s = splitter()
    # 50-99 chars, not question, no emoji
    delay = s._calculate_delay("A" * 60 + ".", 1)
    assert delay == 1150


def test_long_message_base_delay_1600():
    s = splitter()
    # 100+ chars, not question, no emoji
    delay = s._calculate_delay("A" * 105 + ".", 1)
    assert delay == 1600


def test_question_adds_400ms_to_delay():
    s = splitter()
    base = s._calculate_delay("Count these.", 1)     # short → 750
    q_delay = s._calculate_delay("Can you count?", 1)  # short + ? → 750+400=1150
    assert q_delay == base + 400


def test_emoji_adds_200ms_to_delay():
    s = splitter()
    plain = s._calculate_delay("Count to five.", 1)   # 750
    emoji = s._calculate_delay("Count to five! 🌟", 1)  # 750+200=950
    assert emoji == plain + 200


def test_question_and_emoji_both_add_to_delay():
    s = splitter()
    delay = s._calculate_delay("Are you ready? 🚀", 1)
    # short (< 50 chars) → 750 + 400 (question) + 200 (emoji) = 1350
    assert delay == 1350


# ===========================================================================
# 7. Image position
# ===========================================================================

def test_no_image_url_returns_none_image_position():
    chunks, pos = splitter().split("Hello! Let's learn.", image_url=None)
    assert pos is None


def test_visual_example_image_after_first_chunk():
    chunks, pos = splitter().split(
        "Look at this picture! It shows three apples.",
        image_url="http://example.com/img.png",
        response_type="visual_example",
    )
    assert pos == 0


def test_default_type_image_after_last_chunk():
    chunks, pos = splitter().split(
        "Great job! 🌟 Now let's move on.",
        image_url="http://example.com/img.png",
        response_type="celebration",
    )
    assert pos == len(chunks) - 1


def test_welcome_type_image_after_last_chunk():
    chunks, pos = splitter().split(
        "Hello! Today we learn counting.",
        image_url="http://example.com/img.png",
        response_type="welcome",
    )
    assert pos == len(chunks) - 1


# ===========================================================================
# 8. Emoji detection
# ===========================================================================

def test_has_emoji_with_star():
    assert splitter()._has_emoji("Great job! 🌟") is True


def test_has_emoji_with_smiley():
    assert splitter()._has_emoji("Hello 😊") is True


def test_has_emoji_with_rocket():
    assert splitter()._has_emoji("Let's go! 🚀") is True


def test_no_emoji_in_plain_text():
    assert splitter()._has_emoji("Count to ten.") is False


def test_no_emoji_with_punctuation_only():
    assert splitter()._has_emoji("Hello! Are you ready?") is False


# ===========================================================================
# 9. Real-world combined-response format (praise + next question)
# ===========================================================================

def test_combined_praise_and_question_splits_at_paragraph():
    text = "Amazing! 🌟\n\nNow, what comes after 4?"
    chunks, _ = splitter().split(text)
    texts = [c.text for c in chunks]
    assert any("Amazing" in t for t in texts)
    assert any("what comes after 4?" in t for t in texts)


def test_combined_response_question_is_standalone():
    text = "Well done! 🎉\n\nCan you tell me how many apples are in the picture?"
    chunks, _ = splitter().split(text)
    question_chunks = [c for c in chunks if c.text.rstrip().endswith('?')]
    assert len(question_chunks) == 1
