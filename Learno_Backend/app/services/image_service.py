import logging
import re
import hashlib
from typing import Optional, Tuple
from pathlib import Path

import openai
from app.config import settings
from app.utils.exceptions import AIServiceError

logger = logging.getLogger(__name__)


class ImageGenerationService:
    
    MAX_CACHE_SIZE = 100
    
    def __init__(self):
        openai.api_key = settings.OPENAI_API_KEY
        self.model = "dall-e-2"
        self.size = "1024x1024"
        self.quality = "standard"
        self.style = "vivid"
        self.timeout = 60
        self.cache_dir = Path("generated_images")
        self.cache_dir.mkdir(exist_ok=True)
        self._cache: dict = {}
        logger.info("ImageGenerationService initialized with DALL-E")
    
    def extract_image_request(self, response_text: str) -> Optional[str]:
        pattern = r'\[GENERATE_IMAGE:\s*([^\]]+)\]'
        match = re.search(pattern, response_text, re.IGNORECASE)
        if match:
            description = match.group(1).strip()
            logger.debug(f"Found image request: {description}")
            return description
        return None
    
    def remove_image_marker(self, response_text: str) -> str:
        pattern = r'\[GENERATE_IMAGE:\s*[^\]]+\]'
        cleaned = re.sub(pattern, '', response_text, flags=re.IGNORECASE)
        return cleaned.strip()
    
    def _get_cache_key(self, description: str) -> str:
        return hashlib.md5(description.lower().encode()).hexdigest()
    
    def _build_dalle_prompt(self, description: str) -> str:
        base_style = (
            "Create a simple, colorful, child-friendly cartoon illustration. "
            "Style: Bright colors, clean lines, friendly appearance, "
            "suitable for children ages 6-7. "
            "No text in the image. White or simple background. "
        )
        return f"{base_style}Content: {description}"
    
    async def generate_image(self, description: str) -> Tuple[Optional[str], Optional[str]]:
        cache_key = self._get_cache_key(description)
        if cache_key in self._cache:
            logger.info(f"Image found in cache: {cache_key}")
            return self._cache[cache_key], None
        
        try:
            dalle_prompt = self._build_dalle_prompt(description)
            logger.info(f"Generating image: {description[:50]}...")
            
            response = openai.images.generate(
                model=self.model,
                prompt=dalle_prompt,
                size=self.size,
                quality=self.quality,
                style=self.style,
                n=1,
                response_format="url"
            )
            
            image_url = response.data[0].url
            self._cache[cache_key] = image_url
            
            logger.info(f"Image generated successfully: {cache_key}")
            return image_url, None
            
        except openai.BadRequestError as e:
            error_msg = f"Invalid image request: {str(e)}"
            logger.error(error_msg)
            return None, error_msg
            
        except openai.RateLimitError as e:
            error_msg = "Image generation rate limit exceeded"
            logger.error(error_msg)
            return None, error_msg
            
        except Exception as e:
            error_msg = f"Image generation failed: {str(e)}"
            logger.exception(error_msg)
            return None, error_msg
    
    def generate_image_sync(self, description: str) -> Tuple[Optional[str], Optional[str]]:
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
            
            image_url = response.data[0].url
            
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
        return "https://via.placeholder.com/400x400.png?text=Image+Loading..."
    
    def clear_cache(self):
        self._cache.clear()
        logger.info("Image cache cleared")


def process_ai_response_with_images(response_text: str, image_service: ImageGenerationService) -> dict:
    result = {
        "text": response_text,
        "has_image": False,
        "image_url": None,
        "image_error": None
    }
    
    image_description = image_service.extract_image_request(response_text)
    
    if image_description:
        result["has_image"] = True
        result["text"] = image_service.remove_image_marker(response_text)
        image_url, error = image_service.generate_image_sync(image_description)
        
        if image_url:
            result["image_url"] = image_url
        else:
            result["image_error"] = error
            result["image_url"] = image_service.get_placeholder_image(image_description)
    
    return result


_image_service: Optional[ImageGenerationService] = None


def get_image_service() -> ImageGenerationService:
    global _image_service
    if _image_service is None:
        _image_service = ImageGenerationService()
    return _image_service
