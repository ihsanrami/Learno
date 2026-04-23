"""
OpenAI Client for Learno Educational Backend
"""

import logging
from typing import List, Dict, Optional

import openai

from app.config import settings
from app.utils.exceptions import AIServiceError

logger = logging.getLogger(__name__)


class LearnoAIClient:
    """OpenAI API wrapper"""

    def __init__(self):
        # Validate API key
        if not settings.OPENAI_API_KEY:
            logger.error("OPENAI_API_KEY not configured!")
            raise AIServiceError("OpenAI API key is required. Please set OPENAI_API_KEY in .env")
        
        self.model = settings.OPENAI_MODEL
        self.max_tokens = settings.OPENAI_MAX_TOKENS
        self.temperature = settings.OPENAI_TEMPERATURE
        openai.api_key = settings.OPENAI_API_KEY
        logger.info(f"LearnoAIClient initialized with model: {self.model}")

    def generate_response(self, messages: List[Dict[str, str]]) -> str:
        """Generate response from OpenAI"""
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

    def generate_json_response(self, messages: List[Dict[str, str]]) -> str:
        """Generate a JSON-structured response from OpenAI (used for chapter generation)."""
        try:
            response = openai.chat.completions.create(
                model=self.model,
                messages=messages,
                max_tokens=4000,
                temperature=0.7,
                response_format={"type": "json_object"},
            )
            content = response.choices[0].message.content
            if not content:
                raise AIServiceError("Empty JSON response from OpenAI")
            return content.strip()
        except openai.AuthenticationError:
            raise AIServiceError("Invalid OpenAI API key")
        except openai.RateLimitError:
            raise AIServiceError("OpenAI rate limit exceeded")
        except openai.APIConnectionError:
            raise AIServiceError("Cannot reach OpenAI servers")
        except Exception as e:
            # Fallback: try without response_format (older model versions)
            logger.warning(f"JSON mode failed ({e}), retrying without response_format")
            return self.generate_response(messages)


_ai_client: Optional[LearnoAIClient] = None


def get_ai_client() -> LearnoAIClient:
    global _ai_client
    if _ai_client is None:
        _ai_client = LearnoAIClient()
    return _ai_client
