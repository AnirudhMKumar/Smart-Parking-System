from tests.conftest import client


class TestAuth:
    def test_register_success(self):
        response = client.post("/api/auth/register", json={
            "email": "test@example.com",
            "password": "password123",
            "full_name": "Test User",
        })
        assert response.status_code == 201
        data = response.json()
        assert data["email"] == "test@example.com"
        assert data["full_name"] == "Test User"
        assert "id" in data

    def test_register_duplicate_email(self):
        client.post("/api/auth/register", json={
            "email": "dup@example.com",
            "password": "password123",
            "full_name": "User",
        })
        response = client.post("/api/auth/register", json={
            "email": "dup@example.com",
            "password": "password123",
            "full_name": "User2",
        })
        assert response.status_code == 400

    def test_login_success(self):
        client.post("/api/auth/register", json={
            "email": "login@example.com",
            "password": "password123",
            "full_name": "Login User",
        })
        response = client.post("/api/auth/login", json={
            "email": "login@example.com",
            "password": "password123",
        })
        assert response.status_code == 200
        assert "access_token" in response.json()
        assert response.json()["token_type"] == "bearer"

    def test_login_wrong_password(self):
        client.post("/api/auth/register", json={
            "email": "wrong@example.com",
            "password": "password123",
            "full_name": "User",
        })
        response = client.post("/api/auth/login", json={
            "email": "wrong@example.com",
            "password": "wrongpassword",
        })
        assert response.status_code == 401

    def test_login_nonexistent_user(self):
        response = client.post("/api/auth/login", json={
            "email": "nobody@example.com",
            "password": "password123",
        })
        assert response.status_code == 401

    def test_get_me(self):
        client.post("/api/auth/register", json={
            "email": "me@example.com",
            "password": "password123",
            "full_name": "Me User",
        })
        login = client.post("/api/auth/login", json={
            "email": "me@example.com",
            "password": "password123",
        })
        token = login.json()["access_token"]
        response = client.get("/api/auth/me", headers={"Authorization": f"Bearer {token}"})
        assert response.status_code == 200
        assert response.json()["email"] == "me@example.com"

    def test_get_me_unauthorized(self):
        response = client.get("/api/auth/me", headers={"Authorization": "Bearer invalid_token"})
        assert response.status_code == 401
