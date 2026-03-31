from tests.conftest import client


def _login():
    client.post("/api/auth/register", json={
        "email": "vehicle@test.com",
        "password": "password123",
        "full_name": "Vehicle User",
    })
    r = client.post("/api/auth/login", json={
        "email": "vehicle@test.com",
        "password": "password123",
    })
    return {"Authorization": f"Bearer {r.json()['access_token']}"}


class TestVehicles:
    def test_create_vehicle(self):
        h = _login()
        response = client.post("/api/vehicles", json={
            "plate_number": "ABC123",
            "vehicle_type": "sedan",
            "color": "blue",
        }, headers=h)
        assert response.status_code == 201
        data = response.json()
        assert data["plate_number"] == "ABC123"
        assert data["vehicle_type"] == "sedan"
        assert data["color"] == "blue"

    def test_create_duplicate_vehicle(self):
        h = _login()
        client.post("/api/vehicles", json={
            "plate_number": "DUP123",
        }, headers=h)
        response = client.post("/api/vehicles", json={
            "plate_number": "DUP123",
        }, headers=h)
        assert response.status_code == 400

    def test_get_vehicles(self):
        h = _login()
        client.post("/api/vehicles", json={
            "plate_number": "V1",
        }, headers=h)
        client.post("/api/vehicles", json={
            "plate_number": "V2",
        }, headers=h)
        response = client.get("/api/vehicles", headers=h)
        assert response.status_code == 200
        assert len(response.json()) >= 2

    def test_get_vehicle_by_id(self):
        h = _login()
        res = client.post("/api/vehicles", json={
            "plate_number": "GET1",
        }, headers=h)
        vehicle_id = res.json()["id"]
        response = client.get(f"/api/vehicles/{vehicle_id}", headers=h)
        assert response.status_code == 200
        assert response.json()["plate_number"] == "GET1"

    def test_delete_vehicle(self):
        h = _login()
        res = client.post("/api/vehicles", json={
            "plate_number": "DEL1",
        }, headers=h)
        vehicle_id = res.json()["id"]
        response = client.delete(f"/api/vehicles/{vehicle_id}", headers=h)
        assert response.status_code == 204
        response = client.get(f"/api/vehicles/{vehicle_id}", headers=h)
        assert response.status_code == 404

    def test_get_vehicle_not_found(self):
        h = _login()
        response = client.get("/api/vehicles/9999", headers=h)
        assert response.status_code == 404
