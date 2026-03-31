import asyncio
from datetime import datetime, timezone
from app.database import SessionLocal
from app.models.reservation import Reservation
from app.models.parking import ParkingSpot
from app.services import cache_service


async def start_scheduler():
    while True:
        try:
            await expire_reservations()
        except Exception:
            pass
        await asyncio.sleep(60)


async def expire_reservations():
    db = SessionLocal()
    try:
        now = datetime.now(timezone.utc)
        expired = (
            db.query(Reservation)
            .filter(
                Reservation.status == "active",
                Reservation.end_time < now,
            )
            .all()
        )

        for reservation in expired:
            reservation.status = "completed"
            reservation.actual_exit_time = now

            spot = db.query(ParkingSpot).filter(ParkingSpot.id == reservation.spot_id).first()
            if spot and spot.status == "reserved":
                spot.status = "available"

            cache_service.delete_parking_stats()
            cache_service.publish_parking_update({
                "type": "reservation_expired",
                "reservation_id": reservation.id,
                "spot_id": reservation.spot_id,
                "spot_number": spot.spot_number if spot else None,
            })

        if expired:
            db.commit()
    finally:
        db.close()
