import pytest
import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
from app import app

@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_health_returns_200(client):
    response = client.get('/health')
    assert response.status_code == 200

def test_health_returns_healthy(client):
    response = client.get('/health')
    data = response.get_json()
    assert data['status'] == 'healthy'

def test_metrics_returns_200(client):
    response = client.get('/metrics')
    assert response.status_code == 200

def test_status_returns_200(client):
    response = client.get('/status')
    assert response.status_code == 200