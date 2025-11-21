const placesService = require('../services/placesService');

async function getNearbyPlaces(req, res) {
  try {
    const { lat, lng, radius, type } = req.query;

    // Validation
    if (!lat || !lng) {
      return res.status(400).json({ 
        status: 'error',
        message: 'Latitude and longitude are required parameters.' 
      });
    }

    const latitude = parseFloat(lat);
    const longitude = parseFloat(lng);
    const searchRadius = parseInt(radius) || 50000; // Default 50 km radius

    if (isNaN(latitude) || isNaN(longitude)) {
      return res.status(400).json({ 
        status: 'error',
        message: 'Invalid latitude or longitude format.' 
      });
    }

    const places = await placesService.fetchNearbyPlaces(
      latitude,
      longitude,
      searchRadius,
      type
    );

    res.json({
      status: 'success',
      count: places.length,
      data: places
    });
  } catch (error) {
    console.error('Controller Error:', error);
    
    // Determine status code based on error type if possible, default to 500
    const statusCode = error.response ? error.response.status : 500;
    
    res.status(statusCode).json({
      status: 'error',
      message: 'Failed to fetch places from Google API',
      details: error.message
    });
  }
}

module.exports = {
  getNearbyPlaces
};
