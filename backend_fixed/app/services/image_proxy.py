"""
Image Proxy Service for Learno
Downloads DALL-E images immediately and serves them from our own permanent URLs,
preventing display failures when DALL-E URLs expire after ~1 hour.
"""

import uuid
import logging
from pathlib import Path
from datetime import datetime, timedelta, timezone
from typing import Optional

import httpx

logger = logging.getLogger(__name__)

STATIC_DIR = Path("static/generated_images")


def _ensure_dirs() -> None:
    STATIC_DIR.mkdir(parents=True, exist_ok=True)


def download_and_cache_sync(dalle_url: str) -> Optional[str]:
    """
    Download a DALL-E image and save it locally.

    Returns the relative URL path (/static/generated_images/<uuid>.png)
    or None if download fails.
    """
    _ensure_dirs()

    filename = f"{uuid.uuid4()}.png"
    filepath = STATIC_DIR / filename

    try:
        with httpx.Client(timeout=30, follow_redirects=True) as client:
            response = client.get(dalle_url)
            response.raise_for_status()
            filepath.write_bytes(response.content)
            logger.info(f"Proxied image saved: {filename}")
            return f"/static/generated_images/{filename}"
    except Exception as e:
        logger.error(f"Image proxy download failed: {e}")
        return None


async def download_and_cache_async(dalle_url: str) -> Optional[str]:
    """Async version of download_and_cache_sync."""
    _ensure_dirs()

    filename = f"{uuid.uuid4()}.png"
    filepath = STATIC_DIR / filename

    try:
        async with httpx.AsyncClient(timeout=30, follow_redirects=True) as client:
            response = await client.get(dalle_url)
            response.raise_for_status()
            filepath.write_bytes(response.content)
            logger.info(f"Proxied image saved: {filename}")
            return f"/static/generated_images/{filename}"
    except Exception as e:
        logger.error(f"Image proxy download failed: {e}")
        return None


def cleanup_old_images(days: int = 7) -> None:
    """Delete cached images older than `days` days."""
    if not STATIC_DIR.exists():
        return

    cutoff = datetime.now(timezone.utc) - timedelta(days=days)
    deleted = 0

    for f in STATIC_DIR.glob("*.png"):
        try:
            if datetime.fromtimestamp(f.stat().st_mtime, tz=timezone.utc) < cutoff:
                f.unlink()
                deleted += 1
        except Exception:
            pass

    if deleted:
        logger.info(f"Cleaned up {deleted} expired image(s)")
