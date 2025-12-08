import { LocationProvider } from './features/location/context/LocationContext';
import { MapContainerView } from './features/map/components/MapContainerView';
import { PlacesProvider } from './features/places/context/PlacesContext';

function App() {
  return (
    <LocationProvider>
      <PlacesProvider>
        <MapContainerView />
      </PlacesProvider>
    </LocationProvider>
  );
}

export default App;
