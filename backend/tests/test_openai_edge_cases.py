"""
Tests for OpenAI client edge cases and error handling.

All tests mock the openai library so no real API key is needed.
"""

import pytest
from unittest.mock import MagicMock, patch
import openai

from app.ai.openai_client import LearnoAIClient, get_ai_client
from app.utils.exceptions import AIServiceError


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _make_client():
    """Create a LearnoAIClient with a fake key (env already set in conftest)."""
    return LearnoAIClient()


MESSAGES = [{"role": "user", "content": "Hello"}]


# ---------------------------------------------------------------------------
# Authentication errors
# ---------------------------------------------------------------------------

class TestAuthenticationErrors:
    def test_missing_api_key_raises_at_init(self, monkeypatch):
        monkeypatch.setattr("app.config.settings.OPENAI_API_KEY", "")
        with pytest.raises(AIServiceError, match="API key"):
            LearnoAIClient()

    def test_invalid_key_raises_ai_service_error(self):
        client = _make_client()
        with patch.object(client._tts if hasattr(client, "_tts") else openai.chat.completions,
                          "create",
                          side_effect=openai.AuthenticationError(
                              message="Invalid", response=MagicMock(), body={}
                          )):
            with pytest.raises(AIServiceError, match="Invalid OpenAI API key"):
                with patch("openai.chat.completions.create",
                           side_effect=openai.AuthenticationError(
                               message="Invalid", response=MagicMock(), body={}
                           )):
                    client.generate_response(MESSAGES)


# ---------------------------------------------------------------------------
# Rate limit / quota
# ---------------------------------------------------------------------------

class TestRateLimitErrors:
    def test_rate_limit_raises_ai_service_error(self):
        client = _make_client()
        with patch("openai.chat.completions.create",
                   side_effect=openai.RateLimitError(
                       message="Rate limit", response=MagicMock(), body={}
                   )):
            with pytest.raises(AIServiceError, match="rate limit"):
                client.generate_response(MESSAGES)

    def test_rate_limit_json_mode(self):
        client = _make_client()
        with patch("openai.chat.completions.create",
                   side_effect=openai.RateLimitError(
                       message="Rate limit", response=MagicMock(), body={}
                   )):
            with pytest.raises(AIServiceError, match="rate limit"):
                client.generate_json_response(MESSAGES)


# ---------------------------------------------------------------------------
# Timeout errors
# ---------------------------------------------------------------------------

class TestTimeoutErrors:
    def test_timeout_raises_ai_service_error(self):
        client = _make_client()
        with patch("openai.chat.completions.create",
                   side_effect=openai.APITimeoutError(request=MagicMock())):
            with pytest.raises(AIServiceError, match="timed out"):
                client.generate_response(MESSAGES)

    def test_timeout_in_json_mode(self):
        client = _make_client()
        with patch("openai.chat.completions.create",
                   side_effect=openai.APITimeoutError(request=MagicMock())):
            with pytest.raises(AIServiceError, match="timed out"):
                client.generate_json_response(MESSAGES)


# ---------------------------------------------------------------------------
# Connection errors
# ---------------------------------------------------------------------------

class TestConnectionErrors:
    def test_connection_error_raises_ai_service_error(self):
        client = _make_client()
        with patch("openai.chat.completions.create",
                   side_effect=openai.APIConnectionError(request=MagicMock())):
            with pytest.raises(AIServiceError, match="reach OpenAI"):
                client.generate_response(MESSAGES)

    def test_connection_error_json_mode(self):
        client = _make_client()
        with patch("openai.chat.completions.create",
                   side_effect=openai.APIConnectionError(request=MagicMock())):
            with pytest.raises(AIServiceError, match="reach OpenAI"):
                client.generate_json_response(MESSAGES)


# ---------------------------------------------------------------------------
# Server errors (500)
# ---------------------------------------------------------------------------

class TestInternalServerErrors:
    def test_server_error_raises_ai_service_error(self):
        client = _make_client()
        with patch("openai.chat.completions.create",
                   side_effect=openai.InternalServerError(
                       message="Server error", response=MagicMock(), body={}
                   )):
            with pytest.raises(AIServiceError, match="server error"):
                client.generate_response(MESSAGES)

    def test_server_error_json_mode(self):
        client = _make_client()
        with patch("openai.chat.completions.create",
                   side_effect=openai.InternalServerError(
                       message="Server error", response=MagicMock(), body={}
                   )):
            with pytest.raises(AIServiceError, match="server error"):
                client.generate_json_response(MESSAGES)


# ---------------------------------------------------------------------------
# Empty response
# ---------------------------------------------------------------------------

class TestEmptyResponse:
    def _mock_response(self, content):
        mock_resp = MagicMock()
        mock_resp.choices[0].message.content = content
        return mock_resp

    def test_empty_content_raises_ai_service_error(self):
        client = _make_client()
        with patch("openai.chat.completions.create", return_value=self._mock_response("")):
            with pytest.raises(AIServiceError, match="Empty response"):
                client.generate_response(MESSAGES)

    def test_none_content_raises_ai_service_error(self):
        client = _make_client()
        with patch("openai.chat.completions.create", return_value=self._mock_response(None)):
            with pytest.raises(AIServiceError, match="Empty response"):
                client.generate_response(MESSAGES)

    def test_empty_json_content_raises(self):
        client = _make_client()
        with patch("openai.chat.completions.create", return_value=self._mock_response("")):
            with pytest.raises(AIServiceError, match="Empty"):
                client.generate_json_response(MESSAGES)


# ---------------------------------------------------------------------------
# Successful responses
# ---------------------------------------------------------------------------

class TestSuccessfulResponses:
    def _mock_response(self, content):
        mock_resp = MagicMock()
        mock_resp.choices[0].message.content = content
        return mock_resp

    def test_normal_response_returned(self):
        client = _make_client()
        with patch("openai.chat.completions.create",
                   return_value=self._mock_response("  Hello!  ")):
            result = client.generate_response(MESSAGES)
        assert result == "Hello!"

    def test_json_response_returned(self):
        client = _make_client()
        with patch("openai.chat.completions.create",
                   return_value=self._mock_response('{"key": "value"}')):
            result = client.generate_json_response(MESSAGES)
        assert result == '{"key": "value"}'

    def test_json_fallback_on_mode_failure(self):
        """If JSON mode fails with a generic error, retries without response_format."""
        client = _make_client()
        call_count = {"n": 0}

        def side_effect(**kwargs):
            call_count["n"] += 1
            if kwargs.get("response_format"):
                raise Exception("json_mode_not_supported")
            mock_resp = MagicMock()
            mock_resp.choices[0].message.content = "fallback text"
            return mock_resp

        with patch("openai.chat.completions.create", side_effect=side_effect):
            result = client.generate_json_response(MESSAGES)
        assert result == "fallback text"
        assert call_count["n"] == 2  # first attempt + retry


# ---------------------------------------------------------------------------
# Singleton
# ---------------------------------------------------------------------------

class TestSingleton:
    def test_get_ai_client_returns_same_instance(self):
        c1 = get_ai_client()
        c2 = get_ai_client()
        assert c1 is c2
