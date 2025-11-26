/**
 * Authentication endpoint tests
 */

import request from 'supertest';
import app from '../app';

describe('POST /api/auth/login', () => {
    it('should login with valid credentials and return JWT', async () => {
        const response = await request(app)
            .post('/api/auth/login')
            .send({
                email: 'admin@safety.com',
                password: 'password123',
            })
            .expect(200);

        expect(response.body.success).toBe(true);
        expect(response.body.data.token).toBeDefined();
        expect(response.body.data.user.email).toBe('admin@safety.com');
        expect(response.body.data.user.role).toBe('admin');
    });

    it('should reject invalid email format', async () => {
        const response = await request(app)
            .post('/api/auth/login')
            .send({
                email: 'invalid-email',
                password: 'password123',
            })
            .expect(400);

        expect(response.body.error).toBeDefined();
    });

    it('should reject missing password', async () => {
        const response = await request(app)
            .post('/api/auth/login')
            .send({
                email: 'admin@safety.com',
            })
            .expect(400);

        expect(response.body.error).toBeDefined();
    });

    it('should reject invalid credentials', async () => {
        const response = await request(app)
            .post('/api/auth/login')
            .send({
                email: 'nonexistent@example.com',
                password: 'wrongpassword',
            })
            .expect(401);

        expect(response.body.error).toMatch(/invalid/i);
    });
});
