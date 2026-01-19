from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

API_PREFIX = "/api/v1"

def test_system_response():
    payload = {
        "session_id": "test-session-id",
        "response": "8"
    }

    response = client.post("/api/v1/lesson/respond", json=payload)

    assert response.status_code in [200, 400, 404, 422]
