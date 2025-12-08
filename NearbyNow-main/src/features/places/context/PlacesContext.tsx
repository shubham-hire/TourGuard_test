import { createContext, useContext, useState, ReactNode } from 'react';

interface PlacesContextType {
  categoryFilter: string;
  setCategoryFilter: (category: string) => void;
}

const PlacesContext = createContext<PlacesContextType | undefined>(undefined);

export function PlacesProvider({ children }: { children: ReactNode }) {
  const [categoryFilter, setCategoryFilter] = useState('All');

  return (
    <PlacesContext.Provider value={{ categoryFilter, setCategoryFilter }}>
      {children}
    </PlacesContext.Provider>
  );
}

export function usePlacesContext() {
  const context = useContext(PlacesContext);
  if (!context) {
    throw new Error('usePlacesContext must be used within a PlacesProvider');
  }
  return context;
}
