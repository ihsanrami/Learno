"""Tests for bcrypt password utilities."""
import pytest
from app.auth.password import hash_password, verify_password


def test_hash_returns_string():
    assert isinstance(hash_password("secret123"), str)


def test_hash_is_not_plaintext():
    assert hash_password("secret123") != "secret123"


def test_verify_correct_password():
    hashed = hash_password("mypassword")
    assert verify_password("mypassword", hashed) is True


def test_verify_wrong_password():
    hashed = hash_password("mypassword")
    assert verify_password("wrongpassword", hashed) is False


def test_different_hashes_same_password():
    h1 = hash_password("abc12345")
    h2 = hash_password("abc12345")
    assert h1 != h2  # bcrypt uses random salt


def test_verify_empty_string_against_hashed_empty():
    hashed = hash_password("")
    assert verify_password("", hashed) is True


def test_verify_empty_string_against_nonempty():
    hashed = hash_password("notempty")
    assert verify_password("", hashed) is False


def test_hash_long_password():
    long_pw = "a" * 72  # bcrypt processes up to 72 bytes
    hashed = hash_password(long_pw)
    assert verify_password(long_pw, hashed) is True


def test_verify_unicode_password():
    pw = "pässwörd!123"
    hashed = hash_password(pw)
    assert verify_password(pw, hashed) is True
    assert verify_password("passwrd!123", hashed) is False
