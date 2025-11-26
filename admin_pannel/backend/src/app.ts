/**
 * Express app configuration
 * Sets up middleware, routes, and error handling
 */

import express, { Request, Response, NextFunction } from 'express';
import cors from 'cors';
import { login } from './controllers/authController';
import { getUserById } from './controllers/userController';
import {
    listSosEvents,
    getSosEventById,
    createSosEvent,
    updateSosStatus,
} from './controllers/sosController';
import { verifyToken, requireAdmin } from './middleware/auth';
import { sosRateLimiter } from './middleware/rateLimiter';
import {
    loginValidation,
    createSosValidation,
    updateSosValidation,
    getUserValidation,
    listSosValidation,
} from './middleware/validators';

const app = express();

// Middleware
app.use(
    cors({
        origin: process.env.CORS_ORIGIN || 'http://localhost:3000',
        credentials: true,
    })
);
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Health check
app.get('/health', (req, res) => {
    res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Auth routes
app.post('/api/auth/login', loginValidation, login);

// User routes (admin only)
app.get('/api/users/:id', verifyToken, requireAdmin, getUserValidation, getUserById);

// SOS routes
app.get('/api/sos', verifyToken, listSosValidation, listSosEvents);
app.get('/api/sos/:id', verifyToken, getSosEventById);
app.post('/api/sos', sosRateLimiter, createSosValidation, createSosEvent);
app.patch('/api/sos/:id', verifyToken, requireAdmin, updateSosValidation, updateSosStatus);

// 404 handler
app.use((req, res) => {
    res.status(404).json({ error: 'Route not found' });
});

// Error handler
app.use((err: Error, req: Request, res: Response, next: NextFunction) => {
    console.error('Error:', err);
    res.status(500).json({ error: 'Internal server error' });
});

export default app;
