/**
 * HTTP server entry point
 * Starts Express app with Socket.IO
 */

import http from 'http';
import dotenv from 'dotenv';
import app from './app';
import { initializeSocket } from './socket';
import pool from './config/database';

dotenv.config();

const PORT = process.env.PORT || 5000;

// Create HTTP server
const server = http.createServer(app);

// Initialize Socket.IO
initializeSocket(server);

// Test database connection
pool.query('SELECT NOW()', (err, res) => {
    if (err) {
        console.error('Database connection error:', err);
        process.exit(1);
    }
    console.log('✓ Database connected successfully');
});

// Start server
server.listen(PORT, () => {
    console.log(`✓ Server running on port ${PORT}`);
    console.log(`✓ Socket.IO enabled for real-time updates`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
    console.log('SIGTERM received, shutting down gracefully...');
    server.close(() => {
        pool.end();
        console.log('Server closed');
        process.exit(0);
    });
});
