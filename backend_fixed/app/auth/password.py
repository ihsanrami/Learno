import bcrypt

# bcrypt processes only the first 72 bytes of the password. Passwords longer
# than 72 bytes are explicitly truncated here so behaviour is consistent across
# bcrypt versions (4.x raises ValueError; earlier versions silently truncated).
_BCRYPT_MAX_BYTES = 72


def _prepare(plain: str) -> bytes:
    return plain.encode()[:_BCRYPT_MAX_BYTES]


def hash_password(plain: str) -> str:
    return bcrypt.hashpw(_prepare(plain), bcrypt.gensalt(rounds=12)).decode()


def verify_password(plain: str, hashed: str) -> bool:
    return bcrypt.checkpw(_prepare(plain), hashed.encode())
