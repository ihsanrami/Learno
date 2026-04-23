"""
=============================================================================
Tests for Image Proxy Service
=============================================================================
All network calls are mocked — no real HTTP requests are made.
Run with: pytest tests/test_image_proxy.py -v
=============================================================================
"""

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from pathlib import Path
from datetime import datetime, timedelta
from unittest.mock import MagicMock, patch, AsyncMock

import pytest

FAKE_URL = "https://oaidalleapiprodscus.blob.core.windows.net/private/img.png"
FAKE_CONTENT = b"\x89PNG\r\n\x1a\n" + b"\x00" * 100  # minimal fake PNG bytes


# =============================================================================
# 1. Sync: successful download
# =============================================================================

def test_sync_download_returns_proxied_url(tmp_path, monkeypatch):
    import app.services.image_proxy as proxy_mod

    monkeypatch.setattr(proxy_mod, "STATIC_DIR", tmp_path / "images")

    mock_response = MagicMock()
    mock_response.content = FAKE_CONTENT
    mock_response.raise_for_status = MagicMock()

    mock_client_instance = MagicMock()
    mock_client_instance.get.return_value = mock_response
    mock_client_instance.__enter__ = MagicMock(return_value=mock_client_instance)
    mock_client_instance.__exit__ = MagicMock(return_value=False)

    with patch("httpx.Client", return_value=mock_client_instance):
        result = proxy_mod.download_and_cache_sync(FAKE_URL)

    assert result is not None
    assert result.startswith("/static/generated_images/")
    assert result.endswith(".png")


def test_sync_download_creates_file_on_disk(tmp_path, monkeypatch):
    import app.services.image_proxy as proxy_mod

    monkeypatch.setattr(proxy_mod, "STATIC_DIR", tmp_path / "images")

    mock_response = MagicMock()
    mock_response.content = FAKE_CONTENT
    mock_response.raise_for_status = MagicMock()

    mock_client_instance = MagicMock()
    mock_client_instance.get.return_value = mock_response
    mock_client_instance.__enter__ = MagicMock(return_value=mock_client_instance)
    mock_client_instance.__exit__ = MagicMock(return_value=False)

    with patch("httpx.Client", return_value=mock_client_instance):
        result = proxy_mod.download_and_cache_sync(FAKE_URL)

    filename = Path(result).name
    saved_file = tmp_path / "images" / filename
    assert saved_file.exists()
    assert saved_file.read_bytes() == FAKE_CONTENT


def test_sync_download_each_call_produces_unique_filename(tmp_path, monkeypatch):
    import app.services.image_proxy as proxy_mod

    monkeypatch.setattr(proxy_mod, "STATIC_DIR", tmp_path / "images")

    mock_response = MagicMock()
    mock_response.content = FAKE_CONTENT
    mock_response.raise_for_status = MagicMock()

    mock_client_instance = MagicMock()
    mock_client_instance.get.return_value = mock_response
    mock_client_instance.__enter__ = MagicMock(return_value=mock_client_instance)
    mock_client_instance.__exit__ = MagicMock(return_value=False)

    with patch("httpx.Client", return_value=mock_client_instance):
        url1 = proxy_mod.download_and_cache_sync(FAKE_URL)
        url2 = proxy_mod.download_and_cache_sync(FAKE_URL)

    assert url1 != url2


# =============================================================================
# 2. Sync: failed download → returns None (fallback to original URL)
# =============================================================================

def test_sync_download_returns_none_on_http_error(tmp_path, monkeypatch):
    import app.services.image_proxy as proxy_mod
    import httpx

    monkeypatch.setattr(proxy_mod, "STATIC_DIR", tmp_path / "images")

    mock_client_instance = MagicMock()
    mock_client_instance.get.side_effect = httpx.HTTPStatusError(
        "404", request=MagicMock(), response=MagicMock()
    )
    mock_client_instance.__enter__ = MagicMock(return_value=mock_client_instance)
    mock_client_instance.__exit__ = MagicMock(return_value=False)

    with patch("httpx.Client", return_value=mock_client_instance):
        result = proxy_mod.download_and_cache_sync(FAKE_URL)

    assert result is None


def test_sync_download_returns_none_on_network_error(tmp_path, monkeypatch):
    import app.services.image_proxy as proxy_mod
    import httpx

    monkeypatch.setattr(proxy_mod, "STATIC_DIR", tmp_path / "images")

    mock_client_instance = MagicMock()
    mock_client_instance.get.side_effect = httpx.ConnectError("no route to host")
    mock_client_instance.__enter__ = MagicMock(return_value=mock_client_instance)
    mock_client_instance.__exit__ = MagicMock(return_value=False)

    with patch("httpx.Client", return_value=mock_client_instance):
        result = proxy_mod.download_and_cache_sync(FAKE_URL)

    assert result is None


def test_sync_download_no_file_left_on_failure(tmp_path, monkeypatch):
    import app.services.image_proxy as proxy_mod
    import httpx

    images_dir = tmp_path / "images"
    monkeypatch.setattr(proxy_mod, "STATIC_DIR", images_dir)

    mock_client_instance = MagicMock()
    mock_client_instance.get.side_effect = httpx.ConnectError("timeout")
    mock_client_instance.__enter__ = MagicMock(return_value=mock_client_instance)
    mock_client_instance.__exit__ = MagicMock(return_value=False)

    with patch("httpx.Client", return_value=mock_client_instance):
        proxy_mod.download_and_cache_sync(FAKE_URL)

    if images_dir.exists():
        assert list(images_dir.glob("*.png")) == []


# =============================================================================
# 3. Async: successful download
# =============================================================================

@pytest.mark.asyncio
async def test_async_download_returns_proxied_url(tmp_path, monkeypatch):
    import app.services.image_proxy as proxy_mod

    monkeypatch.setattr(proxy_mod, "STATIC_DIR", tmp_path / "images")

    mock_response = AsyncMock()
    mock_response.content = FAKE_CONTENT
    mock_response.raise_for_status = MagicMock()

    mock_client = AsyncMock()
    mock_client.get = AsyncMock(return_value=mock_response)
    mock_client.__aenter__ = AsyncMock(return_value=mock_client)
    mock_client.__aexit__ = AsyncMock(return_value=False)

    with patch("httpx.AsyncClient", return_value=mock_client):
        result = await proxy_mod.download_and_cache_async(FAKE_URL)

    assert result is not None
    assert result.startswith("/static/generated_images/")
    assert result.endswith(".png")


@pytest.mark.asyncio
async def test_async_download_returns_none_on_error(tmp_path, monkeypatch):
    import app.services.image_proxy as proxy_mod
    import httpx

    monkeypatch.setattr(proxy_mod, "STATIC_DIR", tmp_path / "images")

    mock_client = AsyncMock()
    mock_client.get = AsyncMock(side_effect=httpx.ConnectError("timeout"))
    mock_client.__aenter__ = AsyncMock(return_value=mock_client)
    mock_client.__aexit__ = AsyncMock(return_value=False)

    with patch("httpx.AsyncClient", return_value=mock_client):
        result = await proxy_mod.download_and_cache_async(FAKE_URL)

    assert result is None


# =============================================================================
# 4. Cleanup function
# =============================================================================

def test_cleanup_deletes_old_files(tmp_path, monkeypatch):
    import app.services.image_proxy as proxy_mod

    images_dir = tmp_path / "images"
    images_dir.mkdir()
    monkeypatch.setattr(proxy_mod, "STATIC_DIR", images_dir)

    old_file = images_dir / "old_image.png"
    old_file.write_bytes(b"old")
    old_time = (datetime.now() - timedelta(days=10)).timestamp()
    os.utime(old_file, (old_time, old_time))

    proxy_mod.cleanup_old_images(days=7)

    assert not old_file.exists()


def test_cleanup_keeps_recent_files(tmp_path, monkeypatch):
    import app.services.image_proxy as proxy_mod

    images_dir = tmp_path / "images"
    images_dir.mkdir()
    monkeypatch.setattr(proxy_mod, "STATIC_DIR", images_dir)

    recent_file = images_dir / "recent_image.png"
    recent_file.write_bytes(b"fresh")

    proxy_mod.cleanup_old_images(days=7)

    assert recent_file.exists()


def test_cleanup_does_nothing_when_dir_missing(tmp_path, monkeypatch):
    import app.services.image_proxy as proxy_mod

    monkeypatch.setattr(proxy_mod, "STATIC_DIR", tmp_path / "nonexistent")

    # Should not raise
    proxy_mod.cleanup_old_images(days=7)


def test_cleanup_only_removes_png_files(tmp_path, monkeypatch):
    import app.services.image_proxy as proxy_mod

    images_dir = tmp_path / "images"
    images_dir.mkdir()
    monkeypatch.setattr(proxy_mod, "STATIC_DIR", images_dir)

    txt_file = images_dir / "notes.txt"
    txt_file.write_text("keep me")
    old_time = (datetime.now() - timedelta(days=10)).timestamp()
    os.utime(txt_file, (old_time, old_time))

    proxy_mod.cleanup_old_images(days=7)

    assert txt_file.exists()
