const smsService = require('../services/smsService');

/**
 * Send SOS alert with location to emergency contacts
 * POST /api/sos/send
 * Body: {
 *   latitude: number,
 *   longitude: number,
 *   emergencyContacts: Array<{name: string, phone: string}>,
 *   userName?: string
 * }
 */
async function sendSOS(req, res) {
  try {
    const { latitude, longitude, emergencyContacts, userName } = req.body;

    // Validation
    if (!latitude || !longitude) {
      return res.status(400).json({
        success: false,
        error: 'Latitude and longitude are required',
      });
    }

    if (!emergencyContacts || !Array.isArray(emergencyContacts) || emergencyContacts.length === 0) {
      return res.status(400).json({
        success: false,
        error: 'Emergency contacts are required',
      });
    }

    // Create location URL
    const locationUrl = `https://www.google.com/maps/search/?api=1&query=${latitude},${longitude}`;
    
    // Create SOS message
    const userNameText = userName ? `${userName} ` : '';
    const message = `🆘 SOS ALERT! ${userNameText}needs immediate help!\n\nLocation: ${locationUrl}\nCoordinates: ${latitude}, ${longitude}\nTime: ${new Date().toLocaleString()}\n\nPlease respond immediately!`;

    // Send SMS to all emergency contacts
    const results = await smsService.sendSMSToContacts(emergencyContacts, message);

    // Count successful and failed sends
    const successful = results.filter(r => r.success).length;
    const failed = results.filter(r => !r.success).length;

    // Return response
    res.status(200).json({
      success: true,
      message: `SOS alert sent to ${successful} contact(s)`,
      sent: successful,
      failed: failed,
      results: results,
      location: {
        latitude,
        longitude,
        url: locationUrl,
      },
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    console.error('Error sending SOS:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Failed to send SOS alert',
    });
  }
}

module.exports = {
  sendSOS,
};

