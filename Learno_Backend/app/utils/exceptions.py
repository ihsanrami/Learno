class SessionNotFoundError(Exception):
    pass


class SessionExpiredError(Exception):
    pass


class InvalidInputError(Exception):
    pass


class LessonNotAvailableError(Exception):
    pass


class AIServiceError(Exception):
    pass
