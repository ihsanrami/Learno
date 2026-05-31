"""
Custom Exceptions for Learno Educational Backend
"""


class SessionNotFoundError(Exception):
    """Raised when session doesn't exist"""
    pass


class SessionExpiredError(Exception):
    """Raised when session has expired"""
    pass


class InvalidInputError(Exception):
    """Raised when input is invalid"""
    pass


class LessonNotAvailableError(Exception):
    """Raised when lesson is not available"""
    pass


class AIServiceError(Exception):
    """Raised when AI service fails"""
    pass


class DailyLimitReachedError(Exception):
    """Raised when a child has reached their daily learning time limit."""
    def __init__(self, today_minutes: int, target_minutes: int):
        self.today_minutes = today_minutes
        self.target_minutes = target_minutes
        super().__init__(
            f"Daily limit reached: {today_minutes}/{target_minutes} minutes today"
        )


class GradeNotAllowedError(Exception):
    """Raised when a child tries to start a lesson above their own grade."""
    pass
