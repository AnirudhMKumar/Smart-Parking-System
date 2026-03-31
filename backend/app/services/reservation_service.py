from sqlalchemy.orm import Session
from datetime import datetime, timezone
from app.models.reservation import Reservation
from app.models.parking import ParkingSpot
from app.schemas.reservation import ReservationCreate
from app.services import parking_service


def create_reservation(db: Session, user_id: int, data: ReservationCreate) -> Reservation:
    spot = parking_service.get_spot_by_id(db, data.spot_id)
    if not spot or spot.status != "available":
        raise ValueError("Spot is not available")

    conflict = (
        db.query(Reservation)
        .filter(
            Reservation.spot_id == data.spot_id,
            Reservation.status == "active",
            Reservation.start_time < data.end_time,
            Reservation.end_time > data.start_time,
        )
        .first()
    )
    if conflict:
        raise ValueError("Spot already reserved for this time slot")

    reservation = Reservation(
        user_id=user_id,
        vehicle_id=data.vehicle_id,
        spot_id=data.spot_id,
        plate_number=data.plate_number,
        start_time=data.start_time,
        end_time=data.end_time,
        status="active",
    )
    db.add(reservation)

    spot.status = "reserved"
    db.commit()
    db.refresh(reservation)
    return reservation


def get_user_reservations(db: Session, user_id: int, active_only: bool = False) -> list[Reservation]:
    query = db.query(Reservation).filter(Reservation.user_id == user_id)
    if active_only:
        query = query.filter(Reservation.status == "active")
    return query.order_by(Reservation.created_at.desc()).all()


def get_reservation_by_id(db: Session, reservation_id: int, user_id: int | None = None) -> Reservation | None:
    query = db.query(Reservation).filter(Reservation.id == reservation_id)
    if user_id:
        query = query.filter(Reservation.user_id == user_id)
    return query.first()


def cancel_reservation(db: Session, reservation_id: int, user_id: int) -> Reservation:
    reservation = get_reservation_by_id(db, reservation_id, user_id)
    if not reservation:
        raise ValueError("Reservation not found")
    if reservation.status != "active":
        raise ValueError("Reservation is not active")

    reservation.status = "cancelled"
    spot = parking_service.get_spot_by_id(db, reservation.spot_id)
    if spot and spot.status == "reserved":
        spot.status = "available"
    db.commit()
    db.refresh(reservation)
    return reservation


def get_reservation_history(db: Session, user_id: int) -> list[Reservation]:
    return (
        db.query(Reservation)
        .filter(Reservation.user_id == user_id, Reservation.status.in_(["completed", "cancelled"]))
        .order_by(Reservation.updated_at.desc())
        .all()
    )
