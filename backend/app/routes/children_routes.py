from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.auth import service
from app.auth.dependencies import get_current_parent
from app.auth.models import Parent
from app.auth.schemas import ChildCreate, ChildOut, ChildUpdate
from app.database.session import get_db

router = APIRouter(prefix="/children", tags=["children"])


@router.get("/", response_model=list[ChildOut])
def list_children(
    db: Session = Depends(get_db),
    parent: Parent = Depends(get_current_parent),
):
    return service.list_children(db, parent.id)


@router.post("/", response_model=ChildOut, status_code=status.HTTP_201_CREATED)
def create_child(
    data: ChildCreate,
    db: Session = Depends(get_db),
    parent: Parent = Depends(get_current_parent),
):
    return service.create_child(db, parent.id, data)


@router.get("/{child_id}", response_model=ChildOut)
def get_child(
    child_id: int,
    db: Session = Depends(get_db),
    parent: Parent = Depends(get_current_parent),
):
    try:
        return service.get_child(db, child_id, parent.id)
    except service.AuthError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))


@router.put("/{child_id}", response_model=ChildOut)
def update_child(
    child_id: int,
    data: ChildUpdate,
    db: Session = Depends(get_db),
    parent: Parent = Depends(get_current_parent),
):
    try:
        return service.update_child(db, child_id, parent.id, data)
    except service.AuthError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))


@router.delete("/{child_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_child(
    child_id: int,
    db: Session = Depends(get_db),
    parent: Parent = Depends(get_current_parent),
):
    try:
        service.delete_child(db, child_id, parent.id)
    except service.AuthError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))


@router.post("/{child_id}/select", response_model=ChildOut)
def select_child(
    child_id: int,
    db: Session = Depends(get_db),
    parent: Parent = Depends(get_current_parent),
):
    try:
        return service.get_child(db, child_id, parent.id)
    except service.AuthError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))
