from tests.conftest import client


def _login():
    client.post("/api/auth/register", json={
        "email": "parking@test.com",
        "password": "password123",
        "full_name": "Parking User",
    })
    r = client.post("/api/auth/login", json={
        "email": "parking@test.com",
        "password": "password123",
    })
    return {"Authorization": f"Bearer {r.json()['access_token']}"}


class TestParking:
    def test_create_lot(self):
        h = _login()
        response = client.post("/api/parking/lot", json={
            "name": "Test Lot",
            "address": "123 Test St",
            "total_spots": 50,
            "hourly_rate": 5.0,
        }, headers=h)
        assert response.status_code == 201
        data = response.json()
        assert data["name"] == "Test Lot"
        assert data["total_spots"] == 50
        assert data["hourly_rate"] == 5.0

    def test_get_lots(self):
        h = _login()
        client.post("/api/parking/lot", json={
            "name": "Lot A",
            "total_spots": 10,
        }, headers=h)
        response = client.get("/api/parking/lot")
        assert response.status_code == 200
        assert len(response.json()) >= 1

    def test_seed_spots(self):
        h = _login()
        lot = client.post("/api/parking/lot", json={
            "name": "Seed Lot",
            "total_spots": 20,
        }, headers=h)
        lot_id = lot.json()["id"]
        response = client.post(f"/api/parking/spots/seed?lot_id={lot_id}&count=20", headers=h)
        assert response.status_code == 200
        assert response.json()["count"] == 20

    def test_get_all_spots(self):
        h = _login()
        lot = client.post("/api/parking/lot", json={
            "name": "Spots Lot",
            "total_spots": 10,
        }, headers=h)
        lot_id = lot.json()["id"]
        client.post(f"/api/parking/spots/seed?lot_id={lot_id}&count=10", headers=h)
        response = client.get("/api/parking/spots")
        assert response.status_code == 200
        assert len(response.json()) == 10

    def test_get_available_spots(self):
        h = _login()
        lot = client.post("/api/parking/lot", json={
            "name": "Avail Lot",
            "total_spots": 10,
        }, headers=h)
        lot_id = lot.json()["id"]
        client.post(f"/api/parking/spots/seed?lot_id={lot_id}&count=10", headers=h)
        response = client.get("/api/parking/spots/available")
        assert response.status_code == 200
        assert len(response.json()) == 10

    def test_get_stats(self):
        h = _login()
        lot = client.post("/api/parking/lot", json={
            "name": "Stats Lot",
            "total_spots": 10,
        }, headers=h)
        lot_id = lot.json()["id"]
        client.post(f"/api/parking/spots/seed?lot_id={lot_id}&count=10", headers=h)
        response = client.get("/api/parking/stats")
        assert response.status_code == 200
        data = response.json()
        assert data["total_spots"] == 10
        assert data["available"] == 10
        assert data["occupied"] == 0
        assert data["reserved"] == 0
