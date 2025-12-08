import { MapContainer, TileLayer, Marker, Popup, Circle, useMap } from 'react-leaflet';
import { useEffect } from 'react';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import { Loader } from '../../../shared/components/Loader';
import { useUserLocation } from '../../location/hooks/useUserLocation';
import { usePlaces } from '../../places/hooks/usePlaces';
import { PlaceMarker } from './PlaceMarker';
import { SearchBar } from './SearchBar';
// import { CategoryFilter } from './CategoryFilter';

function UserLocationMarker({ lat, lng, accuracy }: { lat: number; lng: number; accuracy: number }) {
  const map = useMap();

  useEffect(() => {
    map.setView([lat, lng], map.getZoom(), { animate: true });
  }, [lat, lng, map]);

  const userIcon = new L.DivIcon({
    html: `
      <div style="
        width: 20px;
        height: 20px;
        background: #4285F4;
        border-radius: 50%;
        box-shadow: 0 0 15px #4285F4;
        animation: pulse 1.5s infinite;
      "></div>
    `,
    className: '',
    iconSize: [20, 20],
    iconAnchor: [10, 10],
  });

  return (
    <>
      <Marker position={[lat, lng]} icon={userIcon}>
        <Popup>
          📍 You are here
        </Popup>
      </Marker>
      <Circle
        center={[lat, lng]}
        radius={accuracy}
        pathOptions={{ color: '#4285F4', fillColor: '#4285F4', fillOpacity: 0.2 }}
      />
    </>
  );
}

export function MapContainerView() {
  const { location, loading: locationLoading, error } = useUserLocation();
  const { places, loading: placesLoading } = usePlaces();

  if (locationLoading || placesLoading) return <Loader />;
  if (error || !location) return <div className="text-center p-4">Location not available: {error}</div>;

  return (
    <div className="relative w-full h-screen">
      {/* Top UI elements */}
      {/* <SearchBar /> */}
      {/* <CategoryFilter /> */}

      {/* Map */}
      <MapContainer
        center={[location.lat, location.lng]}
        zoom={14}
        style={{ height: "100%", width: "100%" }}
        scrollWheelZoom={true}
      >
        <TileLayer
          attribution='&copy; <a href="http://osm.org/copyright">OpenStreetMap contributors</a>'
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        />

        {/* Show User Location */}
        <UserLocationMarker lat={location.lat} lng={location.lng} accuracy={50} />

        {/* Show Real Places */}
        {places.map((place) => (
          <PlaceMarker key={place.id} place={place} />
        ))}
      </MapContainer>
    </div>
  );
}