import { useState, useEffect } from 'react';
import { useUserLocation } from '../../location/hooks/useUserLocation';
import { fetchNearbyPlaces } from '../api/placesApi';
import { Place } from '../types/place';
import { usePlacesContext } from '../context/PlacesContext';

export function usePlaces() {
  const [allPlaces, setAllPlaces] = useState<Place[]>([]);
  const [places, setPlaces] = useState<Place[]>([]);
  const [loading, setLoading] = useState(true);
  const { location } = useUserLocation();
  const { categoryFilter } = usePlacesContext();

  useEffect(() => {
    if (!location) return;

    const fetchPlacesNearby = async () => {
      try {
        const data = await fetchNearbyPlaces(location.lat, location.lng);
        setAllPlaces(data);
      } catch (error) {
        console.error('Error fetching nearby places:', error);
      } finally {
        setLoading(false);
      }
    };

    fetchPlacesNearby();
  }, [location]);

  useEffect(() => {
    if (categoryFilter === 'All') {
      setPlaces(allPlaces);
    } else {
      setPlaces(allPlaces.filter((place) =>
        place.category.toLowerCase().includes(categoryFilter.toLowerCase())
      ));
    }
  }, [categoryFilter, allPlaces]);

  return { places, loading };
}