import asyncio
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import get_settings
from app.database import engine, Base, SessionLocal
from app.models.parking import ParkingLot, ParkingSpot
from app.routers import auth, parking, ocr, reservation, vehicle, ws
from app.routers.ws import listen_for_updates
from app.services.scheduler import start_scheduler

settings = get_settings()


def _seed_initial_data():
    db = SessionLocal()
    try:
        lot_count = db.query(ParkingLot).count()
        if lot_count == 0:
            lot = ParkingLot(name="SmartPS Main Lot", address="Downtown", total_spots=30, hourly_rate=5.0)
            db.add(lot)
            db.flush()
            sections = ["A", "B"]
            spot_num = 1
            for section in sections:
                for _ in range(15):
                    spot = ParkingSpot(
                        lot_id=lot.id,
                        spot_number=f"{section}{spot_num:03d}",
                        spot_type="regular",
                        status="available",
                        floor=1,
                        section=section,
                    )
                    db.add(spot)
                    spot_num += 1
            db.commit()
    finally:
        db.close()


@asynccontextmanager
async def lifespan(app: FastAPI):
    Base.metadata.create_all(bind=engine)
    _seed_initial_data()

    ws_task = asyncio.create_task(listen_for_updates())
    scheduler_task = asyncio.create_task(start_scheduler())

    yield

    ws_task.cancel()
    scheduler_task.cancel()
    try:
        await ws_task
    except asyncio.CancelledError:
        pass
    try:
        await scheduler_task
    except asyncio.CancelledError:
        pass


app = FastAPI(
    title=settings.APP_NAME,
    description="Smart Parking System - AI-powered license plate recognition & reservations",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(parking.router)
app.include_router(ocr.router)
app.include_router(reservation.router)
app.include_router(vehicle.router)
app.include_router(ws.router)


@app.get("/", tags=["Health"])
def health_check():
    return {"status": "ok", "app": settings.APP_NAME, "version": "1.0.0"}


@app.get("/health", tags=["Health"])
def health():
    return {"status": "healthy"}
