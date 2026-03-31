from pydantic import BaseModel
from datetime import datetime


class ReservationCreate(BaseModel):
    spot_id: int
    plate_number: str | None = None
    vehicle_id: int | None = None
    start_time: datetime
    end_time: datetime


class ReservationResponse(BaseModel):
    id: int
    user_id: int
    vehicle_id: int | None
    spot_id: int
    plate_number: str | None
    status: str
    start_time: datetime
    end_time: datetime
    actual_entry_time: datetime | None
    actual_exit_time: datetime | None
    total_amount: float | None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class ReservationCancel(BaseModel):
    reason: str | None = None
