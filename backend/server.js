require('dotenv').config();
const express = require('express');
const cors = require('cors');
const placesController = require('./controllers/placesController');
const authController = require('./controllers/authController');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Routes
app.get('/api/places/nearby', placesController.getNearbyPlaces);
app.post('/api/auth/send-otp', authController.sendOtp);
app.post('/api/auth/verify-otp', authController.verifyOtp);

// Health check
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok', timestamp: new Date() });
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on port ${PORT}`);
});
