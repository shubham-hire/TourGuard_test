/**
 * Authentication middleware
 * Verifies JWT tokens and enforces role-based access control
 */

import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { JwtPayload } from '../types';

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';
const AUTH_DISABLED = (process.env.DISABLE_ADMIN_AUTH || 'false').toLowerCase() === 'true';

if (AUTH_DISABLED) {
    console.warn('[auth] DISABLE_ADMIN_AUTH is enabled. All admin routes are unprotected. Use only in local development.');
}

export interface AuthRequest extends Request {
    user?: JwtPayload;
}

/**
 * Verify JWT token from Authorization header
 */
export const verifyToken = (req: AuthRequest, res: Response, next: NextFunction) => {
    if (AUTH_DISABLED) {
        req.user = {
            userId: 'disabled-auth-user',
            email: 'admin@tourguard.local',
            role: 'admin',
        };
        return next();
    }

    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return res.status(401).json({ error: 'No token provided' });
    }

    const token = authHeader.substring(7);

    try {
        const decoded = jwt.verify(token, JWT_SECRET) as JwtPayload;
        req.user = decoded;
        next();
    } catch (error) {
        return res.status(401).json({ error: 'Invalid or expired token' });
    }
};

/**
 * Ensure user has admin role
 */
export const requireAdmin = (req: AuthRequest, res: Response, next: NextFunction) => {
    if (AUTH_DISABLED) {
        return next();
    }

    if (!req.user || req.user.role !== 'admin') {
        return res.status(403).json({ error: 'Admin access required' });
    }
    next();
};
