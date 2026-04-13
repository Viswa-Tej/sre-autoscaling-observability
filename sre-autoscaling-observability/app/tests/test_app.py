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

def test_index(client):
    r = client.get('/')
    assert r.status_code == 200
    data = r.get_json()
    assert data['version'] == '1.0.0'

def test_health(client):
    r = client.get('/health')
    assert r.status_code == 200
    assert r.get_json()['status'] == 'healthy'

def test_ready(client):
    r = client.get('/ready')
    assert r.status_code == 200

def test_metrics(client):
    r = client.get('/metrics')
    assert r.status_code == 200
    assert b'http_requests_total' in r.data

def test_error_endpoint(client):
    r = client.get('/error')
    assert r.status_code == 500
