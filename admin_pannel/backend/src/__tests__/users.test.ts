/**
 * User endpoint tests
 */

import request from 'supertest';
import app from '../app';

let authToken: string;

beforeAll(async () => {
    // Login as admin
    const response = await request(app)
        .post('/api/auth/login')
        .send({
            email: 'admin@safety.com',
            password: 'password123',
        });
    authToken = response.body.data.token;
});

describe('GET /api/users/:id', () => {
    it('should get user details with admin auth', async () => {
        const userId = 'c3f1b9a2-8d9f-4e2b-9f6a-1f2a3b4c5d6e';

        const response = await request(app)
            .get(`/api/users/${userId}`)
            .set('Authorization', `Bearer ${authToken}`)
            .expect(200);

        expect(response.body.success).toBe(true);
        expect(response.body.data.id).toBe(userId);
        expect(response.body.data.name).toBeDefined();
    });

    it('should reject without auth', async () => {
        await request(app)
            .get('/api/users/c3f1b9a2-8d9f-4e2b-9f6a-1f2a3b4c5d6e')
            .expect(401);
    });

    it('should return 404 for non-existent user', async () => {
        const response = await request(app)
            .get('/api/users/00000000-0000-0000-0000-000000000000')
            .set('Authorization', `Bearer ${authToken}`)
            .expect(404);

        expect(response.body.error).toMatch(/not found/i);
    });
});
