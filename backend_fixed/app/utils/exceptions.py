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
