import logging
from typing import List, Dict, Optional

import openai

from app.config import settings
from app.utils.exceptions import AIServiceError

logger = logging.getLogger(__name__)


class LearnoAIClient:

    def __init__(self):
        if not settings.OPENAI_API_KEY:
            logger.error("OPENAI_API_KEY not configured!")
            raise AIServiceError("OpenAI API key is required. Please set OPENAI_API_KEY in .env")
        
        self.model = settings.OPENAI_MODEL
        self.max_tokens = settings.OPENAI_MAX_TOKENS
        self.temperature = settings.OPENAI_TEMPERATURE
        openai.api_key = settings.OPENAI_API_KEY
        logger.info(f"LearnoAIClient initialized with model: {self.model}")

    def generate_response(self, messages: List[Dict[str, str]]) -> str:
        try:
            response = openai.chat.completions.create(
                model=self.model,
                messages=messages,
                max_tokens=self.max_tokens,
                temperature=self.temperature,
            )

            content = response.choices[0].message.content
            if not content:
                raise AIServiceError("Empty response from OpenAI")

            return content.strip()

        except openai.AuthenticationError:
            raise AIServiceError("Invalid OpenAI API key")
        except openai.RateLimitError:
            raise AIServiceError("OpenAI rate limit exceeded")
        except openai.APIConnectionError:
            raise AIServiceError("Cannot reach OpenAI servers")
        except Exception as e:
            logger.exception("OpenAI error")
            raise AIServiceError(f"OpenAI request failed: {str(e)}")


_ai_client: Optional[LearnoAIClient] = None


def get_ai_client() -> LearnoAIClient:
    global _ai_client
    if _ai_client is None:
        _ai_client = LearnoAIClient()
    return _ai_client
