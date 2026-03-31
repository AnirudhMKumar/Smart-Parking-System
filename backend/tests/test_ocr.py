from tests.conftest import client


def _login():
    client.post("/api/auth/register", json={
        "email": "ocr@test.com",
        "password": "password123",
        "full_name": "OCR User",
    })
    r = client.post("/api/auth/login", json={
        "email": "ocr@test.com",
        "password": "password123",
    })
    return {"Authorization": f"Bearer {r.json()['access_token']}"}


def _setup_parking():
    h = _login()
    lot = client.post("/api/parking/lot", json={
        "name": "OCR Lot",
        "total_spots": 10,
        "hourly_rate": 5.0,
    }, headers=h)
    lot_id = lot.json()["id"]
    client.post(f"/api/parking/spots/seed?lot_id={lot_id}&count=10", headers=h)
    return h


class TestOCREntryExit:
    def test_entry_with_spot_id(self):
        h = _setup_parking()
        response = client.post("/api/ocr/entry", json={
            "plate_number": "ABC123",
            "spot_id": 1,
        }, headers=h)
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["plate_number"] == "ABC123"
        assert data["spot_id"] == 1

    def test_entry_auto_assign_spot(self):
        h = _setup_parking()
        response = client.post("/api/ocr/entry", json={
            "plate_number": "XYZ789",
        }, headers=h)
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["plate_number"] == "XYZ789"
        assert data["spot_id"] is not None

    def test_entry_occupied_spot(self):
        h = _setup_parking()
        client.post("/api/ocr/entry", json={
            "plate_number": "AAA111",
            "spot_id": 1,
        }, headers=h)
        response = client.post("/api/ocr/entry", json={
            "plate_number": "BBB222",
            "spot_id": 1,
        }, headers=h)
        assert response.status_code == 400

    def test_exit(self):
        h = _setup_parking()
        client.post("/api/ocr/entry", json={
            "plate_number": "EXIT123",
            "spot_id": 2,
        }, headers=h)
        response = client.post("/api/ocr/exit", json={
            "plate_number": "EXIT123",
        }, headers=h)
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["plate_number"] == "EXIT123"
        assert data["spot_id"] == 2

    def test_stats_after_entry(self):
        h = _setup_parking()
        client.post("/api/ocr/entry", json={
            "plate_number": "STAT123",
            "spot_id": 3,
        }, headers=h)
        response = client.get("/api/parking/stats")
        assert response.status_code == 200
        data = response.json()
        assert data["occupied"] >= 1

    def test_stats_after_exit(self):
        h = _setup_parking()
        client.post("/api/ocr/entry", json={
            "plate_number": "EXITSTAT",
            "spot_id": 4,
        }, headers=h)
        client.post("/api/ocr/exit", json={
            "plate_number": "EXITSTAT",
        }, headers=h)
        response = client.get("/api/parking/stats")
        assert response.status_code == 200
        data = response.json()
        assert data["occupied"] == 0
