# v1.0.1 - CI/CD pipeline test
import time
import math
import logging
from flask import Flask, jsonify, Response
from prometheus_client import (
    Counter, Histogram, Gauge, generate_latest, CONTENT_TYPE_LATEST
)

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)
app = Flask(__name__)

REQUEST_COUNT = Counter('http_requests_total', 'Total HTTP requests', ['method', 'endpoint', 'status_code'])
REQUEST_LATENCY = Histogram('http_request_duration_seconds', 'Request latency', ['endpoint'],
    buckets=[0.01, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5, 5.0])
IN_PROGRESS = Gauge('http_requests_in_progress', 'Requests in progress')
APP_INFO = Gauge('app_info', 'App metadata', ['version', 'environment'])
APP_INFO.labels(version='1.0.0', environment='production').set(1)

@app.before_request
def before(): IN_PROGRESS.inc()

@app.after_request
def after(r): IN_PROGRESS.dec(); return r

@app.route('/')
def index():
    with REQUEST_LATENCY.labels(endpoint='/').time():
        REQUEST_COUNT.labels(method='GET', endpoint='/', status_code=200).inc()
        return jsonify({'message': 'SRE Auto-Scaling Observability App', 'version': '1.0.0', 'cloud': 'GCP'})

@app.route('/health')
def health():
    with REQUEST_LATENCY.labels(endpoint='/health').time():
        REQUEST_COUNT.labels(method='GET', endpoint='/health', status_code=200).inc()
        return jsonify({'status': 'healthy'}), 200

@app.route('/ready')
def ready():
    with REQUEST_LATENCY.labels(endpoint='/ready').time():
        REQUEST_COUNT.labels(method='GET', endpoint='/ready', status_code=200).inc()
        return jsonify({'status': 'ready'}), 200

@app.route('/metrics')
def metrics():
    return Response(generate_latest(), mimetype=CONTENT_TYPE_LATEST)

@app.route('/stress')
def stress():
    with REQUEST_LATENCY.labels(endpoint='/stress').time():
        start = time.time()
        while time.time() - start < 1:
            math.factorial(10000)
        REQUEST_COUNT.labels(method='GET', endpoint='/stress', status_code=200).inc()
        return jsonify({'status': 'stress complete', 'duration_seconds': 1})

@app.route('/error')
def error():
    REQUEST_COUNT.labels(method='GET', endpoint='/error', status_code=500).inc()
    return jsonify({'error': 'simulated error for SLO alert testing'}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
