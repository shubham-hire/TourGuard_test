from datetime import datetime
from typing import Dict, List, Literal, Optional

from pydantic import BaseModel, ConfigDict, Field, computed_field


RiskLevel = Literal["low", "medium", "high"]


class RoutePoint(BaseModel):
    lat: float = Field(ge=-90, le=90)
    lng: float = Field(ge=-180, le=180)
    eta_utc: Optional[datetime] = None


class RoutePlan(BaseModel):
    tourist_id: str
    trip_id: str
    points: List[RoutePoint]
    allowable_deviation_m: Optional[float] = None


class ObservationContext(BaseModel):
    manual_check_in: bool = False
    on_route: Optional[bool] = None
    notes: Optional[str] = None


class Observation(BaseModel):
    tourist_id: str
    trip_id: str
    timestamp: datetime
    lat: float = Field(ge=-90, le=90)
    lng: float = Field(ge=-180, le=180)
    speed_mps: float = Field(ge=0)
    accuracy_m: float = Field(ge=0)
    battery_pct: Optional[float] = Field(default=None, ge=0, le=100)
    heading_deg: Optional[float] = Field(default=None, ge=0, le=360)
    context: ObservationContext = Field(default_factory=ObservationContext)


class DangerZone(BaseModel):
    name: str
    risk_level: RiskLevel
    advisory: Optional[str] = None
    polygon: List[List[float]]


class AlertPayload(BaseModel):
    tourist_id: str
    trip_id: str
    timestamp: datetime
    alert_type: Literal["route_deviation", "long_inactivity", "danger_zone", "anomaly"]
    severity: RiskLevel
    message: str
    metadata: Dict[str, str] = Field(default_factory=dict)

    @computed_field
    def recipients(self) -> List[str]:
        return ["tourist", "admin_panel", "family"]


class TrainRequest(BaseModel):
    retrain_with_new_data: bool = True
    persist_model: bool = True


class TrainResponse(BaseModel):
    model_config = ConfigDict(protected_namespaces=())
    trained_on_rows: int
    model_path: Optional[str]
    feature_importances: Optional[Dict[str, float]] = None


class AlertHistoryResponse(BaseModel):
    trip_id: str
    alerts: List[AlertPayload]


class GeofenceStatus(BaseModel):
    tourist_id: str
    trip_id: str
    inside_zone: bool
    zone_name: Optional[str] = None
    risk_level: Optional[RiskLevel] = None
    advisory: Optional[str] = None
    lat: float
    lng: float
    last_updated: datetime

