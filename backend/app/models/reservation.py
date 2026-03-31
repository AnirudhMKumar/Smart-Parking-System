from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey, func
from sqlalchemy.orm import relationship
from app.database import Base


class Reservation(Base):
    __tablename__ = "reservations"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    vehicle_id = Column(Integer, ForeignKey("vehicles.id"), nullable=True)
    spot_id = Column(Integer, ForeignKey("parking_spots.id"), nullable=False)
    plate_number = Column(String(20), nullable=True)
    status = Column(String(20), default="active")  # active, completed, cancelled, no_show
    start_time = Column(DateTime(timezone=True), nullable=False)
    end_time = Column(DateTime(timezone=True), nullable=False)
    actual_entry_time = Column(DateTime(timezone=True), nullable=True)
    actual_exit_time = Column(DateTime(timezone=True), nullable=True)
    total_amount = Column(Float, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    user = relationship("User", back_populates="reservations")
    vehicle = relationship("Vehicle", back_populates="reservations")
    spot = relationship("ParkingSpot", back_populates="reservations")
