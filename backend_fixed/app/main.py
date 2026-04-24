"""
=============================================================================
Main Application Entry Point for Learno Educational Backend
=============================================================================
UPDATED VERSION - Uses Dynamic Lesson System

Changes:
- Uses DynamicLessonService for comprehensive teaching
- New /lesson/continue endpoint for teaching flow
- Full chapter coverage with concept-based teaching
=============================================================================
"""

import logging
import os
import time

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.gzip import GZipMiddleware
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles
from slowapi import _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded

from app.config import settings
from app.routes.dynamic_routes import session_router, lesson_router, curriculum_router
from app.routes.auth_routes import router as auth_router
from app.routes.children_routes import router as children_router
from app.routes.parent_routes import router as parent_router
from app.utils.exceptions import (
    SessionNotFoundError,
    SessionExpiredError,
    InvalidInputError,
    LessonNotAvailableError,
    AIServiceError
)

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(name)s %(message)s",
)
logger = logging.getLogger(__name__)

_start_time = time.time()

# =============================================================================
# Create FastAPI Application
# =============================================================================

from app.rate_limiter import limiter

app = FastAPI(
    title=settings.APP_TITLE,
    description="AI-powered educational backend with comprehensive teaching",
    version="2.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json"
)

app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

app.add_middleware(GZipMiddleware, minimum_size=1000)


@app.middleware("http")
async def log_slow_requests(request: Request, call_next):
    t0 = time.perf_counter()
    response = await call_next(request)
    elapsed_ms = (time.perf_counter() - t0) * 1000
    if elapsed_ms > 1000:
        logger.warning(
            "SLOW REQUEST %.0fms %s %s",
            elapsed_ms,
            request.method,
            request.url.path,
        )
    return response


@app.on_event("startup")
async def startup():
    from app.database.session import engine
    from app.database.base import Base
    import app.auth.models  # noqa: F401 — register all models including analytics
    Base.metadata.create_all(bind=engine)
    logger.info("Learno backend started (v2.0.0)")

# =============================================================================
# Static Files (proxied AI-generated images)
# =============================================================================

os.makedirs("static/generated_images", exist_ok=True)
app.mount("/static", StaticFiles(directory="static"), name="static")

# =============================================================================
# CORS Middleware
# =============================================================================

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# =============================================================================
# Register Routers
# =============================================================================

API_PREFIX = f"/api/{settings.API_VERSION}"

app.include_router(session_router, prefix=API_PREFIX)
app.include_router(lesson_router, prefix=API_PREFIX)
app.include_router(curriculum_router, prefix=API_PREFIX)
app.include_router(auth_router, prefix=API_PREFIX)
app.include_router(children_router, prefix=API_PREFIX)
app.include_router(parent_router, prefix=API_PREFIX)


# =============================================================================
# Exception Handlers
# =============================================================================

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


# =============================================================================
# Root Endpoints
# =============================================================================

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
    from app.ai.chapter_generator import get_cache_stats
    uptime_seconds = int(time.time() - _start_time)
    return {
        "status": "success",
        "message": "Service is healthy",
        "data": {
            "version": "2.0.0",
            "uptime_seconds": uptime_seconds,
            "chapter_cache": get_cache_stats(),
        },
    }


@app.get("/api/v1/health")
async def api_health_check():
    from app.ai.chapter_generator import get_cache_stats
    uptime_seconds = int(time.time() - _start_time)
    return {
        "status": "success",
        "message": "Service is healthy",
        "data": {
            "version": "2.0.0",
            "uptime_seconds": uptime_seconds,
            "chapter_cache": get_cache_stats(),
        },
    }


# =============================================================================
# Teaching Flow Documentation
# =============================================================================

@app.get("/teaching-flow")
async def teaching_flow_info():
    """
    Documentation endpoint explaining the teaching flow.
    """
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
