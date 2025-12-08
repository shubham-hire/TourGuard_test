import axios from 'axios';
import { Place } from '../types/place';

export async function fetchNearbyPlaces(lat: number, lng: number): Promise<Place[]> {
  const radius = 1000; // radius in meters (1 km)

  const overpassQuery = `
    [out:json];
    (
      node["shop"](around:${radius},${lat},${lng});
      node["amenity"="cafe"](around:${radius},${lat},${lng});
      node["amenity"="restaurant"](around:${radius},${lat},${lng});
    );
    out body;
  `;

  const queryString = `data=${encodeURIComponent(overpassQuery)}`;

  const response = await axios.post(
    'https://overpass-api.de/api/interpreter',
    queryString,
    {
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
    }
  );

  const elements = response.data.elements;

  return elements.map((el: any) => ({
    id: el.id,
    name: el.tags?.name || 'Unnamed Place',
    category: el.tags?.shop || el.tags?.amenity || 'Unknown',
    lat: el.lat,
    lng: el.lon,
    distance: 0, // (optional) you can calculate distance from user later
  }));
}
