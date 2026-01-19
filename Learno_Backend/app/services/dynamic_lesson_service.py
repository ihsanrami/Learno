
import logging
import re
from typing import Tuple, Optional, Dict, List
from dataclasses import dataclass, field

from app.models.lesson_content import (
    ChapterContent, ConceptContent, PracticeQuestion,
    ConceptPhase, LessonPhase,
    get_chapter, is_chapter_available
)
from app.services.session_service import get_session_service
from app.services.image_service import get_image_service
from app.ai.openai_client import get_ai_client
from app.ai.dynamic_prompt_builder import (
    build_welcome_prompt,
    build_concept_introduction_prompt,
    build_explanation_prompt,
    build_visual_explanation_prompt,
    build_guided_practice_prompt,
    build_independent_practice_prompt,
    build_mastery_check_prompt,
    build_chapter_review_prompt,
    build_celebration_prompt,
    build_hint_prompt,
    build_encouragement_prompt
)
from app.utils.exceptions import LessonNotAvailableError

logger = logging.getLogger(__name__)
@dataclass
class TeachingState:
    """Tracks where we are in teaching the chapter"""
    lesson_phase: LessonPhase = LessonPhase.WELCOME
    current_concept_index: int = 0
    concept_phase: ConceptPhase = ConceptPhase.INTRODUCTION
    
    guided_question_index: int = 0
    independent_question_index: int = 0
    review_question_index: int = 0
    
    current_attempts: int = 0
    total_correct: int = 0
    total_wrong: int = 0
    
    consecutive_wrong: int = 0
    needs_extra_help: bool = False
    
    current_expected_answer: Optional[str] = None
    current_acceptable_answers: List[str] = field(default_factory=list)
    current_hint: str = ""
    
    def reset_attempts(self):
        self.current_attempts = 0
        self.consecutive_wrong = 0
    
    def record_correct(self):
        self.total_correct += 1
        self.consecutive_wrong = 0
        self.needs_extra_help = False
    
    def record_wrong(self):
        self.total_wrong += 1
        self.current_attempts += 1
        self.consecutive_wrong += 1
        if self.consecutive_wrong >= 3:
            self.needs_extra_help = True
@dataclass 
class LearnoResponse:
    """Response from Learno"""
    text: str
    response_type: str
    image_url: Optional[str] = None
    is_lesson_complete: bool = False
    progress_info: Optional[Dict] = None
class DynamicLessonService:
    """Manages comprehensive teaching flow."""
    
    def __init__(self):
        self.session_service = get_session_service()
        self.image_service = get_image_service()
        self.ai_client = get_ai_client()
        self._teaching_states: Dict[str, TeachingState] = {}
        logger.info("DynamicLessonService initialized")
    
    def _get_state(self, session_id: str) -> TeachingState:
        if session_id not in self._teaching_states:
            self._teaching_states[session_id] = TeachingState()
        return self._teaching_states[session_id]
    
    def _get_progress_info(self, state: TeachingState, chapter: ChapterContent) -> Dict:
        return {
            "lesson_phase": state.lesson_phase.value,
            "current_concept": state.current_concept_index + 1,
            "total_concepts": chapter.total_concepts,
            "concept_phase": state.concept_phase.value,
            "total_correct": state.total_correct,
            "total_wrong": state.total_wrong
        }
    
    def start_lesson(self, grade: int, subject: str, lesson: str) -> Tuple[any, LearnoResponse]:
        """Start a new comprehensive lesson"""
        
        if not is_chapter_available(grade, subject, lesson):
            raise LessonNotAvailableError(
                "Only Grade 2 → Math → Counting is available for now."
            )
        
        session = self.session_service.create_session(grade, subject, lesson)
        chapter = get_chapter(lesson) or get_chapter("counting")
        
        state = self._get_state(session.session_id)
        state.lesson_phase = LessonPhase.WELCOME
        
        messages = build_welcome_prompt(
            chapter_title=chapter.chapter_title,
            welcome_script=chapter.welcome_script,
            chapter_overview=chapter.chapter_overview
        )
        
        ai_text = self.ai_client.generate_response(messages)
        clean_text, image_url = self._process_response(ai_text)
        
        state.lesson_phase = LessonPhase.TEACHING
        state.current_concept_index = 0
        state.concept_phase = ConceptPhase.INTRODUCTION
        
        session.total_steps = chapter.total_concepts * 6
        self.session_service.update_session(session)
        
        return session, LearnoResponse(
            text=clean_text,
            response_type="welcome",
            image_url=image_url,
            progress_info=self._get_progress_info(state, chapter)
        )
    
    def continue_teaching(self, session_id: str) -> LearnoResponse:
        """Continue to next teaching step"""
        
        session = self.session_service.get_session(session_id)
        state = self._get_state(session_id)
        chapter = get_chapter(session.lesson) or get_chapter("counting")
        
        if state.current_concept_index >= chapter.total_concepts:
            if state.lesson_phase != LessonPhase.CHAPTER_REVIEW:
                state.lesson_phase = LessonPhase.CHAPTER_REVIEW
                state.review_question_index = 0
            return self._do_chapter_review(session_id, state, chapter)
        
        concept = chapter.concepts[state.current_concept_index]
        
        if state.concept_phase == ConceptPhase.INTRODUCTION:
            return self._do_introduction(session_id, state, concept, chapter)
        elif state.concept_phase == ConceptPhase.EXPLANATION:
            return self._do_explanation(session_id, state, concept, chapter)
        elif state.concept_phase == ConceptPhase.VISUAL_EXAMPLE:
            return self._do_visual_example(session_id, state, concept, chapter)
        elif state.concept_phase == ConceptPhase.GUIDED_PRACTICE:
            return self._do_guided_practice(session_id, state, concept, chapter)
        elif state.concept_phase == ConceptPhase.INDEPENDENT_PRACTICE:
            return self._do_independent_practice(session_id, state, concept, chapter)
        elif state.concept_phase == ConceptPhase.CONCEPT_CHECK:
            return self._do_mastery_check(session_id, state, concept, chapter)
        elif state.concept_phase == ConceptPhase.COMPLETED:
            state.current_concept_index += 1
            state.concept_phase = ConceptPhase.INTRODUCTION
            state.reset_attempts()
            return self.continue_teaching(session_id)
        
        return self._do_introduction(session_id, state, concept, chapter)
    
    def _do_introduction(self, session_id: str, state: TeachingState, 
                         concept: ConceptContent, chapter: ChapterContent) -> LearnoResponse:
        messages = build_concept_introduction_prompt(
            concept_name=concept.concept_name,
            learning_objective=concept.learning_objective,
            introduction_script=concept.introduction_script
        )
        ai_text = self.ai_client.generate_response(messages)
        clean_text, image_url = self._process_response(ai_text)
        
        state.concept_phase = ConceptPhase.EXPLANATION
        
        return LearnoResponse(
            text=clean_text,
            response_type="concept_introduction",
            image_url=image_url,
            progress_info=self._get_progress_info(state, chapter)
        )
    
    def _do_explanation(self, session_id: str, state: TeachingState,
                        concept: ConceptContent, chapter: ChapterContent) -> LearnoResponse:
        messages = build_explanation_prompt(
            concept_name=concept.concept_name,
            explanation_script=concept.explanation_script,
            key_points=concept.key_points,
            examples=concept.examples
        )
        ai_text = self.ai_client.generate_response(messages)
        clean_text, image_url = self._process_response(ai_text)
        
        state.concept_phase = ConceptPhase.VISUAL_EXAMPLE
        
        return LearnoResponse(
            text=clean_text,
            response_type="explanation",
            image_url=image_url,
            progress_info=self._get_progress_info(state, chapter)
        )
    
    def _do_visual_example(self, session_id: str, state: TeachingState,
                           concept: ConceptContent, chapter: ChapterContent) -> LearnoResponse:
        messages = build_visual_explanation_prompt(
            concept_name=concept.concept_name,
            visual_description=concept.visual_description,
            visual_explanation=concept.visual_explanation
        )
        ai_text = self.ai_client.generate_response(messages)
        clean_text = self.image_service.remove_image_marker(ai_text)
        
        logger.info(f"🖼️ Generating visual for: {concept.concept_name}")
        image_url, error = self.image_service.generate_image_sync(concept.visual_description)
        if error:
            logger.error(f"❌ Visual image FAILED: {error}")
        elif image_url:
            logger.info(f"✅ Visual image SUCCESS! URL length: {len(image_url)}")
        else:
            logger.error("❌ No image_url and no error - something wrong!")
        
        state.concept_phase = ConceptPhase.GUIDED_PRACTICE
        state.guided_question_index = 0
        
        return LearnoResponse(
            text=clean_text,
            response_type="visual_example",
            image_url=image_url,
            progress_info=self._get_progress_info(state, chapter)
        )
    
    def _do_guided_practice(self, session_id: str, state: TeachingState,
                            concept: ConceptContent, chapter: ChapterContent) -> LearnoResponse:
        if state.guided_question_index >= len(concept.guided_questions):
            state.concept_phase = ConceptPhase.INDEPENDENT_PRACTICE
            state.independent_question_index = 0
            return self._do_independent_practice(session_id, state, concept, chapter)
        
        question = concept.guided_questions[state.guided_question_index]
        
        messages = build_guided_practice_prompt(
            question=question,
            concept_name=concept.concept_name,
            is_first=(state.guided_question_index == 0)
        )
        ai_text = self.ai_client.generate_response(messages)
        clean_text, image_url = self._process_response(ai_text, question.image_prompt)
        
        state.current_expected_answer = question.expected_answer
        state.current_acceptable_answers = question.acceptable_answers
        state.current_hint = question.hint_text
        
        return LearnoResponse(
            text=clean_text,
            response_type="guided_practice",
            image_url=image_url,
            progress_info=self._get_progress_info(state, chapter)
        )
    
    def _do_independent_practice(self, session_id: str, state: TeachingState,
                                  concept: ConceptContent, chapter: ChapterContent) -> LearnoResponse:
        if state.independent_question_index >= len(concept.independent_questions):
            state.concept_phase = ConceptPhase.CONCEPT_CHECK
            return self._do_mastery_check(session_id, state, concept, chapter)
        
        question = concept.independent_questions[state.independent_question_index]
        
        messages = build_independent_practice_prompt(
            question=question,
            concept_name=concept.concept_name,
            question_number=state.independent_question_index + 1,
            total_questions=len(concept.independent_questions)
        )
        ai_text = self.ai_client.generate_response(messages)
        clean_text, image_url = self._process_response(ai_text, question.image_prompt)
        
        state.current_expected_answer = question.expected_answer
        state.current_acceptable_answers = question.acceptable_answers
        state.current_hint = question.hint_text
        
        return LearnoResponse(
            text=clean_text,
            response_type="independent_practice",
            image_url=image_url,
            progress_info=self._get_progress_info(state, chapter)
        )
    
    def _do_mastery_check(self, session_id: str, state: TeachingState,
                          concept: ConceptContent, chapter: ChapterContent) -> LearnoResponse:
        messages = build_mastery_check_prompt(
            concept_name=concept.concept_name,
            question=concept.mastery_check_question
        )
        ai_text = self.ai_client.generate_response(messages)
        clean_text, image_url = self._process_response(ai_text)
        
        state.current_expected_answer = concept.mastery_answer
        state.current_acceptable_answers = concept.mastery_acceptable
        state.current_hint = "Think about what we just learned!"
        
        return LearnoResponse(
            text=clean_text,
            response_type="mastery_check",
            image_url=image_url,
            progress_info=self._get_progress_info(state, chapter)
        )
    
    def _do_chapter_review(self, session_id: str, state: TeachingState,
                           chapter: ChapterContent) -> LearnoResponse:
        if state.review_question_index >= len(chapter.review_questions):
            state.lesson_phase = LessonPhase.CELEBRATION
            return self._do_celebration(session_id, state, chapter)
        
        question = chapter.review_questions[state.review_question_index]
        
        messages = build_chapter_review_prompt(
            question=question,
            question_number=state.review_question_index + 1,
            total_questions=len(chapter.review_questions)
        )
        ai_text = self.ai_client.generate_response(messages)
        clean_text, image_url = self._process_response(ai_text)
        
        state.current_expected_answer = question.expected_answer
        state.current_acceptable_answers = question.acceptable_answers
        state.current_hint = question.hint_text
        
        return LearnoResponse(
            text=clean_text,
            response_type="chapter_review",
            image_url=image_url,
            progress_info=self._get_progress_info(state, chapter)
        )
    
    def _do_celebration(self, session_id: str, state: TeachingState,
                        chapter: ChapterContent) -> LearnoResponse:
        messages = build_celebration_prompt(
            completion_script=chapter.completion_script,
            total_correct=state.total_correct,
            total_questions=state.total_correct + state.total_wrong
        )
        ai_text = self.ai_client.generate_response(messages)
        clean_text, image_url = self._process_response(ai_text)
        
        if not image_url:
            img_url, error = self.image_service.generate_image_sync(
                "Celebration scene with confetti, stars, trophy, cartoon style"
            )
            if img_url:
                image_url = img_url
            elif error:
                logger.warning(f"Celebration image generation failed: {error}")
        
        state.lesson_phase = LessonPhase.COMPLETED
        
        return LearnoResponse(
            text=clean_text,
            response_type="celebration",
            image_url=image_url,
            is_lesson_complete=True,
            progress_info=self._get_progress_info(state, chapter)
        )
    
    def process_response(self, session_id: str, transcript: str) -> LearnoResponse:
        """Process child's answer"""
        
        session = self.session_service.get_session(session_id)
        state = self._get_state(session_id)
        chapter = get_chapter(session.lesson) or get_chapter("counting")
        
        is_correct = self._evaluate_answer(transcript, state)
        
        if is_correct:
            state.record_correct()
            return self._handle_correct_answer(session_id, state, chapter)
        else:
            state.record_wrong()
            return self._handle_wrong_answer(session_id, state, chapter, transcript)
    
    def _evaluate_answer(self, transcript: str, state: TeachingState) -> bool:
        """Check if answer is correct"""
        if not state.current_expected_answer:
            return True
        
        normalized = transcript.lower().strip()
        
        if normalized == state.current_expected_answer.lower():
            return True
        
        for acceptable in state.current_acceptable_answers:
            if acceptable.lower() in normalized or normalized in acceptable.lower():
                return True
        
        numbers = re.findall(r'\d+', transcript)
        if numbers and state.current_expected_answer in numbers:
            return True
        
        return False
    
    def _handle_correct_answer(self, session_id: str, state: TeachingState,
                                chapter: ChapterContent) -> LearnoResponse:
        concept = None
        if state.current_concept_index < chapter.total_concepts:
            concept = chapter.concepts[state.current_concept_index]
        
        phrases = concept.encouragement_phrases if concept else ["Great job! 🎉"]
        messages = build_encouragement_prompt(is_correct=True, encouragement_phrases=phrases)
        ai_text = self.ai_client.generate_response(messages)
        praise_text, _ = self._process_response(ai_text)
        
        self._advance_after_correct(state)
        next_response = self.continue_teaching(session_id)
        
        combined_text = f"{praise_text}\n\n{next_response.text}"
        
        return LearnoResponse(
            text=combined_text,
            response_type=next_response.response_type,
            image_url=next_response.image_url,
            is_lesson_complete=next_response.is_lesson_complete,
            progress_info=next_response.progress_info
        )
    
    def _handle_wrong_answer(self, session_id: str, state: TeachingState,
                              chapter: ChapterContent, transcript: str) -> LearnoResponse:
        messages = build_hint_prompt(
            child_answer=transcript,
            expected_answer=state.current_expected_answer or "",
            hint_text=state.current_hint,
            attempt_count=state.current_attempts,
            needs_extra_help=state.needs_extra_help
        )
        ai_text = self.ai_client.generate_response(messages)
        clean_text, image_url = self._process_response(ai_text)
        
        return LearnoResponse(
            text=clean_text,
            response_type="hint",
            image_url=image_url,
            progress_info=self._get_progress_info(state, chapter)
        )
    
    def _advance_after_correct(self, state: TeachingState):
        state.reset_attempts()
        
        if state.concept_phase == ConceptPhase.GUIDED_PRACTICE:
            state.guided_question_index += 1
        elif state.concept_phase == ConceptPhase.INDEPENDENT_PRACTICE:
            state.independent_question_index += 1
        elif state.concept_phase == ConceptPhase.CONCEPT_CHECK:
            state.concept_phase = ConceptPhase.COMPLETED
        elif state.lesson_phase == LessonPhase.CHAPTER_REVIEW:
            state.review_question_index += 1
    
    def handle_silence(self, session_id: str, duration: float) -> LearnoResponse:
        session = self.session_service.get_session(session_id)
        state = self._get_state(session_id)
        chapter = get_chapter(session.lesson) or get_chapter("counting")
        
        hint_text = state.current_hint or "Take your time! You can do it! 😊"
        
        messages = build_hint_prompt(
            child_answer="",
            expected_answer=state.current_expected_answer or "",
            hint_text=hint_text,
            attempt_count=0,
            needs_extra_help=False,
            is_silence=True
        )
        ai_text = self.ai_client.generate_response(messages)
        clean_text, image_url = self._process_response(ai_text)
        
        return LearnoResponse(
            text=clean_text,
            response_type="silence_hint",
            image_url=image_url,
            progress_info=self._get_progress_info(state, chapter)
        )
    
    def _process_response(self, ai_text: str, force_image_prompt: str = None) -> Tuple[str, Optional[str]]:
        image_url = None
        clean_text = ai_text
        
        image_desc = self.image_service.extract_image_request(ai_text)
        if image_desc:
            clean_text = self.image_service.remove_image_marker(ai_text)
            img_url, error = self.image_service.generate_image_sync(image_desc)
            if img_url:
                image_url = img_url
            elif error:
                logger.warning(f"Image generation failed: {error}")
        elif force_image_prompt:
            img_url, error = self.image_service.generate_image_sync(force_image_prompt)
            if img_url:
                image_url = img_url
            elif error:
                logger.warning(f"Forced image generation failed: {error}")
        
        return clean_text, image_url
    
    def end_lesson(self, session_id: str) -> Tuple[Dict, str]:
        state = self._get_state(session_id)
        
        summary = {
            "concepts_completed": state.current_concept_index,
            "total_correct": state.total_correct,
            "total_wrong": state.total_wrong,
            "is_complete": state.lesson_phase == LessonPhase.COMPLETED
        }
        
        message = "Great effort today! 🌟" if not summary["is_complete"] else "You completed the whole lesson! 🎉"
        
        if session_id in self._teaching_states:
            del self._teaching_states[session_id]
        
        self.session_service.delete_session(session_id)
        
        return summary, message
_dynamic_lesson_service: Optional[DynamicLessonService] = None
def get_dynamic_lesson_service() -> DynamicLessonService:
    global _dynamic_lesson_service
    if _dynamic_lesson_service is None:
        _dynamic_lesson_service = DynamicLessonService()
    return _dynamic_lesson_service
