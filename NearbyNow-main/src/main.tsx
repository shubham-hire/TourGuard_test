import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';
import './index.css';
import 'leaflet/dist/leaflet.css';
import { LocationProvider } from './features/location/context/LocationContext';

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <LocationProvider>
      <App />
    </LocationProvider>
  </React.StrictMode>,
);
