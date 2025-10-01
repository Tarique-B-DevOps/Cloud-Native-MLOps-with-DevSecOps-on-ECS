# tests/test_app.py
import pytest
from fastapi.testclient import TestClient
from app import app, House

client = TestClient(app)

def test_read_root():
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert "message" in data
    assert data["model_loaded"] is True

def test_health_check():
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"

def test_predict_house_price():
    # Create a sample house input
    house_data = {
        "Size": 1500.0,
        "Bedrooms": 3,
        "Age": 10
    }
    
    response = client.post("/predict", json=house_data)
    assert response.status_code == 200
    data = response.json()
    # Check if predicted_price exists and is a float
    assert "predicted_price" in data
    assert isinstance(data["predicted_price"], float)
