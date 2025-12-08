export function formatDistance(meters: number): string {
    if (meters < 1000) {
      return `${meters} m`;
    } else {
      return `${(meters / 1000).toFixed(1)} km`;
    }
  }
  