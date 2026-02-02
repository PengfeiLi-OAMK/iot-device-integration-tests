import sqlite3
import datetime
import os
from flask import Flask, request, jsonify

app = Flask(__name__)
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DB_FILE = os.path.join(BASE_DIR, 'database.db')

# --- 1. Database Initialization ---
def init_db():
    conn = sqlite3.connect(DB_FILE)
    c = conn.cursor()
    # Create a table simulating IoT device state
    # Fields: id, target temperature, firmware version, status message, timestamp
    c.execute('''CREATE TABLE IF NOT EXISTS device_state
                 (id INTEGER PRIMARY KEY AUTOINCREMENT,
                  target_temp REAL,
                  firmware_version TEXT,
                  status TEXT,
                  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)''')
    conn.commit()
    conn.close()

# --- 2. Helper Functions: Industrial Rule Validation  ---
def is_valid_temp(temp):
    # Simulates hardware constraints: temperature must be within [-40, 85] range.
    return -40 <= temp <= 85

# --- 3. API Endpoints [cite: 42, 43] ---

@app.route('/api/config', methods=['POST'])
def set_config():
    """
    Receives configuration commands via POST.
    Test points: Input validation, data persistence, and logic consistency.
    """
    data = request.get_json()
    
    # Extract parameters
    raw_temp = data.get('target_temperature')
    firmware = data.get('firmware_version', 'v1.0')

    # Rule validation (Provides logic for automated test cases)
    if raw_temp is None:
        return jsonify({"error": "Missing target_temperature"}), 400
    try:
        target_temp = float(raw_temp)
    except ValueError:
        return jsonify({"error": "target_temperature must be a number"}), 400
    
    if not is_valid_temp(target_temp):
        return jsonify({"error": "Temperature out of range (-40 to 85)"}), 400

    # Write to database (To be verified later by DatabaseLibrary)
    conn = sqlite3.connect(DB_FILE)
    c = conn.cursor()
    c.execute("INSERT INTO device_state (target_temp, firmware_version, status) VALUES (?, ?, ?)",
              (target_temp, firmware, "CONFIGURED"))
    conn.commit()
    conn.close()

    return jsonify({
        "message": "Configuration accepted",
        "configured_temp": target_temp,
        "timestamp": datetime.datetime.now().isoformat()
    }), 200

@app.route('/api/status', methods=['GET'])
def get_status():
    """
    Retrieves current device status via GET.
    Test points: Consistency between API responses and database state.
    """
    conn = sqlite3.connect(DB_FILE)
    c = conn.cursor()
    # Retrieve the most recent status entry
    c.execute("SELECT target_temp, firmware_version, status, updated_at FROM device_state ORDER BY id DESC LIMIT 1")
    row = c.fetchone()
    conn.close()

    if row:
        return jsonify({
            "target_temperature": row[0],
            "firmware_version": row[1],
            "status": row[2],
            "last_update": row[3]
        })
    else:
        return jsonify({"status": "No data available"}), 404

# --- 4. Main Entry Point ---
if __name__ == '__main__':
    init_db() 
    print("🚀 Mock IoT Device running on http://127.0.0.1:5000")
    app.run(debug=True, port=5000)