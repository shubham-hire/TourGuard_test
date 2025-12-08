import { useMapEvents } from 'react-leaflet';

export function useMap() {
  useMapEvents({
    click(e) {
      console.log('Map clicked at', e.latlng);
    },
    moveend(e) {
      console.log('Map moved to', e.target.getCenter());
    }
  });

  return null;
}
