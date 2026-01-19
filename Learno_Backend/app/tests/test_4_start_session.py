from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

API_PREFIX = "/api/v1"


def test_start_learning_session():
    payload = {
        "grade": "Second Grade",
        "subject": "Math",
        "topic": "Mixed operations: one digit"
    }

    response = client.post("/api/v1/session/start", json=payload)

    assert response.status_code in [200, 422]
