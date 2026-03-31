from pydantic import BaseModel
from datetime import datetime


class VehicleBase(BaseModel):
    plate_number: str
    vehicle_type: str | None = None
    color: str | None = None


class VehicleCreate(VehicleBase):
    pass


class VehicleResponse(VehicleBase):
    id: int
    user_id: int
    plate_image_url: str | None
    created_at: datetime

    class Config:
        from_attributes = True


class PlateRecordBase(BaseModel):
    plate_number: str
    confidence: float | None = None
    record_type: str  # entry or exit


class PlateRecordResponse(PlateRecordBase):
    id: int
    image_url: str | None
    spot_id: int | None
    processed_at: datetime

    class Config:
        from_attributes = True


class OCRResult(BaseModel):
    plate_number: str
    confidence: float
    bounding_box: list | None = None


class OCRResponse(BaseModel):
    success: bool
    plates: list[OCRResult]
    count: int


class EntryRequest(BaseModel):
    plate_number: str
    spot_id: int | None = None
    image_url: str | None = None


class ExitRequest(BaseModel):
    plate_number: str
    image_url: str | None = None


class EntryExitResponse(BaseModel):
    success: bool
    message: str
    plate_number: str
    spot_id: int | None = None
    spot_number: str | None = None
    record_id: int | None = None
    duration_minutes: int | None = None
    amount: float | None = None
