/**
 * Request validation middleware using express-validator
 */

import { body, param, query, validationResult } from 'express-validator';
import { Request, Response, NextFunction } from 'express';

export const validateRequest = (req: Request, res: Response, next: NextFunction) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        return res.status(400).json({ error: errors.array()[0].msg });
    }
    next();
};

export const loginValidation = [
    body('email').isEmail().withMessage('Valid email is required'),
    body('password').notEmpty().withMessage('Password is required'),
    validateRequest,
];

export const createSosValidation = [
    body('userId').optional().isUUID().withMessage('userId must be a valid UUID'),
    body('user')
        .optional()
        .isObject()
        .withMessage('user must be an object when provided'),
    body('user.externalId')
        .optional()
        .isString()
        .trim()
        .notEmpty()
        .withMessage('user.externalId must be a non-empty string'),
    body('user.name').optional().isString().trim(),
    body('user.phone').optional().isString().trim(),
    body('user.email').optional().isEmail().withMessage('user.email must be valid'),
    body('user.medicalConditions').optional().isString().trim(),
    body('user.allergies').optional().isString().trim(),
    body('user.emergencyContacts').optional().isArray().withMessage('emergencyContacts must be an array'),
    body('user.emergencyContacts.*.name').optional().isString().trim(),
    body('user.emergencyContacts.*.relation').optional().isString().trim(),
    body('user.emergencyContacts.*.phone').optional().isString().trim(),
    body('latitude')
        .isFloat({ min: -90, max: 90 })
        .withMessage('Latitude must be between -90 and 90'),
    body('longitude')
        .isFloat({ min: -180, max: 180 })
        .withMessage('Longitude must be between -180 and 180'),
    body('accuracy').optional().isInt({ min: 0 }).withMessage('Accuracy must be a positive integer'),
    body('message').optional().isString().trim(),
    body('timestamp').optional().isISO8601().withMessage('Timestamp must be ISO 8601 format'),
    body().custom((value) => {
        if (!value.userId && !(value.user && value.user.externalId)) {
            throw new Error('Provide either userId or user.externalId');
        }
        return true;
    }),
    validateRequest,
];

export const updateSosValidation = [
    param('id').isUUID().withMessage('Valid SOS event ID (UUID) is required'),
    body('status')
        .isIn(['pending', 'acknowledged', 'resolved'])
        .withMessage('Status must be pending, acknowledged, or resolved'),
    validateRequest,
];

export const getUserValidation = [
    param('id').isUUID().withMessage('Valid user ID (UUID) is required'),
    validateRequest,
];

export const listSosValidation = [
    query('status')
        .optional()
        .isIn(['pending', 'acknowledged', 'resolved'])
        .withMessage('Status must be pending, acknowledged, or resolved'),
    query('since').optional().isISO8601().withMessage('Since must be ISO 8601 format'),
    validateRequest,
];
