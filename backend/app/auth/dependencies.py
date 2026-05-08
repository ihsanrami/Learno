from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
import jwt
from sqlalchemy.orm import Session

from app.auth.jwt_handler import decode_access_token
from app.auth.models import Parent
from app.database.session import get_db

_bearer = HTTPBearer(auto_error=False)


def get_current_parent(
    credentials: HTTPAuthorizationCredentials | None = Depends(_bearer),
    db: Session = Depends(get_db),
) -> Parent:
    if not credentials:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")
    try:
        payload = decode_access_token(credentials.credentials)
    except jwt.PyJWTError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid or expired token")

    parent = db.query(Parent).filter(Parent.id == int(payload["sub"])).first()
    if not parent:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Parent not found")
    return parent


def get_optional_parent(
    credentials: HTTPAuthorizationCredentials | None = Depends(_bearer),
    db: Session = Depends(get_db),
) -> Parent | None:
    """Returns current parent or None — for backward-compatible optional auth."""
    if not credentials:
        return None
    try:
        payload = decode_access_token(credentials.credentials)
        return db.query(Parent).filter(Parent.id == int(payload["sub"])).first()
    except Exception:
        return None
