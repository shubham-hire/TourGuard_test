from __future__ import annotations

from collections import defaultdict, deque
from datetime import datetime, timedelta
from pathlib import Path
from typing import Deque, Dict, List, Optional, Tuple

import pandas as pd

from .config import get_settings
from .schemas import AlertPayload, GeofenceStatus, Observation, RoutePlan


class ObservationStore:
    """Persists observations and route plans in-memory plus CSV snapshots."""

    def __init__(self) -> None:
        self._obs: Dict[str, Deque[Observation]] = defaultdict(lambda: deque(maxlen=5000))
        self._routes: Dict[str, RoutePlan] = {}
        self._alerts: Dict[str, List[AlertPayload]] = defaultdict(list)
        self._last_alert_at: Dict[Tuple[str, str], datetime] = {}
        self._geofence_status: Dict[str, GeofenceStatus] = {}
        self.settings = get_settings()
        self.settings.data_dir.mkdir(parents=True, exist_ok=True)

    def add_observation(self, obs: Observation) -> None:
        key = self._trip_key(obs.tourist_id, obs.trip_id)
        self._obs[key].append(obs)
        self._append_to_csv(obs)

    def add_route(self, plan: RoutePlan) -> None:
        key = self._trip_key(plan.tourist_id, plan.trip_id)
        self._routes[key] = plan

    def get_route(self, tourist_id: str, trip_id: str) -> Optional[RoutePlan]:
        return self._routes.get(self._trip_key(tourist_id, trip_id))

    def get_observations(self, tourist_id: str, trip_id: str) -> List[Observation]:
        return list(self._obs.get(self._trip_key(tourist_id, trip_id), []))

    def record_alert(self, alert: AlertPayload) -> bool:
        key = self._trip_key(alert.tourist_id, alert.trip_id)
        now = alert.timestamp
        if not self._can_alert(key, now):
            return False
        self._alerts[key].append(alert)
        self._last_alert_at[key] = now
        return True

    def get_alerts(self, trip_id: str) -> List[AlertPayload]:
        return self._alerts.get(trip_id, [])

    def update_geofence_status(self, status: GeofenceStatus) -> None:
        key = self._trip_key(status.tourist_id, status.trip_id)
        self._geofence_status[key] = status

    def list_geofence_status(self) -> List[GeofenceStatus]:
        return list(self._geofence_status.values())

    def load_dataframe(self) -> pd.DataFrame:
        dataset = self.settings.historical_dataset
        if dataset.exists():
            return pd.read_csv(dataset, parse_dates=["timestamp"])
        return pd.DataFrame()

    def _append_to_csv(self, obs: Observation) -> None:
        dataset = self.settings.historical_dataset
        row = {
            "tourist_id": obs.tourist_id,
            "trip_id": obs.trip_id,
            "timestamp": obs.timestamp.isoformat(),
            "lat": obs.lat,
            "lng": obs.lng,
            "speed_mps": obs.speed_mps,
            "accuracy_m": obs.accuracy_m,
            "battery_pct": obs.battery_pct,
        }
        header = not dataset.exists()
        df = pd.DataFrame([row])
        df.to_csv(dataset, mode="a", header=header, index=False)

    def _can_alert(self, key: Tuple[str, str], now: datetime) -> bool:
        last = self._last_alert_at.get(key)
        if last is None:
            return True
        buffer_minutes = self.settings.alert_buffer_minutes
        return now - last >= timedelta(minutes=buffer_minutes)

    @staticmethod
    def _trip_key(tourist_id: str, trip_id: str) -> str:
        return f"{tourist_id}::{trip_id}"


store = ObservationStore()

