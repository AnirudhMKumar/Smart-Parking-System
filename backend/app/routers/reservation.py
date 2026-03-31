from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.user import User
from app.schemas.reservation import ReservationCreate, ReservationResponse
from app.services import reservation_service
from app.utils.security import get_current_user

router = APIRouter(prefix="/api/reservations", tags=["Reservations"])


@router.post("", response_model=ReservationResponse, status_code=201)
def create_reservation(data: ReservationCreate, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    try:
        reservation = reservation_service.create_reservation(db, user.id, data)
        return reservation
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("", response_model=list[ReservationResponse])
def get_reservations(active_only: bool = False, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    return reservation_service.get_user_reservations(db, user.id, active_only)


@router.get("/history", response_model=list[ReservationResponse])
def get_history(db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    return reservation_service.get_reservation_history(db, user.id)


@router.get("/{reservation_id}", response_model=ReservationResponse)
def get_reservation(reservation_id: int, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    reservation = reservation_service.get_reservation_by_id(db, reservation_id, user.id)
    if not reservation:
        raise HTTPException(status_code=404, detail="Reservation not found")
    return reservation


@router.patch("/{reservation_id}/cancel", response_model=ReservationResponse)
def cancel_reservation(reservation_id: int, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    try:
        return reservation_service.cancel_reservation(db, reservation_id, user.id)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
