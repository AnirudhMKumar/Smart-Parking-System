from pydantic import BaseModel
from datetime import datetime


class ParkingLotBase(BaseModel):
    name: str
    address: str | None = None
    total_spots: int
    hourly_rate: float | None = None


class ParkingLotCreate(ParkingLotBase):
    pass


class ParkingLotResponse(ParkingLotBase):
    id: int
    created_at: datetime

    class Config:
        from_attributes = True


class ParkingSpotBase(BaseModel):
    spot_number: str
    spot_type: str = "regular"
    floor: int = 1
    section: str | None = None


class ParkingSpotCreate(ParkingSpotBase):
    lot_id: int


class ParkingSpotResponse(ParkingSpotBase):
    id: int
    lot_id: int
    status: str
    updated_at: datetime

    class Config:
        from_attributes = True


class ParkingSpotUpdate(BaseModel):
    status: str | None = None
    spot_type: str | None = None


class ParkingStats(BaseModel):
    total_spots: int
    available: int
    occupied: int
    reserved: int
    maintenance: int
