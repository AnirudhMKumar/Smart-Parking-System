import io
from fastapi import APIRouter, Depends, UploadFile, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.user import User
from app.models.vehicle import Vehicle, PlateRecord
from app.models.parking import ParkingSpot
from app.schemas.vehicle import OCRResponse, OCRResult, EntryRequest, ExitRequest, EntryExitResponse
from app.config import get_settings
from app.utils.security import get_current_user

router = APIRouter(prefix="/api/ocr", tags=["License Plate Recognition"])

settings = get_settings()

_ocr = None


def get_ocr():
    global _ocr
    if _ocr is None:
        import os
        os.environ["PADDLE_PDX_DISABLE_MODEL_SOURCE_CHECK"] = "True"
        from paddleocr import PaddleOCR
        _ocr = PaddleOCR(lang="en")
    return _ocr


def parse_ocr_result(result) -> list[OCRResult]:
    plates = []
    if not result:
        return plates

    rec_texts = result.get("rec_texts", [])
    rec_scores = result.get("rec_scores", [])
    dt_polys = result.get("dt_polys", [])

    detected_parts = []
    for i, text in enumerate(rec_texts):
        confidence = float(rec_scores[i]) if i < len(rec_scores) else 0.0
        if confidence >= settings.OCR_CONFIDENCE_THRESHOLD and text.strip():
            detected_parts.append((text.strip(), confidence, dt_polys[i] if i < len(dt_polys) else None))

    if detected_parts:
        full_plate = "".join(p[0] for p in detected_parts)
        avg_confidence = sum(p[1] for p in detected_parts) / len(detected_parts)
        bbox = None
        if detected_parts[0][2] is not None:
            poly = detected_parts[0][2]
            bbox = poly.tolist() if hasattr(poly, "tolist") else list(poly)
        plates.append(OCRResult(
            plate_number=full_plate,
            confidence=round(avg_confidence, 4),
            bounding_box=bbox,
        ))

    for text, confidence, poly in detected_parts:
        bbox = poly.tolist() if poly is not None and hasattr(poly, "tolist") else (list(poly) if poly is not None else None)
        if text != plates[0].plate_number if plates else True:
            plates.append(OCRResult(
                plate_number=text,
                confidence=round(confidence, 4),
                bounding_box=bbox,
            ))

    return plates


@router.post("/recognize", response_model=OCRResponse)
async def recognize_plate(file: UploadFile, db: Session = Depends(get_db)):
    if not file.filename.lower().endswith((".jpg", ".jpeg", ".png", ".bmp")):
        raise HTTPException(status_code=400, detail="Unsupported image format")

    image_bytes = await file.read()

    try:
        import numpy as np
        import cv2
        nparr = np.frombuffer(image_bytes, np.uint8)
        img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        if img is None:
            raise ValueError("Invalid image")
    except Exception:
        raise HTTPException(status_code=400, detail="Could not read image")

    ocr = get_ocr()
    result = ocr.predict(img)

    plates = []
    if result:
        for page in result:
            page_plates = parse_ocr_result(page)
            plates.extend(page_plates)

    return OCRResponse(success=True, plates=plates, count=len(plates))


@router.post("/entry", response_model=EntryExitResponse)
def record_entry(data: EntryRequest, db: Session = Depends(get_db), _: User = Depends(get_current_user)):
    plate_number = data.plate_number.upper().strip()

    spot = None
    if data.spot_id:
        spot = db.query(ParkingSpot).filter(ParkingSpot.id == data.spot_id).first()
        if not spot:
            raise HTTPException(status_code=404, detail="Spot not found")
        if spot.status != "available":
            raise HTTPException(status_code=400, detail=f"Spot is {spot.status}")
        spot.status = "occupied"
    else:
        spot = db.query(ParkingSpot).filter(ParkingSpot.status == "available").first()
        if not spot:
            raise HTTPException(status_code=400, detail="No available spots")
        spot.status = "occupied"

    record = PlateRecord(
        plate_number=plate_number,
        confidence=1.0,
        image_url=data.image_url,
        record_type="entry",
        spot_id=spot.id,
    )
    db.add(record)
    db.commit()
    db.refresh(record)
    db.refresh(spot)

    return EntryExitResponse(
        success=True,
        message="Entry recorded successfully",
        plate_number=plate_number,
        spot_id=spot.id,
        spot_number=spot.spot_number,
        record_id=record.id,
    )


@router.post("/exit", response_model=EntryExitResponse)
def record_exit(data: ExitRequest, db: Session = Depends(get_db), _: User = Depends(get_current_user)):
    plate_number = data.plate_number.upper().strip()

    entry_record = (
        db.query(PlateRecord)
        .filter(
            PlateRecord.plate_number == plate_number,
            PlateRecord.record_type == "entry",
        )
        .order_by(PlateRecord.processed_at.desc())
        .first()
    )

    spot = None
    duration_minutes = None
    amount = None

    if entry_record and entry_record.spot_id:
        spot = db.query(ParkingSpot).filter(ParkingSpot.id == entry_record.spot_id).first()
        if spot:
            spot.status = "available"

            from datetime import datetime, timezone
            now = datetime.now(timezone.utc)
            entry_time = entry_record.processed_at
            if entry_time.tzinfo is None:
                from datetime import timezone as tz
                entry_time = entry_time.replace(tzinfo=tz.utc)
            duration_minutes = int((now - entry_time).total_seconds() / 60)

            lot = spot.lot if spot.lot else None
            if lot and lot.hourly_rate:
                hours = max(1, duration_minutes / 60)
                amount = round(hours * lot.hourly_rate, 2)

    record = PlateRecord(
        plate_number=plate_number,
        confidence=1.0,
        image_url=data.image_url,
        record_type="exit",
        spot_id=spot.id if spot else None,
    )
    db.add(record)
    db.commit()
    db.refresh(record)

    return EntryExitResponse(
        success=True,
        message="Exit recorded successfully",
        plate_number=plate_number,
        spot_id=spot.id if spot else None,
        spot_number=spot.spot_number if spot else None,
        record_id=record.id,
        duration_minutes=duration_minutes,
        amount=amount,
    )
