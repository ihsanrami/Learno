"""AI-driven conversational tutoring service — full history sent to GPT-4o each turn."""

import logging
from concurrent.futures import ThreadPoolExecutor
from dataclasses import dataclass, field
from typing import Any, List, Dict, Tuple, Optional

from app.services.session_service import get_session_service
from app.services.image_service import get_image_service
from app.services.message_splitter import get_message_splitter
from app.ai.openai_client import get_ai_client
from app.ai.conversational_prompt_builder import (
    build_conversational_prompt,
    determine_lesson_language,
)
from app.ai.chapter_generator import generate_chapter
from app.models.curriculum import is_valid_topic, find_topic_by_name, get_topic
from app.models.lesson_content import is_chapter_available, get_chapter
from app.utils.exceptions import LessonNotAvailableError, DailyLimitReachedError, GradeNotAllowedError
from app.database.session import SessionLocal
from app.auth.models import ChildProfile
import app.services.analytics_service as analytics_svc

# Grade ordering used for the backend access guard.
_GRADE_ORDER = {
    "kindergarten": 0,
    "first": 1,
    "second": 2,
    "third": 3,
    "fourth": 4,
}

logger = logging.getLogger(__name__)

# Shared executor for background DALL-E calls — max 2 simultaneous generations.
_image_executor = ThreadPoolExecutor(max_workers=2)


@dataclass
class LearnoResponse:
    text: str
    response_type: str
    lesson_language: str = "en"
    image_url: Optional[str] = None
    is_lesson_complete: bool = False
    progress_info: Optional[Dict] = None
    messages: List = field(default_factory=list)
    image_position: Optional[int] = None


@dataclass
class ConversationContext:
    """Per-session conversational state — replaces TeachingState."""
    child_name: str
    grade: int
    subject: str
    topic: str
    lesson_language: str
    lesson_stage: str          # greeting | warmup | teaching | review | ended
    topic_info: dict
    conversation_history: List[Dict[str, str]] = field(default_factory=list)
    turn_count: int = 0
    total_turns: int = 0
    total_correct_signals: int = 0
    total_wrong_signals: int = 0
    teaching_turn_count: int = 0
    image_index: int = 0
    total_questions: int = 0
    pending_image_future: Any = field(default=None, compare=False, repr=False)


class ConversationalLessonService:
    """
    Each turn: build_conversational_prompt(full history) → GPT-4o → store in history.

    No pre-generated content. No rigid state machine.
    The AI decides what to say based on the full conversation context.
    """

    def __init__(self):
        self.session_service = get_session_service()
        self.image_service = get_image_service()
        self.ai_client = get_ai_client()
        self._splitter = get_message_splitter()
        self._contexts: Dict[str, ConversationContext] = {}
        self._analytics_map: Dict[str, tuple] = {}
        logger.info("ConversationalLessonService initialized")

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------

    def _get_context(self, session_id: str) -> ConversationContext:
        ctx = self._contexts.get(session_id)
        if not ctx:
            raise ValueError(f"No conversation context for session {session_id}")
        return ctx

    def _get_topic_info(self, grade: int, subject: str, lesson: str) -> dict:
        """
        Extract a lightweight topic guide from the chapter generator.
        We use ONLY concept names + key points — NOT pre-generated scripts or questions.
        The AI will teach in its own words based on this guide.
        """
        try:
            if is_chapter_available(grade, subject, lesson):
                chapter = get_chapter(lesson)
            else:
                topic = get_topic(grade, subject, lesson) or find_topic_by_name(grade, subject, lesson)
                chapter = generate_chapter(grade, subject, topic.topic_id, topic.name_en) if topic else None

            if chapter:
                return {
                    "title": chapter.chapter_title,
                    "concepts": [
                        {
                            "name": c.concept_name,
                            "objective": c.learning_objective,
                            "key_points": c.key_points[:3],
                        }
                        for c in chapter.concepts
                    ],
                }
        except Exception as e:
            logger.warning(f"Topic info load failed for {grade}/{subject}/{lesson}: {e}")

        return {
            "title": lesson,
            "concepts": [{"name": lesson, "objective": f"Learn about {lesson}", "key_points": []}],
        }

    def _make_response(
        self,
        text: str,
        response_type: str,
        lesson_language: str,
        is_lesson_complete: bool = False,
        image_url: Optional[str] = None,
    ) -> LearnoResponse:
        chunks, image_position = self._splitter.split(
            text=text,
            image_url=image_url,
            response_type=response_type,
        )
        return LearnoResponse(
            text=text,
            response_type=response_type,
            lesson_language=lesson_language,
            image_url=image_url,
            is_lesson_complete=is_lesson_complete,
            messages=chunks,
            image_position=image_position,
        )

    def _call_ai(self, ctx: ConversationContext, answer_eval: Optional[bool] = None) -> str:
        """Call GPT-4o with full conversational context."""
        messages = build_conversational_prompt(
            child_name=ctx.child_name,
            grade=ctx.grade,
            subject=ctx.subject,
            topic=ctx.topic,
            lesson_language=ctx.lesson_language,
            lesson_stage=ctx.lesson_stage,
            topic_info=ctx.topic_info,
            conversation_history=ctx.conversation_history,
            turn_count=ctx.turn_count,
            answer_eval=answer_eval,
        )
        logger.debug(f"[PROMPT] stage={ctx.lesson_stage} turn={ctx.turn_count}\n{messages[0]['content']}")
        ai_text = self.ai_client.generate_response(messages)
        logger.info(f"[RAW] stage={ctx.lesson_stage} turn={ctx.turn_count} >> {ai_text!r}")
        return ai_text

    @staticmethod
    def _parse_markers(text: str) -> Tuple[str, List[str]]:
        """Strip special control markers from AI text. Returns (clean_text, markers_found)."""
        markers_found = []
        clean = text
        for marker in ["[CORRECT]", "[WRONG]", "[END_SESSION]", "[START_REVIEW]", "[LESSON_COMPLETE]"]:
            if marker in clean:
                markers_found.append(marker)
                clean = clean.replace(marker, "").strip()
        return clean, markers_found

    @staticmethod
    def _child_signals_ready(transcript: str) -> bool:
        """Check if child's words indicate readiness to start the lesson."""
        lower = transcript.lower()
        signals = [
            "yes", "yeah", "yep", "sure", "ok", "okay", "ready", "let's", "lets",
            "go", "start", "begin",
            "نعم", "أيوه", "إي", "أه", "يلا", "بدي", "أبدأ", "أبدا", "جاهز", "جاهزة",
            "حسناً", "حسنا", "تمام", "زين",
        ]
        return any(s in lower for s in signals)

    def _evaluate_answer(self, child_answer: str, ai_question: str) -> Optional[bool]:
        """
        gpt-4o-mini eval: True=correct, False=wrong, None=unknown/skip.

        ai_question is the PREVIOUS AI message (the question the child was answering),
        not the current AI response after the child spoke.
        """
        eval_messages = [
            {"role": "system", "content": (
                "You are an educational evaluator for a children's tutoring app. "
                "Reply with ONLY the word YES or NO — nothing else. "
                "YES if the child's answer correctly addresses the teacher's question. "
                "NO if the child answered incorrectly or said something unrelated to the question."
            )},
            {"role": "user", "content": (
                f"Teacher asked: {ai_question}\n\n"
                f"Child answered: {child_answer}"
            )},
        ]
        logger.info(
            f"[EVAL-PROMPT] q={ai_question[:100]!r} | ans={child_answer!r}"
        )
        result = self.ai_client.generate_eval_response(eval_messages)
        logger.info(f"[EVAL-RAW] {result!r}")
        upper = result.strip().upper()
        if upper.startswith("YES"):
            return True
        if upper.startswith("NO"):
            return False
        return None  # UNKNOWN — don't count either way

    @staticmethod
    def _build_image_description(ctx: "ConversationContext") -> str:
        """Build a DALL-E prompt from concept data, cycling by image_index."""
        concepts = ctx.topic_info.get("concepts", [])
        if concepts:
            idx = ctx.image_index % len(concepts)
            concept = concepts[idx]
            name = concept.get("name", ctx.topic)
            points = concept.get("key_points", [])
            kp = points[0] if points else ""
            if kp:
                return f"colorful cartoon illustration for children: {name}, {kp}"
            return f"colorful cartoon illustration for children: {name}"
        return f"colorful cartoon illustration for children learning {ctx.topic}"

    # ------------------------------------------------------------------
    # Public API — matches the interface expected by dynamic_routes.py
    # ------------------------------------------------------------------

    def start_lesson(
        self,
        grade: int,
        subject: str,
        lesson: str,
        child_name: str = "friend",
        app_language: str = "en",
        child_id: Optional[int] = None,
    ) -> Tuple[any, LearnoResponse]:
        """Start a new conversational lesson with a warm personal greeting."""

        if not is_chapter_available(grade, subject, lesson) and \
                not is_valid_topic(grade, subject, lesson):
            raise LessonNotAvailableError(
                f"Topic '{lesson}' not found for Grade {grade} / {subject}."
            )

        # Pre-flight checks — run before AI call or session creation to fail fast.
        # Both specific errors are explicitly re-raised so the generic except
        # below never swallows them.
        if child_id is not None:
            try:
                db = SessionLocal()
                try:
                    # Grade restriction: child may only access their own grade or lower.
                    child_profile = (
                        db.query(ChildProfile)
                        .filter(ChildProfile.id == child_id)
                        .first()
                    )
                    if child_profile:
                        child_grade_int = _GRADE_ORDER.get(
                            child_profile.grade.value, 0
                        )
                        if grade > child_grade_int:
                            raise GradeNotAllowedError()

                    # Daily time-limit check.
                    today_min, target_min = analytics_svc.get_today_minutes(db, child_id)
                    if target_min > 0 and today_min >= target_min:
                        raise DailyLimitReachedError(today_min, target_min)
                finally:
                    db.close()
            except (DailyLimitReachedError, GradeNotAllowedError):
                raise  # re-raise before the generic except can swallow it
            except Exception as e:
                logger.warning(f"Pre-flight check failed (non-fatal): {e}")

        lesson_language = determine_lesson_language(subject, app_language)
        topic_info = self._get_topic_info(grade, subject, lesson)
        session = self.session_service.create_session(grade, subject, lesson)

        ctx = ConversationContext(
            child_name=child_name,
            grade=grade,
            subject=subject,
            topic=lesson,
            lesson_language=lesson_language,
            lesson_stage="greeting",
            topic_info=topic_info,
        )
        self._contexts[session.session_id] = ctx

        # Generate the warm greeting — topic is NOT mentioned yet
        ai_text = self._call_ai(ctx)
        clean, _ = self._parse_markers(ai_text)

        ctx.conversation_history.append({"role": "assistant", "content": clean})
        ctx.turn_count += 1

        if child_id is not None:
            try:
                db = SessionLocal()
                try:
                    a_sess = analytics_svc.start_session(
                        db=db,
                        child_id=child_id,
                        grade=str(grade),
                        subject=subject,
                        topic_id=lesson,
                    )
                    self._analytics_map[session.session_id] = (child_id, a_sess.id)
                finally:
                    db.close()
            except Exception as e:
                logger.warning(f"Analytics start failed: {e}")

        return session, self._make_response(
            text=clean,
            response_type="greeting",
            lesson_language=lesson_language,
        )

    def process_response(self, session_id: str, transcript: str) -> LearnoResponse:
        """
        Process child's response.
        Full conversation history → GPT-4o → contextual next message.
        """
        ctx = self._get_context(session_id)
        ctx.total_turns += 1

        # Collect any background DALL-E result that finished since the last turn
        carry_image_url: Optional[str] = None
        if ctx.pending_image_future is not None:
            if ctx.pending_image_future.done():
                try:
                    result, err = ctx.pending_image_future.result()
                    if result:
                        carry_image_url = result
                        logger.info("[IMG] background DALL-E ready — delivering with this turn")
                    else:
                        logger.info(f"[IMG] background DALL-E done but failed — err={err}")
                except Exception as _exc:
                    logger.warning(f"[IMG] background DALL-E exception: {_exc}")
                ctx.pending_image_future = None
            else:
                logger.info("[IMG] background DALL-E still running — will retry next turn")

        # Remember stage BEFORE transitions so the eval doesn't misfire on warmup→teaching turns
        stage_before_transition = ctx.lesson_stage

        # Grab the last AI question from history (what the child was actually answering)
        last_ai_question = next(
            (m["content"] for m in reversed(ctx.conversation_history) if m["role"] == "assistant"),
            "",
        )

        # Add child's message to the conversation history
        ctx.conversation_history.append({"role": "user", "content": transcript})

        # Stage transitions
        if ctx.lesson_stage == "greeting":
            # After the first child response, move to warmup
            ctx.lesson_stage = "warmup"
        elif ctx.lesson_stage == "warmup":
            # Move to teaching if child signals readiness OR after enough warmup turns
            if self._child_signals_ready(transcript) or ctx.turn_count >= 5:
                ctx.lesson_stage = "teaching"

        # Run eval first (teaching/review only) so the result guides the main AI response
        answer_eval: Optional[bool] = None
        if stage_before_transition in ("teaching", "review") and transcript.strip():
            answer_eval = self._evaluate_answer(transcript, last_ai_question)
            if answer_eval is True:
                ctx.total_correct_signals += 1
                ctx.total_questions += 1
                logger.info(
                    f"[EVAL] YES — session={session_id} "
                    f"correct={ctx.total_correct_signals}/{ctx.total_questions}"
                )
            elif answer_eval is False:
                ctx.total_wrong_signals += 1
                ctx.total_questions += 1
                logger.info(
                    f"[EVAL] NO — session={session_id} "
                    f"wrong={ctx.total_wrong_signals}/{ctx.total_questions}"
                )
            else:
                logger.info(f"[EVAL] UNKNOWN — skipping this turn")

        # Call AI with full context — eval result guides correct/wrong response
        ai_text = self._call_ai(ctx, answer_eval=answer_eval)
        clean, markers = self._parse_markers(ai_text)

        # ── Image pipeline ──────────────────────────────────────────────
        # Priority 1: AI emitted [GENERATE_IMAGE] → synchronous this turn.
        # Priority 2: Backend trigger on odd teaching turns (1,3,5…) →
        #             background thread; result carried to the NEXT turn.
        image_url = None
        image_description = self.image_service.extract_image_request(clean)
        logger.info(
            f"[IMG] stage={ctx.lesson_stage} tch={ctx.teaching_turn_count} "
            f"AI-marker={'found' if image_description else 'none'} "
            f"pending={'yes' if ctx.pending_image_future is not None else 'no'}"
        )
        if image_description:
            # Priority 1: AI marker — synchronous generation, available this turn
            clean = self.image_service.remove_image_marker(clean)
            image_url, img_err = self.image_service.generate_image_sync(image_description)
            logger.info(f"[IMG] AI-marker DALL-E → url={'set' if image_url else 'None'} err={img_err}")
            if img_err:
                logger.warning(f"[IMG] AI-marker generation failed: {img_err}")
        elif ctx.lesson_stage == "teaching":
            ctx.teaching_turn_count += 1
            # Priority 2: backend trigger on odd teaching turns (1, 3, 5…)
            if ctx.teaching_turn_count % 2 == 1 and ctx.pending_image_future is None:
                desc = self._build_image_description(ctx)
                ctx.image_index += 1
                ctx.pending_image_future = _image_executor.submit(
                    self.image_service.generate_image_sync, desc
                )
                logger.info(
                    f"[IMG] backend trigger tch={ctx.teaching_turn_count} "
                    f"concept-idx={ctx.image_index - 1} desc={desc!r}"
                )
            else:
                logger.info(
                    f"[IMG] no backend trigger "
                    f"(tch={ctx.teaching_turn_count} "
                    f"pending={ctx.pending_image_future is not None})"
                )

        # Interpret markers
        is_complete = False
        rtype = "conversation"

        if "[END_SESSION]" in markers:
            ctx.lesson_stage = "ended"
            is_complete = True
            rtype = "session_ended"
        elif "[LESSON_COMPLETE]" in markers:
            ctx.lesson_stage = "ended"
            is_complete = True
            rtype = "celebration"
        elif "[START_REVIEW]" in markers:
            ctx.lesson_stage = "review"
            rtype = "review"

        ctx.conversation_history.append({"role": "assistant", "content": clean})
        ctx.turn_count += 1

        return self._make_response(
            text=clean,
            response_type=rtype,
            lesson_language=ctx.lesson_language,
            is_lesson_complete=is_complete,
            image_url=image_url or carry_image_url,
        )

    def handle_silence(self, session_id: str, duration: float) -> LearnoResponse:
        """
        Handle child silence — add silence marker to history and let AI respond naturally.
        The AI knows to be patient and gently check in.
        """
        ctx = self._get_context(session_id)

        # Add silence event to conversation history so AI sees it as context
        ctx.conversation_history.append({
            "role": "user",
            "content": f"[{ctx.child_name} has been silent for {int(duration)} seconds — no response]",
        })

        ai_text = self._call_ai(ctx)
        clean, markers = self._parse_markers(ai_text)

        is_complete = any(m in markers for m in ["[END_SESSION]", "[LESSON_COMPLETE]"])
        if is_complete:
            ctx.lesson_stage = "ended"

        ctx.conversation_history.append({"role": "assistant", "content": clean})
        ctx.turn_count += 1

        return self._make_response(
            text=clean,
            response_type="silence_response",
            lesson_language=ctx.lesson_language,
            is_lesson_complete=is_complete,
        )

    def continue_teaching(self, session_id: str) -> LearnoResponse:
        """
        Kept for API compatibility with /lesson/continue endpoint.
        In the conversational model this endpoint is not used — everything
        goes through process_response. Returns empty noop so old clients
        don't break.
        """
        ctx = self._get_context(session_id)
        return self._make_response(
            text="",
            response_type="noop",
            lesson_language=ctx.lesson_language,
        )

    def end_lesson(self, session_id: str) -> Tuple[Dict, str]:
        ctx = self._contexts.get(session_id)
        is_complete = ctx.lesson_stage == "ended" if ctx else False

        summary = {
            "concepts_completed": 0,
            "total_correct": ctx.total_correct_signals if ctx else 0,
            "total_wrong": ctx.total_wrong_signals if ctx else 0,
            "is_complete": is_complete,
        }
        message = "Great effort today! 🌟"

        if session_id in self._analytics_map:
            child_id, analytics_id = self._analytics_map.pop(session_id)
            try:
                db = SessionLocal()
                try:
                    analytics_svc.end_session(
                        db=db,
                        session_id=analytics_id,
                        questions_correct=ctx.total_correct_signals if ctx else 0,
                        questions_total=max(ctx.total_turns, 1) if ctx else 1,
                        concepts_completed=0,
                        concepts_total=len(ctx.topic_info.get("concepts", [])) if ctx else 0,
                        completed=is_complete,
                    )
                    analytics_svc.check_and_award_achievements(db, child_id)
                finally:
                    db.close()
            except Exception as e:
                logger.warning(f"Analytics end failed: {e}")

        if session_id in self._contexts:
            del self._contexts[session_id]
        self.session_service.delete_session(session_id)
        return summary, message


_service: Optional[ConversationalLessonService] = None


def get_conversational_lesson_service() -> ConversationalLessonService:
    global _service
    if _service is None:
        _service = ConversationalLessonService()
    return _service
