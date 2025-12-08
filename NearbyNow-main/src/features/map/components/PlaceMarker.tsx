import { Marker, Popup } from 'react-leaflet';
import L from 'leaflet';
import 'leaflet-extra-markers/dist/css/leaflet.extra-markers.min.css';
import { Place } from '../../places/types/place';

interface PlaceMarkerProps {
  place: Place;
}

export function PlaceMarker({ place }: PlaceMarkerProps) {
  const customIcon = new L.Icon({
    iconUrl: 'https://cdn-icons-png.flaticon.com/512/684/684908.png',
    iconSize: [30, 30],
    iconAnchor: [15, 30],
    popupAnchor: [0, -30],
  });

  return (
    <Marker position={[place.lat, place.lng]} icon={customIcon}>
      <Popup>
        <strong>{place.name}</strong><br />
        {place.category}<br />
        {place.distance} meters away
      </Popup>
    </Marker>
  );
}
