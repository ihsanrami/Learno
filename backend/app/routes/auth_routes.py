from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy.orm import Session

from app.auth import service
from app.auth.dependencies import get_current_parent
from app.auth.models import Parent
from app.auth.schemas import (
    AccessToken,
    ParentLogin,
    ParentOut,
    ParentRegister,
    RefreshRequest,
    TokenPair,
)
from app.database.session import get_db
from app.rate_limiter import limiter

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/register", response_model=ParentOut, status_code=status.HTTP_201_CREATED)
@limiter.limit("10/minute")
async def register(request: Request, data: ParentRegister, db: Session = Depends(get_db)):
    try:
        parent = service.register_parent(db, data)
    except service.AuthError as e:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail=str(e))
    return parent


@router.post("/login", response_model=TokenPair)
@limiter.limit("20/minute")
async def login(request: Request, data: ParentLogin, db: Session = Depends(get_db)):
    try:
        _, tokens = service.login_parent(db, data.email, data.password)
    except service.AuthError as e:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=str(e))
    return tokens


@router.post("/refresh", response_model=TokenPair)
@limiter.limit("30/minute")
async def refresh(request: Request, data: RefreshRequest, db: Session = Depends(get_db)):
    try:
        tokens = service.refresh_access_token(db, data.refresh_token)
    except service.AuthError as e:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=str(e))
    return tokens


@router.post("/logout", status_code=status.HTTP_204_NO_CONTENT)
async def logout(data: RefreshRequest, db: Session = Depends(get_db)):
    service.logout_parent(db, data.refresh_token)


@router.get("/me", response_model=ParentOut)
async def me(current_parent: Parent = Depends(get_current_parent)):
    return current_parent
