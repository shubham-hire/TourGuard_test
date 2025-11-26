/**
 * Map view component with Leaflet
 * Displays SOS events as markers with accuracy circles
 */

import React, { useEffect, useRef } from 'react';
import { MapContainer, TileLayer, Marker, Popup, Circle, useMap } from 'react-leaflet';
import L from 'leaflet';
import { SosEvent } from '../../types';

// Fix Leaflet default marker icon issue with Vite
import markerIcon2x from 'leaflet/dist/images/marker-icon-2x.png';
import markerIcon from 'leaflet/dist/images/marker-icon.png';
import markerShadow from 'leaflet/dist/images/marker-shadow.png';

delete (L.Icon.Default.prototype as any)._getIconUrl;
L.Icon.Default.mergeOptions({
    iconUrl: markerIcon,
    iconRetinaUrl: markerIcon2x,
    shadowUrl: markerShadow,
});

// Custom SOS icon
const sosIcon = new L.Icon({
    iconUrl: 'data:image/svg+xml;base64,' + btoa(`
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#ef4444" width="40" height="40">
      <circle cx="12" cy="12" r="11" fill="#ef4444" opacity="0.3"/>
      <circle cx="12" cy="12" r="8" fill="#ef4444"/>
      <path d="M12 2L15 8L21 9L16 14L18 21L12 17L6 21L8 14L3 9L9 8L12 2Z" fill="white"/>
    </svg>
  `),
    iconSize: [40, 40],
    iconAnchor: [20, 40],
    popupAnchor: [0, -40],
});

interface MapViewProps {
    events: SosEvent[];
    selectedEvent: SosEvent | null;
    onEventClick: (event: SosEvent) => void;
    newEventId?: string | null;
}

// Component to fly to selected event
const MapController: React.FC<{ selectedEvent: SosEvent | null }> = ({ selectedEvent }) => {
    const map = useMap();

    useEffect(() => {
        if (selectedEvent) {
            map.flyTo([selectedEvent.latitude, selectedEvent.longitude], 15);
        }
    }, [selectedEvent, map]);

    return null;
};

const MapView: React.FC<MapViewProps> = ({ events, selectedEvent, onEventClick, newEventId }) => {
    const center: [number, number] = [19.076, 72.8777]; // Mumbai default
    const zoom = 13;

    return (
        <div className="h-full w-full">
            <MapContainer
                center={center}
                zoom={zoom}
                className="h-full w-full rounded-lg"
                style={{ background: '#1e293b' }}
            >
                <TileLayer
                    url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
                    attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
                />

                <MapController selectedEvent={selectedEvent} />

                {events.map((event) => (
                    <React.Fragment key={event.id}>
                        {/* Accuracy circle */}
                        {event.accuracyMeters && (
                            <Circle
                                center={[event.latitude, event.longitude]}
                                radius={event.accuracyMeters}
                                pathOptions={{
                                    fillColor: event.status === 'pending' ? '#ef4444' : '#10b981',
                                    fillOpacity: 0.2,
                                    color: event.status === 'pending' ? '#ef4444' : '#10b981',
                                    weight: 2,
                                }}
                            />
                        )}

                        {/* Marker */}
                        <Marker
                            position={[event.latitude, event.longitude]}
                            icon={sosIcon}
                            eventHandlers={{
                                click: () => onEventClick(event),
                            }}
                        >
                            <Popup>
                                <div className="text-navy-dark">
                                    <h3 className="font-bold">{event.user?.name || 'Unknown User'}</h3>
                                    <p className="text-sm">{event.message || 'No message'}</p>
                                    <p className="text-xs mt-1">
                                        Status:{' '}
                                        <span
                                            className={
                                                event.status === 'pending'
                                                    ? 'text-danger font-semibold'
                                                    : event.status === 'acknowledged'
                                                        ? 'text-warning font-semibold'
                                                        : 'text-success font-semibold'
                                            }
                                        >
                                            {event.status.toUpperCase()}
                                        </span>
                                    </p>
                                </div>
                            </Popup>
                        </Marker>
                    </React.Fragment>
                ))}
            </MapContainer>

            {/* Live location badge */}
            <div className="absolute top-4 left-4 bg-danger px-4 py-2 rounded-lg shadow-lg flex items-center space-x-2 pulse-glow z-[1000]">
                <div className="w-2 h-2 bg-white rounded-full animate-pulse" />
                <span className="text-white font-semibold text-sm">LIVE LOCATION</span>
            </div>
        </div>
    );
};

export default MapView;
