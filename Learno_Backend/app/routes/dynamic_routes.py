import logging
import re
from fastapi import APIRouter
from pydantic import BaseModel, validator
from typing import Optional

from app.services.dynamic_lesson_service import get_dynamic_lesson_service
from app.utils.exceptions import InvalidInputError

logger = logging.getLogger(__name__)


class StartSessionRequest(BaseModel):
    student_id: str = "default"
    student_name: str = "Student"
    grade: int
    subject: str
    lesson: str
    force_new: bool = False
    
    @validator('student_id')
    def validate_student_id(cls, v):
        if not v or not v.strip():
            return "default"
        return re.sub(r'[<>"\'/\\]', '', v.strip())[:100]
    
    @validator('student_name')
    def validate_student_name(cls, v):
        if not v or not v.strip():
            return "Student"
        return re.sub(r'[<>"\'/\\]', '', v.strip())[:50]
    
    @validator('subject', 'lesson')
    def validate_strings(cls, v):
        if not v or not v.strip():
            raise ValueError("Field cannot be empty")
        return re.sub(r'[<>"\'/\\]', '', v.strip())[:100]


class ContinueRequest(BaseModel):
    session_id: str
    
    @validator('session_id')
    def validate_session_id(cls, v):
        if not v or not v.strip():
            raise ValueError("session_id is required")
        return v.strip()


class ChildResponseRequest(BaseModel):
    session_id: str
    transcript: str
    confidence: Optional[float] = None
    duration: Optional[float] = None
    
    @validator('transcript')
    def validate_transcript(cls, v):
        if not v or not v.strip():
            raise ValueError("transcript is required")
        cleaned = re.sub(r'[<>]', '', v.strip())
        return cleaned[:500]


class SilenceNotificationRequest(BaseModel):
    session_id: str
    silence_duration: float
    
    @validator('silence_duration')
    def validate_duration(cls, v):
        if v <= 0:
            raise ValueError("silence_duration must be positive")
        if v > 300:
            v = 300
        return v


class EndSessionRequest(BaseModel):
    session_id: str


class LearnoResponseData(BaseModel):
    text: str
    response_type: str
    generated_image_url: Optional[str] = None


class ProgressData(BaseModel):
    lesson_phase: str
    current_concept: int
    total_concepts: int
    concept_phase: str
    total_correct: int
    total_wrong: int


class StudentAnalyticsData(BaseModel):
    learning_level: str = "developing"
    teaching_style: str = "standard"
    accuracy: float = 0.0


class LessonResponseData(BaseModel):
    learno_response: LearnoResponseData
    progress: Optional[ProgressData] = None
    is_complete: bool = False
    student_analytics: Optional[StudentAnalyticsData] = None


class StartSessionResponseData(BaseModel):
    session_id: str
    learno_response: LearnoResponseData
    progress: Optional[ProgressData] = None
    student_analytics: Optional[StudentAnalyticsData] = None


class StartSessionResponse(BaseModel):
    status: str
    message: str
    data: StartSessionResponseData


class DynamicLessonResponse(BaseModel):
    status: str
    message: str
    data: LessonResponseData


class EndSessionResponseData(BaseModel):
    concepts_completed: int
    total_correct: int
    total_wrong: int
    is_complete: bool


class EndSessionResponse(BaseModel):
    status: str
    message: str
    data: EndSessionResponseData


session_router = APIRouter(prefix="/session", tags=["Session Management"])


@session_router.post("/start", response_model=StartSessionResponse)
async def start_session(request: StartSessionRequest):
    logger.info(f"Starting lesson: student={request.student_id}, grade={request.grade}, subject={request.subject}, lesson={request.lesson}")
    
    service = get_dynamic_lesson_service()
    session, response = service.start_lesson(grade=request.grade, subject=request.subject, lesson=request.lesson)
    
    progress = None
    if response.progress_info:
        progress = ProgressData(
            lesson_phase=response.progress_info.get("lesson_phase", ""),
            current_concept=response.progress_info.get("current_concept", 0),
            total_concepts=response.progress_info.get("total_concepts", 0),
            concept_phase=response.progress_info.get("concept_phase", ""),
            total_correct=response.progress_info.get("total_correct", 0),
            total_wrong=response.progress_info.get("total_wrong", 0)
        )
    
    return StartSessionResponse(
        status="success",
        message="Lesson started successfully",
        data=StartSessionResponseData(
            session_id=session.session_id,
            learno_response=LearnoResponseData(
                text=response.text,
                response_type=response.response_type,
                generated_image_url=response.image_url
            ),
            progress=progress
        )
    )


@session_router.post("/end", response_model=EndSessionResponse)
async def end_session(request: EndSessionRequest):
    logger.info(f"Ending session: {request.session_id}")
    
    service = get_dynamic_lesson_service()
    summary, message = service.end_lesson(request.session_id)
    
    return EndSessionResponse(
        status="success",
        message=message,
        data=EndSessionResponseData(
            concepts_completed=summary.get("concepts_completed", 0),
            total_correct=summary.get("total_correct", 0),
            total_wrong=summary.get("total_wrong", 0),
            is_complete=summary.get("is_complete", False)
        )
    )


lesson_router = APIRouter(prefix="/lesson", tags=["Lesson Interaction"])


@lesson_router.post("/continue", response_model=DynamicLessonResponse)
async def continue_teaching(request: ContinueRequest):
    logger.info(f"Continuing lesson: {request.session_id}")
    
    service = get_dynamic_lesson_service()
    response = service.continue_teaching(request.session_id)
    
    progress = None
    if response.progress_info:
        progress = ProgressData(
            lesson_phase=response.progress_info.get("lesson_phase", ""),
            current_concept=response.progress_info.get("current_concept", 0),
            total_concepts=response.progress_info.get("total_concepts", 0),
            concept_phase=response.progress_info.get("concept_phase", ""),
            total_correct=response.progress_info.get("total_correct", 0),
            total_wrong=response.progress_info.get("total_wrong", 0)
        )
    
    return DynamicLessonResponse(
        status="success",
        message="Teaching continued",
        data=LessonResponseData(
            learno_response=LearnoResponseData(
                text=response.text,
                response_type=response.response_type,
                generated_image_url=response.image_url
            ),
            progress=progress,
            is_complete=response.is_lesson_complete
        )
    )


@lesson_router.post("/respond", response_model=DynamicLessonResponse)
async def respond_to_question(request: ChildResponseRequest):
    logger.info(f"Processing response: {request.session_id}")
    
    service = get_dynamic_lesson_service()
    response = service.process_response(session_id=request.session_id, transcript=request.transcript)
    
    progress = None
    if response.progress_info:
        progress = ProgressData(
            lesson_phase=response.progress_info.get("lesson_phase", ""),
            current_concept=response.progress_info.get("current_concept", 0),
            total_concepts=response.progress_info.get("total_concepts", 0),
            concept_phase=response.progress_info.get("concept_phase", ""),
            total_correct=response.progress_info.get("total_correct", 0),
            total_wrong=response.progress_info.get("total_wrong", 0)
        )
    
    return DynamicLessonResponse(
        status="success",
        message="Response processed",
        data=LessonResponseData(
            learno_response=LearnoResponseData(
                text=response.text,
                response_type=response.response_type,
                generated_image_url=response.image_url
            ),
            progress=progress,
            is_complete=response.is_lesson_complete
        )
    )


@lesson_router.post("/silence", response_model=DynamicLessonResponse)
async def handle_silence(request: SilenceNotificationRequest):
    logger.info(f"Handling silence: {request.session_id} - {request.silence_duration}s")
    
    service = get_dynamic_lesson_service()
    response = service.handle_silence(session_id=request.session_id, duration=request.silence_duration)
    
    progress = None
    if response.progress_info:
        progress = ProgressData(
            lesson_phase=response.progress_info.get("lesson_phase", ""),
            current_concept=response.progress_info.get("current_concept", 0),
            total_concepts=response.progress_info.get("total_concepts", 0),
            concept_phase=response.progress_info.get("concept_phase", ""),
            total_correct=response.progress_info.get("total_correct", 0),
            total_wrong=response.progress_info.get("total_wrong", 0)
        )
    
    return DynamicLessonResponse(
        status="success",
        message="Hint provided",
        data=LessonResponseData(
            learno_response=LearnoResponseData(
                text=response.text,
                response_type=response.response_type,
                generated_image_url=response.image_url
            ),
            progress=progress,
            is_complete=False
        )
    )
