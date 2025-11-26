# ML Engine Service

This standalone Python service ingests live tourist telemetry plus historical Meghalaya crime data to detect route deviation, long inactivity, and entries into dangerous zones. It exposes a FastAPI interface and can run locally or inside Docker.

## Features

- Ingest dynamic observations (`POST /observations`) tied to a user/trip.
- Register planned routes (`POST /routes`) to enable deviation scoring.
- Maintain time-aware inactivity checks per trip.
- Load danger-zone polygons from `data/danger_zones.geojson` and flag entries.
- Train an IsolationForest anomaly model using historical + newly stored data (`POST /train`).
- Send structured alerts to tourist/admin/family channels (stubbed; extend with SMS/email providers).

## Getting Started

```bash
cd ml-engine
python -m venv .venv
. .venv/Scripts/Activate   # Windows
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8082
```

The service loads the latest model from `models/anomaly_iforest.joblib`. If it does not exist, a starter model is trained automatically from the bundled sample dataset.

## Key Endpoints

| Method | Path | Purpose |
| --- | --- | --- |
| `GET` | `/health` | Liveness check |
| `POST` | `/routes` | Register or update a tourist’s planned route |
| `POST` | `/observations` | Stream telemetry for real-time monitoring |
| `POST` | `/train` | Re-train the anomaly detector on stored data |
| `GET` | `/alerts/{trip_id}` | Fetch alert history for a trip |
| `GET` | `/geofence-status` | Current zone info for all active trips |

Example payload for `/observations`:

```json
{
  "tourist_id": "tg-001",
  "trip_id": "cherrapunji-day1",
  "timestamp": "2025-11-26T11:30:00Z",
  "lat": 25.2841,
  "lng": 91.5801,
  "speed_mps": 2.3,
  "accuracy_m": 9.5,
  "battery_pct": 82,
  "context": {
    "on_route": true,
    "manual_check_in": false
  }
}
```

## Configuration

Environment variables (optional) can override defaults defined in `app/config.py`.

| Variable | Default | Description |
| --- | --- | --- |
| `ML_ENGINE_ALERT_BUFFER_MINUTES` | `5` | Minimum spacing between repeated alerts per trip |
| `ML_ENGINE_INACTIVITY_MINUTES` | `15` | Base inactivity threshold |
| `ML_ENGINE_ROUTE_DEVIATION_METERS` | `120` | Allowed deviation distance from planned route |

## Extending Alerts

`app/alerts.py` currently logs events in-memory. Replace the handlers with integrations to Firebase Cloud Messaging, Twilio, or your admin panel WebSocket to propagate real alerts to tourists, admins, and family members.

## Tests

```bash
pytest
```

Tests focus on geometric utilities and detection logic to ensure consistent behavior as you iterate on models.

## Data

- `data/historical_observations.csv`: toy dataset for initial training. Replace with sanitized Meghalaya crime/trip data.
- `data/danger_zones.geojson`: seed polygons for known hotspots. Extend with real intelligence feeds.

Keep sensitive data out of version control; mount secure volumes or use environment-specific buckets.

