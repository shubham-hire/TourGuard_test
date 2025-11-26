/**
 * Rate limiter middleware for SOS endpoint
 * Prevents abuse by limiting 1 SOS request per user per 10 seconds
 * 
 * Note: Uses in-memory store for development. For production with
 * multiple instances, use Redis-backed rate limiting (e.g., express-rate-limit with Redis store)
 */

import { Request, Response, NextFunction } from 'express';

interface RateLimitEntry {
    count: number;
    resetTime: number;
}

const rateLimitStore = new Map<string, RateLimitEntry>();
const WINDOW_MS = 10000; // 10 seconds
const MAX_REQUESTS = 1;

/**
 * Rate limit SOS requests per user
 */
export const sosRateLimiter = (req: Request, res: Response, next: NextFunction) => {
    const userId = req.body.userId;

    if (!userId) {
        return res.status(400).json({ error: 'userId is required' });
    }

    const now = Date.now();
    const userLimit = rateLimitStore.get(userId);

    if (!userLimit || now > userLimit.resetTime) {
        // Create new window
        rateLimitStore.set(userId, {
            count: 1,
            resetTime: now + WINDOW_MS,
        });
        return next();
    }

    if (userLimit.count >= MAX_REQUESTS) {
        const retryAfter = Math.ceil((userLimit.resetTime - now) / 1000);
        return res.status(429).json({
            error: 'Too many SOS requests. Please wait before sending another.',
            retryAfter,
        });
    }

    userLimit.count++;
    return next();
};

// Cleanup old entries every minute
setInterval(() => {
    const now = Date.now();
    for (const [userId, entry] of rateLimitStore.entries()) {
        if (now > entry.resetTime) {
            rateLimitStore.delete(userId);
        }
    }
}, 60000);
