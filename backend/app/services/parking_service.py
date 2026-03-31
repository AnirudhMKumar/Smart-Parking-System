from sqlalchemy.orm import Session
from sqlalchemy import func as sql_func
from app.models.parking import ParkingSpot, ParkingLot
from app.schemas.parking import ParkingStats
from app.services import cache_service


def get_all_spots(db: Session, lot_id: int | None = None) -> list[ParkingSpot]:
    query = db.query(ParkingSpot)
    if lot_id:
        query = query.filter(ParkingSpot.lot_id == lot_id)
    return query.order_by(ParkingSpot.floor, ParkingSpot.section, ParkingSpot.spot_number).all()


def get_available_spots(db: Session, lot_id: int | None = None) -> list[ParkingSpot]:
    query = db.query(ParkingSpot).filter(ParkingSpot.status == "available")
    if lot_id:
        query = query.filter(ParkingSpot.lot_id == lot_id)
    return query.order_by(ParkingSpot.floor, ParkingSpot.section, ParkingSpot.spot_number).all()


def get_spot_by_id(db: Session, spot_id: int) -> ParkingSpot | None:
    return db.query(ParkingSpot).filter(ParkingSpot.id == spot_id).first()


def update_spot_status(db: Session, spot_id: int, status: str) -> ParkingSpot | None:
    spot = get_spot_by_id(db, spot_id)
    if spot:
        spot.status = status
        db.commit()
        db.refresh(spot)
        cache_service.set_spot_cache(spot_id, status)
        cache_service.delete_spot_cache(spot_id)  # invalidate
    return spot


def get_parking_stats(db: Session, lot_id: int | None = None) -> ParkingStats:
    cached = cache_service.get_parking_stats()
    if cached:
        return ParkingStats(**cached)

    query = db.query(ParkingSpot)
    if lot_id:
        query = query.filter(ParkingSpot.lot_id == lot_id)

    total = query.count()
    available = query.filter(ParkingSpot.status == "available").count()
    occupied = query.filter(ParkingSpot.status == "occupied").count()
    reserved = query.filter(ParkingSpot.status == "reserved").count()
    maintenance = query.filter(ParkingSpot.status == "maintenance").count()

    stats = ParkingStats(
        total_spots=total,
        available=available,
        occupied=occupied,
        reserved=reserved,
        maintenance=maintenance,
    )
    cache_service.set_parking_stats(stats.model_dump())
    return stats


def get_parking_lots(db: Session) -> list[ParkingLot]:
    return db.query(ParkingLot).all()


def create_parking_lot(db: Session, name: str, address: str | None, total_spots: int, hourly_rate: float | None = None) -> ParkingLot:
    lot = ParkingLot(name=name, address=address, total_spots=total_spots, hourly_rate=hourly_rate)
    db.add(lot)
    db.commit()
    db.refresh(lot)
    return lot


def seed_spots(db: Session, lot_id: int, count: int, floors: int = 1, sections: list[str] | None = None) -> list[ParkingSpot]:
    if sections is None:
        sections = ["A", "B"]
    spots = []
    spots_per_section = count // (len(sections) * floors)
    spot_num = 1
    for floor in range(1, floors + 1):
        for section in sections:
            for _ in range(spots_per_section):
                spot = ParkingSpot(
                    lot_id=lot_id,
                    spot_number=f"{section}{spot_num:03d}",
                    spot_type="regular",
                    status="available",
                    floor=floor,
                    section=section,
                )
                db.add(spot)
                spots.append(spot)
                spot_num += 1
    db.commit()
    for s in spots:
        db.refresh(s)
    return spots
