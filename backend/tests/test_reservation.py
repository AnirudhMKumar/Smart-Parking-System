from tests.conftest import client
from datetime import datetime, timedelta, timezone


def _login():
    client.post("/api/auth/register", json={
        "email": "res@test.com",
        "password": "password123",
        "full_name": "Res User",
    })
    r = client.post("/api/auth/login", json={
        "email": "res@test.com",
        "password": "password123",
    })
    return {"Authorization": f"Bearer {r.json()['access_token']}"}


def _setup_parking():
    h = _login()
    lot = client.post("/api/parking/lot", json={
        "name": "Res Lot",
        "total_spots": 10,
        "hourly_rate": 5.0,
    }, headers=h)
    lot_id = lot.json()["id"]
    client.post(f"/api/parking/spots/seed?lot_id={lot_id}&count=10", headers=h)
    return h


class TestReservations:
    def test_create_reservation(self):
        h = _setup_parking()
        now = datetime.now(timezone.utc)
        response = client.post("/api/reservations", json={
            "spot_id": 1,
            "plate_number": "RES123",
            "start_time": now.isoformat(),
            "end_time": (now + timedelta(hours=2)).isoformat(),
        }, headers=h)
        assert response.status_code == 201
        data = response.json()
        assert data["status"] == "active"
        assert data["plate_number"] == "RES123"
        assert data["spot_id"] == 1

    def test_reservation_marks_spot_reserved(self):
        h = _setup_parking()
        now = datetime.now(timezone.utc)
        client.post("/api/reservations", json={
            "spot_id": 2,
            "plate_number": "MARK123",
            "start_time": now.isoformat(),
            "end_time": (now + timedelta(hours=2)).isoformat(),
        }, headers=h)
        response = client.get("/api/parking/stats")
        assert response.status_code == 200
        data = response.json()
        assert data["reserved"] >= 1

    def test_reservation_conflict(self):
        h = _setup_parking()
        now = datetime.now(timezone.utc)
        end = now + timedelta(hours=2)
        client.post("/api/reservations", json={
            "spot_id": 3,
            "plate_number": "CONF123",
            "start_time": now.isoformat(),
            "end_time": end.isoformat(),
        }, headers=h)
        response = client.post("/api/reservations", json={
            "spot_id": 3,
            "plate_number": "CONF456",
            "start_time": now.isoformat(),
            "end_time": end.isoformat(),
        }, headers=h)
        assert response.status_code == 400

    def test_cancel_reservation(self):
        h = _setup_parking()
        now = datetime.now(timezone.utc)
        res = client.post("/api/reservations", json={
            "spot_id": 4,
            "plate_number": "CANC123",
            "start_time": now.isoformat(),
            "end_time": (now + timedelta(hours=2)).isoformat(),
        }, headers=h)
        res_id = res.json()["id"]
        response = client.patch(f"/api/reservations/{res_id}/cancel", headers=h)
        assert response.status_code == 200
        assert response.json()["status"] == "cancelled"

    def test_cancel_restores_spot(self):
        h = _setup_parking()
        now = datetime.now(timezone.utc)
        res = client.post("/api/reservations", json={
            "spot_id": 5,
            "plate_number": "REST123",
            "start_time": now.isoformat(),
            "end_time": (now + timedelta(hours=2)).isoformat(),
        }, headers=h)
        res_id = res.json()["id"]
        client.patch(f"/api/reservations/{res_id}/cancel", headers=h)
        response = client.get("/api/parking/stats")
        assert response.status_code == 200
        data = response.json()
        assert data["reserved"] == 0

    def test_get_reservations(self):
        h = _setup_parking()
        now = datetime.now(timezone.utc)
        client.post("/api/reservations", json={
            "spot_id": 6,
            "plate_number": "GET123",
            "start_time": now.isoformat(),
            "end_time": (now + timedelta(hours=2)).isoformat(),
        }, headers=h)
        response = client.get("/api/reservations", headers=h)
        assert response.status_code == 200
        assert len(response.json()) >= 1

    def test_get_reservation_by_id(self):
        h = _setup_parking()
        now = datetime.now(timezone.utc)
        res = client.post("/api/reservations", json={
            "spot_id": 7,
            "plate_number": "ID123",
            "start_time": now.isoformat(),
            "end_time": (now + timedelta(hours=2)).isoformat(),
        }, headers=h)
        res_id = res.json()["id"]
        response = client.get(f"/api/reservations/{res_id}", headers=h)
        assert response.status_code == 200
        assert response.json()["id"] == res_id

    def test_cancel_nonexistent_reservation(self):
        h = _login()
        response = client.patch("/api/reservations/9999/cancel", headers=h)
        assert response.status_code == 400
