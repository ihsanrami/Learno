from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.config import settings
from app.routes.dynamic_routes import session_router, lesson_router
from app.utils.exceptions import (
    SessionNotFoundError,
    SessionExpiredError,
    InvalidInputError,
    LessonNotAvailableError,
    AIServiceError
)

app = FastAPI(
    title=settings.APP_TITLE,
    description="AI-powered educational backend with comprehensive teaching",
    version="2.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

API_PREFIX = f"/api/{settings.API_VERSION}"

app.include_router(session_router, prefix=API_PREFIX)
app.include_router(lesson_router, prefix=API_PREFIX)


@app.exception_handler(SessionNotFoundError)
async def session_not_found_handler(request: Request, exc: SessionNotFoundError):
    return JSONResponse(
        status_code=404,
        content={
            "status": "error",
            "message": str(exc),
            "state": "SESSION_NOT_FOUND"
        }
    )


@app.exception_handler(SessionExpiredError)
async def session_expired_handler(request: Request, exc: SessionExpiredError):
    return JSONResponse(
        status_code=410,
        content={
            "status": "error",
            "message": str(exc),
            "state": "SESSION_EXPIRED"
        }
    )


@app.exception_handler(InvalidInputError)
async def invalid_input_handler(request: Request, exc: InvalidInputError):
    return JSONResponse(
        status_code=400,
        content={
            "status": "error",
            "message": str(exc),
            "state": "INVALID_INPUT"
        }
    )


@app.exception_handler(LessonNotAvailableError)
async def lesson_not_available_handler(request: Request, exc: LessonNotAvailableError):
    return JSONResponse(
        status_code=400,
        content={
            "status": "error",
            "message": str(exc),
            "state": "LESSON_NOT_AVAILABLE"
        }
    )


@app.exception_handler(AIServiceError)
async def ai_service_error_handler(request: Request, exc: AIServiceError):
    return JSONResponse(
        status_code=503,
        content={
            "status": "error",
            "message": str(exc),
            "state": "AI_SERVICE_ERROR"
        }
    )


@app.get("/")
async def root():
    return {
        "status": "success",
        "message": "Welcome to Learno Educational Backend v2.0",
        "data": {
            "version": "2.0.0",
            "api_docs": "/docs",
            "health": "healthy",
            "features": [
                "Comprehensive chapter teaching",
                "Concept-based learning",
                "Visual explanations with AI images",
                "Adaptive difficulty",
                "Full chapter coverage"
            ]
        }
    }


@app.get("/health")
async def health_check():
    return {
        "status": "success",
        "message": "Service is healthy",
        "data": None
    }


@app.get("/teaching-flow")
async def teaching_flow_info():
    return {
        "status": "success",
        "message": "Teaching Flow Documentation",
        "data": {
            "overview": "Learno teaches complete chapters with multiple concepts",
            "flow": {
                "1_start": "POST /api/v1/session/start - Begin lesson, get welcome",
                "2_continue": "POST /api/v1/lesson/continue - Progress through teaching phases",
                "3_respond": "POST /api/v1/lesson/respond - Answer questions",
                "4_silence": "POST /api/v1/lesson/silence - Handle silence",
                "5_end": "POST /api/v1/session/end - End lesson"
            },
            "teaching_phases_per_concept": [
                "INTRODUCTION - What we'll learn",
                "EXPLANATION - Teach the concept",
                "VISUAL_EXAMPLE - Show with image",
                "GUIDED_PRACTICE - Practice together",
                "INDEPENDENT_PRACTICE - Child tries alone",
                "MASTERY_CHECK - Verify understanding"
            ],
            "chapter_structure": [
                "WELCOME - Greet and overview",
                "TEACHING - All concepts (each with 6 phases)",
                "CHAPTER_REVIEW - Review questions",
                "CELEBRATION - Complete!"
            ],
            "notes": [
                "Call /continue after non-question responses",
                "Call /respond after questions",
                "Lesson doesn't end until all concepts mastered",
                "Images generated for visual teaching"
            ]
        }
    }
