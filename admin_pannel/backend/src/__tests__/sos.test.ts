/**
 * SOS endpoint tests
 */

import request from 'supertest';
import app from '../app';

let authToken: string;

beforeAll(async () => {
    // Login to get auth token
    const response = await request(app)
        .post('/api/auth/login')
        .send({
            email: 'admin@safety.com',
            password: 'password123',
        });
    authToken = response.body.data.token;
});

describe('POST /api/sos', () => {
    it('should create SOS event with valid data', async () => {
        const response = await request(app)
            .post('/api/sos')
            .send({
                userId: 'c3f1b9a2-8d9f-4e2b-9f6a-1f2a3b4c5d6e',
                latitude: 19.075983,
                longitude: 72.877655,
                accuracy: 12,
                message: 'Test emergency',
                timestamp: new Date().toISOString(),
            })
            .expect(201);

        expect(response.body.id).toBeDefined();
        expect(response.body.status).toBe('pending');
        expect(response.body.latitude).toBe(19.075983);
    });

    it('should reject invalid latitude', async () => {
        const response = await request(app)
            .post('/api/sos')
            .send({
                userId: 'c3f1b9a2-8d9f-4e2b-9f6a-1f2a3b4c5d6e',
                latitude: 100,
                longitude: 72.877655,
            })
            .expect(400);

        expect(response.body.error).toMatch(/latitude/i);
    });

    it('should reject invalid longitude', async () => {
        const response = await request(app)
            .post('/api/sos')
            .send({
                userId: 'c3f1b9a2-8d9f-4e2b-9f6a-1f2a3b4c5d6e',
                latitude: 19.075983,
                longitude: 200,
            })
            .expect(400);

        expect(response.body.error).toMatch(/longitude/i);
    });
});

describe('GET /api/sos', () => {
    it('should list SOS events with auth', async () => {
        const response = await request(app)
            .get('/api/sos')
            .set('Authorization', `Bearer ${authToken}`)
            .expect(200);

        expect(response.body.success).toBe(true);
        expect(Array.isArray(response.body.data)).toBe(true);
    });

    it('should reject without auth', async () => {
        await request(app).get('/api/sos').expect(401);
    });

    it('should filter by status', async () => {
        const response = await request(app)
            .get('/api/sos?status=pending')
            .set('Authorization', `Bearer ${authToken}`)
            .expect(200);

        expect(response.body.success).toBe(true);
    });
});

describe('PATCH /api/sos/:id', () => {
    it('should update SOS status with admin auth', async () => {
        // First, get an existing event
        const listResponse = await request(app)
            .get('/api/sos')
            .set('Authorization', `Bearer ${authToken}`);

        const eventId = listResponse.body.data[0]?.id;

        if (eventId) {
            const response = await request(app)
                .patch(`/api/sos/${eventId}`)
                .set('Authorization', `Bearer ${authToken}`)
                .send({ status: 'acknowledged' })
                .expect(200);

            expect(response.body.success).toBe(true);
            expect(response.body.data.status).toBe('acknowledged');
        }
    });

    it('should reject invalid status', async () => {
        const response = await request(app)
            .patch('/api/sos/d5a7f3e8-3d59-4b8b-9f1a-2f3b4c5d6e7f')
            .set('Authorization', `Bearer ${authToken}`)
            .send({ status: 'invalid' })
            .expect(400);

        expect(response.body.error).toBeDefined();
    });
});
