"""
=============================================================================
Message Splitter for Learno Educational Backend
=============================================================================
Splits AI-generated text into short, child-friendly message chunks with
natural pacing delays. Designed for children aged 4-10: short segments,
gentle timing, emoji-aware splitting, abbreviation-safe sentence detection.
=============================================================================
"""

import re
from dataclasses import dataclass
from typing import List, Optional, Tuple


@dataclass
class MessageChunk:
    """A single display-ready message segment with its pre-display delay."""
    text: str
    delay_ms: int


class MessageSplitter:
    """
    Splits long AI responses into a sequence of timed, child-friendly chunks.

    Splitting rules:
    - Paragraph breaks (\\n\\n) are always hard split boundaries.
    - Sentence boundaries respected via regex; abbreviations and decimals
      are protected from false splits.
    - Maximum 2 sentences per chunk, maximum 150 characters per chunk.
    - Questions (ending ?) always stand alone as isolated chunks.
    - Short exclamations <= 30 chars (greetings/praise) stand alone.
    """

    # Abbreviations whose trailing dot must not be treated as sentence end.
    ABBREVIATIONS: frozenset = frozenset({
        'mr', 'mrs', 'ms', 'dr', 'prof', 'sr', 'jr',
        'vs', 'st', 'no', 'fig', 'etc',
    })

    # Placeholder replaces protected dots so the split regex ignores them.
    _PLACEHOLDER = '\x00'

    def split(
        self,
        text: str,
        image_url: Optional[str] = None,
        response_type: str = "",
    ) -> Tuple[List[MessageChunk], Optional[int]]:
        """
        Split text into timed MessageChunks with image position.

        Args:
            text: Full AI-generated response text (may contain emojis).
            image_url: If provided, image_position is set in the output.
            response_type: Response type string; "visual_example" places
                           the image after the first chunk, all others after
                           the last chunk.

        Returns:
            Tuple of (chunks, image_position).
            image_position is the chunk index after which the image appears,
            or None when there is no image.
        """
        if not text or not text.strip():
            return [MessageChunk(text=text or "", delay_ms=0)], None

        # 1. Hard split on paragraph breaks (handles \n\n from combined responses).
        paragraphs = re.split(r'\n\n+', text.strip())

        all_sentences: List[str] = []
        for para in paragraphs:
            para = para.strip()
            if para:
                all_sentences.extend(self._split_sentences(para))

        if not all_sentences:
            return [MessageChunk(text=text.strip(), delay_ms=0)], None

        # 2. Group sentences into display chunks.
        groups = self._group_sentences(all_sentences)

        # 3. Assign delays.
        chunks = [
            MessageChunk(text=g, delay_ms=self._calculate_delay(g, i))
            for i, g in enumerate(groups)
        ]

        # 4. Determine image position.
        image_position: Optional[int] = None
        if image_url and chunks:
            if response_type == "visual_example":
                image_position = 0          # image appears after first chunk
            else:
                image_position = len(chunks) - 1   # image appears after last chunk

        return chunks, image_position

    # -------------------------------------------------------------------------
    # Sentence splitting
    # -------------------------------------------------------------------------

    def _split_sentences(self, paragraph: str) -> List[str]:
        """
        Split one paragraph into individual sentences.

        Protects known abbreviations (Mr., Dr.) and decimal numbers (3.14)
        from being mistaken for sentence boundaries.
        """
        text = paragraph

        # Protect abbreviation dots: "Dr." → "Dr\x00"
        def _protect(match: re.Match) -> str:
            return match.group(1) + self._PLACEHOLDER

        abbrev_pattern = r'\b(' + '|'.join(
            re.escape(a) for a in sorted(self.ABBREVIATIONS, key=len, reverse=True)
        ) + r')\.'
        text = re.sub(abbrev_pattern, _protect, text, flags=re.IGNORECASE)

        # Protect decimal numbers: "3.14" → "3\x004"
        text = re.sub(r'(\d)\.(\d)', r'\1' + self._PLACEHOLDER + r'\2', text)

        # Split on sentence-ending punctuation followed by whitespace.
        parts = re.split(r'(?<=[.!?])\s+', text)

        # Restore placeholder and filter empties.
        sentences = [
            part.replace(self._PLACEHOLDER, '.').strip()
            for part in parts
            if part.strip()
        ]

        return sentences if sentences else [paragraph.strip()]

    # -------------------------------------------------------------------------
    # Sentence grouping
    # -------------------------------------------------------------------------

    def _group_sentences(self, sentences: List[str]) -> List[str]:
        """
        Combine adjacent sentences into chunks within size/count limits.

        Combining rules:
        - Combined text must be <= 150 characters.
        - Neither sentence may be standalone (question or short exclamation).
        - At most 2 sentences per chunk.
        """
        groups: List[str] = []
        i = 0

        while i < len(sentences):
            s1 = sentences[i]

            if i + 1 < len(sentences):
                s2 = sentences[i + 1]
                combined = f"{s1} {s2}"
                can_combine = (
                    len(combined) <= 150
                    and not self._is_standalone(s1)
                    and not self._is_standalone(s2)
                )
                if can_combine:
                    groups.append(combined)
                    i += 2
                    continue

            groups.append(s1)
            i += 1

        return groups

    def _is_standalone(self, sentence: str) -> bool:
        """
        Return True if this sentence must not be combined with another.

        Standalone cases:
        - Ends with ? (question — child must respond), ignoring trailing emojis.
        - Short exclamation <= 30 chars ending with ! (greeting / praise).
        """
        last_punct = self._last_punctuation(sentence)
        if last_punct == '?':
            return True
        if last_punct == '!' and len(sentence.rstrip()) <= 30:
            return True
        return False

    def _last_punctuation(self, text: str) -> str:
        """
        Return the last meaningful punctuation character in text,
        skipping trailing whitespace and emoji-range characters.
        """
        for char in reversed(text.rstrip()):
            cp = ord(char)
            if (
                0x1F300 <= cp <= 0x1FAFF
                or 0x2600 <= cp <= 0x27BF
                or 0xFE00 <= cp <= 0xFE0F
                or char == ' '
            ):
                continue
            return char
        return ''

    # -------------------------------------------------------------------------
    # Delay calculation
    # -------------------------------------------------------------------------

    def _calculate_delay(self, chunk_text: str, index: int) -> int:
        """
        Calculate display delay in milliseconds before showing this chunk.

        Algorithm:
        - First chunk (index 0): always 0 ms (immediate).
        - Short  (<  50 chars): 750 ms base.
        - Medium (50–99 chars): 1 150 ms base.
        - Long  (100+ chars):  1 600 ms base.
        - Ends with ?:         +400 ms (child needs time to anticipate).
        - Contains emoji:      +200 ms (visual richness warrants a beat).
        """
        if index == 0:
            return 0

        length = len(chunk_text)

        if length < 50:
            base = 750
        elif length < 100:
            base = 1150
        else:
            base = 1600

        if self._last_punctuation(chunk_text) == '?':
            base += 400
        if self._has_emoji(chunk_text):
            base += 200

        return base

    # -------------------------------------------------------------------------
    # Emoji detection
    # -------------------------------------------------------------------------

    def _has_emoji(self, text: str) -> bool:
        """Return True if text contains any character in a recognised emoji range."""
        for char in text:
            cp = ord(char)
            if (
                0x1F300 <= cp <= 0x1FAFF   # emoticons, misc symbols, transport
                or 0x2600 <= cp <= 0x27BF  # misc symbols & dingbats
                or 0x1F000 <= cp <= 0x1F02F  # mahjong tiles
                or 0x1F0A0 <= cp <= 0x1F0FF  # playing cards
                or 0xFE00 <= cp <= 0xFE0F    # variation selectors / emoji modifiers
            ):
                return True
        return False


# =============================================================================
# Module-level singleton
# =============================================================================

_splitter: Optional[MessageSplitter] = None


def get_message_splitter() -> MessageSplitter:
    """Return the shared MessageSplitter singleton."""
    global _splitter
    if _splitter is None:
        _splitter = MessageSplitter()
    return _splitter
