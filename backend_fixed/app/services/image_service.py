"""
=============================================================================
Image Generation Service for Learno Educational Backend
=============================================================================
Handles AI image generation using OpenAI DALL-E API.

Features:
- Generate educational images from text descriptions
- Extract [GENERATE_IMAGE: ...] markers from AI responses
- Child-friendly, cartoon style images
- Caching to avoid regenerating same images

=============================================================================
"""

import logging
import re
import hashlib
import base64
from typing import Optional, Tuple
from pathlib import Path

import openai
from app.config import settings
from app.utils.exceptions import AIServiceError
from app.services.image_proxy import download_and_cache_sync, download_and_cache_async

logger = logging.getLogger(__name__)


class ImageGenerationService:
    """
    Service for generating educational images using DALL-E.
    """
    
    # Cache size limit to prevent memory leak
    MAX_CACHE_SIZE = 100
    
    def __init__(self):
        """Initialize the image generation service."""
        openai.api_key = settings.OPENAI_API_KEY
        
        # Image settings
        self.model = "dall-e-3"  # or "dall-e-2" for cheaper option
        self.size = "1024x1024"  # DALL-E 3 sizes: 1024x1024, 1792x1024, 1024x1792
        self.quality = "standard"  # "standard" or "hd"
        self.style = "vivid"  # "vivid" or "natural"
        self.timeout = 60  # Timeout in seconds
        
        # Cache directory for generated images
        self.cache_dir = Path("generated_images")
        self.cache_dir.mkdir(exist_ok=True)
        
        # In-memory cache for session (with size limit)
        self._cache: dict = {}
        
        logger.info("ImageGenerationService initialized with DALL-E")
    
    def extract_image_request(self, response_text: str) -> Optional[str]:
        """
        Extract image generation request from AI response.
        
        Looks for pattern: [GENERATE_IMAGE: description here]
        
        Args:
            response_text: The AI's response text
            
        Returns:
            Image description if found, None otherwise
        """
        pattern = r'\[GENERATE_IMAGE:\s*([^\]]+)\]'
        match = re.search(pattern, response_text, re.IGNORECASE)
        
        if match:
            description = match.group(1).strip()
            logger.debug(f"Found image request: {description}")
            return description
        
        return None
    
    def remove_image_marker(self, response_text: str) -> str:
        """
        Remove [GENERATE_IMAGE: ...] marker from response text.
        
        Used to clean text before TTS (don't speak the marker).
        
        Args:
            response_text: The AI's response text
            
        Returns:
            Cleaned text without the marker
        """
        pattern = r'\[GENERATE_IMAGE:\s*[^\]]+\]'
        cleaned = re.sub(pattern, '', response_text, flags=re.IGNORECASE)
        return cleaned.strip()
    
    def _get_cache_key(self, description: str) -> str:
        """Generate a cache key for the image description."""
        return hashlib.md5(description.lower().encode()).hexdigest()
    
    def _build_dalle_prompt(self, description: str) -> str:
        """
        Build an optimized prompt for DALL-E.
        
        Adds child-friendly styling requirements.
        """
        base_style = (
            "Create a simple, colorful, child-friendly cartoon illustration. "
            "Style: Bright colors, clean lines, friendly appearance, "
            "suitable for children ages 6-7. "
            "No text in the image. White or simple background. "
        )
        
        return f"{base_style}Content: {description}"
    
    async def generate_image(self, description: str) -> Tuple[Optional[str], Optional[str]]:
        """
        Generate an educational image using DALL-E.
        
        Args:
            description: What the image should show
            
        Returns:
            Tuple of (image_url, error_message)
            - If successful: (url, None)
            - If failed: (None, error_message)
        """
        # Check cache first
        cache_key = self._get_cache_key(description)
        if cache_key in self._cache:
            logger.info(f"Image found in cache: {cache_key}")
            return self._cache[cache_key], None
        
        try:
            # Build optimized prompt
            dalle_prompt = self._build_dalle_prompt(description)
            
            logger.info(f"Generating image: {description[:50]}...")
            
            # Call DALL-E API
            response = openai.images.generate(
                model=self.model,
                prompt=dalle_prompt,
                size=self.size,
                quality=self.quality,
                style=self.style,
                n=1,
                response_format="url"  # or "b64_json" for base64
            )
            
            # Extract URL
            dalle_url = response.data[0].url

            # Proxy: download immediately so the URL never expires
            proxied = await download_and_cache_async(dalle_url)
            image_url = proxied if proxied else dalle_url
            if not proxied:
                logger.warning("Image proxy failed; falling back to DALL-E URL")

            # Cache the result
            self._cache[cache_key] = image_url

            logger.info(f"Image generated successfully: {cache_key}")
            return image_url, None
            
        except openai.BadRequestError as e:
            error_msg = f"Invalid image request: {str(e)}"
            logger.error(error_msg)
            return None, error_msg
            
        except openai.RateLimitError as e:
            error_msg = "Image generation rate limit exceeded. Please try again later."
            logger.error(error_msg)
            return None, error_msg
            
        except Exception as e:
            error_msg = f"Image generation failed: {str(e)}"
            logger.exception(error_msg)
            return None, error_msg
    
    def generate_image_sync(self, description: str) -> Tuple[Optional[str], Optional[str]]:
        """
        Synchronous version of generate_image.
        
        For use in non-async contexts.
        """
        # Check cache first
        cache_key = self._get_cache_key(description)
        if cache_key in self._cache:
            logger.info(f"Image found in cache: {cache_key}")
            return self._cache[cache_key], None
        
        try:
            dalle_prompt = self._build_dalle_prompt(description)
            
            logger.info(f"Generating image (sync): {description[:50]}...")
            
            response = openai.images.generate(
                model=self.model,
                prompt=dalle_prompt,
                size=self.size,
                quality=self.quality,
                style=self.style,
                n=1,
                response_format="url"
            )
            
            dalle_url = response.data[0].url

            # Proxy: download immediately so the URL never expires
            proxied = download_and_cache_sync(dalle_url)
            image_url = proxied if proxied else dalle_url
            if not proxied:
                logger.warning("Image proxy failed; falling back to DALL-E URL")

            # Enforce cache size limit
            if len(self._cache) >= self.MAX_CACHE_SIZE:
                oldest_key = next(iter(self._cache))
                del self._cache[oldest_key]
                logger.debug(f"Cache full, removed: {oldest_key}")

            self._cache[cache_key] = image_url

            logger.info(f"Image generated successfully: {cache_key}")
            return image_url, None
            
        except Exception as e:
            error_msg = f"Image generation failed: {str(e)}"
            logger.exception(error_msg)
            return None, error_msg
    
    def get_placeholder_image(self, description: str) -> str:
        """
        Get a placeholder image URL when generation fails.
        
        Returns a simple placeholder or cached fallback.
        """
        # You could return a static placeholder URL here
        # For now, return a data URI with a simple placeholder
        return "https://via.placeholder.com/400x400.png?text=Image+Loading..."
    
    def clear_cache(self):
        """Clear the in-memory image cache."""
        self._cache.clear()
        logger.info("Image cache cleared")


# =============================================================================
# Response Parser Integration
# =============================================================================

def process_ai_response_with_images(
    response_text: str,
    image_service: ImageGenerationService
) -> dict:
    """
    Process AI response and handle image generation.
    
    Args:
        response_text: The AI's raw response
        image_service: ImageGenerationService instance
        
    Returns:
        Dictionary with:
        - text: Cleaned response text (for TTS)
        - has_image: Whether an image was requested
        - image_url: Generated image URL (if any)
        - image_error: Error message (if generation failed)
    """
    result = {
        "text": response_text,
        "has_image": False,
        "image_url": None,
        "image_error": None
    }
    
    # Check for image request
    image_description = image_service.extract_image_request(response_text)
    
    if image_description:
        result["has_image"] = True
        
        # Clean text for TTS
        result["text"] = image_service.remove_image_marker(response_text)
        
        # Generate image
        image_url, error = image_service.generate_image_sync(image_description)
        
        if image_url:
            result["image_url"] = image_url
        else:
            result["image_error"] = error
            result["image_url"] = image_service.get_placeholder_image(image_description)
    
    return result


# =============================================================================
# Singleton
# =============================================================================

_image_service: Optional[ImageGenerationService] = None


def get_image_service() -> ImageGenerationService:
    """Get or create the singleton ImageGenerationService."""
    global _image_service
    if _image_service is None:
        _image_service = ImageGenerationService()
    return _image_service
