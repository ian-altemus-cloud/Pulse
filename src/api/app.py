from flask import Flask, jsonify
import datetime
import os

app = Flask(__name__)


@app.route('/health', methods=['GET'])
def health():
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.datetime.utcnow().isoformat(),
        'version': os.environ.get('APP_VERSION', '1.0.0')
    }), 200


@app.route('/metrics', methods=['GET'])
def metrics():
    return jsonify({
        'cpu_utilization': 45.2,
        'memory_utilization': 62.1,
        'request_rate': 120,
        'uptime_seconds': 3600,
        'status': 'nominal'
    }), 200


@app.route('/status', methods=['GET'])
def status():
    return jsonify({
        'environment': os.environ.get('ENVIRONMENT', 'local'),
        'region': os.environ.get('AWS_REGION', 'us-east-1'),
        'task_id': os.environ.get('ECS_TASK_ID', 'local'),
        'version': os.environ.get('APP_VERSION', '1.0.0')
    }), 200


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)
