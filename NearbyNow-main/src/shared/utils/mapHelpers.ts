import { LatLngLiteral } from 'leaflet';

export function getDistanceInMeters(a: LatLngLiteral, b: LatLngLiteral): number {
  const R = 6371e3; // meters
  const φ1 = (a.lat * Math.PI) / 180;
  const φ2 = (b.lat * Math.PI) / 180;
  const Δφ = ((b.lat - a.lat) * Math.PI) / 180;
  const Δλ = ((b.lng - a.lng) * Math.PI) / 180;

  const haversine = Math.sin(Δφ/2) * Math.sin(Δφ/2) +
                    Math.cos(φ1) * Math.cos(φ2) *
                    Math.sin(Δλ/2) * Math.sin(Δλ/2);

  const c = 2 * Math.atan2(Math.sqrt(haversine), Math.sqrt(1-haversine));

  const d = R * c;

  return Math.round(d); // in meters
}
