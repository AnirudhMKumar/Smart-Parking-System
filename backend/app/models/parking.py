from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey, func
from sqlalchemy.orm import relationship
from app.database import Base


class ParkingLot(Base):
    __tablename__ = "parking_lots"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False)
    address = Column(String, nullable=True)
    total_spots = Column(Integer, nullable=False)
    hourly_rate = Column(Float, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    spots = relationship("ParkingSpot", back_populates="lot", cascade="all, delete-orphan")


class ParkingSpot(Base):
    __tablename__ = "parking_spots"

    id = Column(Integer, primary_key=True, index=True)
    lot_id = Column(Integer, ForeignKey("parking_lots.id"), nullable=False)
    spot_number = Column(String(20), nullable=False)
    spot_type = Column(String(20), default="regular")  # regular, compact, ev, handicap
    status = Column(String(20), default="available")    # available, occupied, reserved, maintenance
    floor = Column(Integer, default=1)
    section = Column(String(10), nullable=True)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    lot = relationship("ParkingLot", back_populates="spots")
    reservations = relationship("Reservation", back_populates="spot")
    plate_records = relationship("PlateRecord", back_populates="spot")
