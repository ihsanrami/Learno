import logging
from typing import Optional, Dict
from datetime import datetime, timedelta
import uuid

from app.config import settings
from app.utils.exceptions import SessionNotFoundError, SessionExpiredError

logger = logging.getLogger(__name__)


class Session:
    
    def __init__(self, grade: int, subject: str, lesson: str):
        self.session_id = str(uuid.uuid4())
        self.grade = grade
        self.subject = subject
        self.lesson = lesson
        self.created_at = datetime.now()
        self.last_activity = datetime.now()
        self.total_steps = 0
        self.is_complete = False
    
    def update_activity(self):
        self.last_activity = datetime.now()
    
    def is_expired(self) -> bool:
        timeout = timedelta(seconds=settings.SESSION_TIMEOUT_SECONDS)
        return datetime.now() - self.last_activity > timeout


class SessionService:
    
    def __init__(self):
        self._sessions: Dict[str, Session] = {}
        logger.info("SessionService initialized")
    
    def create_session(self, grade: int, subject: str, lesson: str) -> Session:
        session = Session(grade, subject, lesson)
        self._sessions[session.session_id] = session
        logger.info(f"Session created: {session.session_id}")
        return session
    
    def get_session(self, session_id: str) -> Session:
        session = self._sessions.get(session_id)
        
        if not session:
            raise SessionNotFoundError(f"Session not found: {session_id}")
        
        if session.is_expired():
            del self._sessions[session_id]
            raise SessionExpiredError(f"Session expired: {session_id}")
        
        session.update_activity()
        return session
    
    def update_session(self, session: Session):
        session.update_activity()
        self._sessions[session.session_id] = session
    
    def delete_session(self, session_id: str):
        if session_id in self._sessions:
            del self._sessions[session_id]
            logger.info(f"Session deleted: {session_id}")


_session_service: Optional[SessionService] = None


def get_session_service() -> SessionService:
    global _session_service
    if _session_service is None:
        _session_service = SessionService()
    return _session_service
