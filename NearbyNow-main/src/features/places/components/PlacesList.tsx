import { Place } from "../types/place";

interface PlacesListProps {
  places: Place[];
}

export function PlacesList({ places }: PlacesListProps) {
  if (!places.length) return <div>No places found nearby.</div>;

  return (
    <ul className="p-4">
      {places.map((place) => (
        <li key={place.id} className="mb-2">
          <strong>{place.name}</strong> — {place.category} ({place.distance} meters)
        </li>
      ))}
    </ul>
  );
}
