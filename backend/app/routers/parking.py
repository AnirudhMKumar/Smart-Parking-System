from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.user import User
from app.schemas.parking import ParkingLotResponse, ParkingSpotResponse, ParkingStats, ParkingSpotCreate, ParkingLotCreate
from app.services import parking_service
from app.utils.security import get_current_user

router = APIRouter(prefix="/api/parking", tags=["Parking"])


@router.get("/lot", response_model=list[ParkingLotResponse])
def get_lots(db: Session = Depends(get_db)):
    return parking_service.get_parking_lots(db)


@router.post("/lot", response_model=ParkingLotResponse, status_code=201)
def create_lot(data: ParkingLotCreate, db: Session = Depends(get_db), _: User = Depends(get_current_user)):
    return parking_service.create_parking_lot(db, data.name, data.address, data.total_spots, data.hourly_rate)


@router.get("/spots", response_model=list[ParkingSpotResponse])
def get_all_spots(lot_id: int | None = None, db: Session = Depends(get_db)):
    return parking_service.get_all_spots(db, lot_id)


@router.get("/spots/available", response_model=list[ParkingSpotResponse])
def get_available_spots(lot_id: int | None = None, db: Session = Depends(get_db)):
    return parking_service.get_available_spots(db, lot_id)


@router.get("/stats", response_model=ParkingStats)
def get_stats(lot_id: int | None = None, db: Session = Depends(get_db)):
    return parking_service.get_parking_stats(db, lot_id)


@router.post("/spots/seed")
def seed_spots(lot_id: int, count: int = 20, floors: int = 1, db: Session = Depends(get_db), _: User = Depends(get_current_user)):
    spots = parking_service.seed_spots(db, lot_id, count, floors)
    return {"message": f"Created {len(spots)} spots", "count": len(spots)}
