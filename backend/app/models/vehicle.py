from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey, func
from sqlalchemy.orm import relationship
from app.database import Base


class Vehicle(Base):
    __tablename__ = "vehicles"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    plate_number = Column(String(20), nullable=False, index=True)
    plate_image_url = Column(String, nullable=True)
    vehicle_type = Column(String(20), nullable=True)  # sedan, suv, truck, motorcycle
    color = Column(String(30), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", back_populates="vehicles")
    reservations = relationship("Reservation", back_populates="vehicle")


class PlateRecord(Base):
    __tablename__ = "plate_records"

    id = Column(Integer, primary_key=True, index=True)
    plate_number = Column(String(20), nullable=False, index=True)
    confidence = Column(Float, nullable=True)
    image_url = Column(String, nullable=True)
    record_type = Column(String(10), nullable=False)  # entry, exit
    spot_id = Column(Integer, ForeignKey("parking_spots.id"), nullable=True)
    processed_at = Column(DateTime(timezone=True), server_default=func.now())

    spot = relationship("ParkingSpot", back_populates="plate_records")
