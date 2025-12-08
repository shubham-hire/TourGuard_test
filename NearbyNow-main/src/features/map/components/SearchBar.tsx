import { useState } from 'react';
import axios from 'axios';
import { useLocationContext } from '../../location/context/LocationContext';

export function SearchBar() {
  const [query, setQuery] = useState('');
  const { setLocation } = useLocationContext();

  const handleSearch = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!query) return;

    try {
      const response = await axios.get(`https://nominatim.openstreetmap.org/search`, {
        params: {
          q: query,
          format: 'json',
          limit: 1,
        },
      });

      if (response.data.length > 0) {
        const { lat, lon } = response.data[0];
        setLocation({ lat: parseFloat(lat), lng: parseFloat(lon) });
      } else {
        alert('Location not found!');
      }
    } catch (error) {
      console.error('Error searching location:', error);
    }
  };

  return (
    <form onSubmit={handleSearch} className="absolute top-4 left-1/2 transform -translate-x-1/2 z-[1000] flex bg-white p-2 rounded-md shadow-md">
      <input
        type="text"
        value={query}
        onChange={(e) => setQuery(e.target.value)}
        placeholder="Search city..."
        className="p-2 border border-gray-300 rounded-l-md focus:outline-none"
      />
      <button type="submit" className="bg-blue-500 text-white p-2 rounded-r-md hover:bg-blue-600">
        Search
      </button>
    </form>
  );
}
