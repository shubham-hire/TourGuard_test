import express from 'express';
import { Request, Response } from 'express';

const router = express.Router();

// The Main NestJS Backend — source of truth for SOS alerts
const MAIN_BACKEND_URL = process.env.MAIN_BACKEND_URL || 'https://tourguard-test.onrender.com';

// Helper to forward requests to the main backend (uses native fetch)
async function proxyFetch(path: string, options: RequestInit = {}): Promise<any> {
  const url = `${MAIN_BACKEND_URL}${path}`;
  console.log(`[SOS Proxy] → ${options.method || 'GET'} ${url}`);
  const resp = await fetch(url, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...((options.headers as Record<string, string>) || {}),
    },
  });
  const text = await resp.text();
  let body: any = {};
  try { body = JSON.parse(text); } catch { body = { raw: text }; }
  return { ok: resp.ok, status: resp.status, body };
}

// GET /api/sos-alerts — proxied from Main Backend
router.get('/api/sos-alerts', async (req: Request, res: Response) => {
  try {
    const queryString = req.url.includes('?') ? req.url.substring(req.url.indexOf('?')) : '';
    const authHeader = req.headers.authorization || '';

    const { ok, status, body } = await proxyFetch(`/api/sos-alerts${queryString}`, {
      method: 'GET',
      headers: { Authorization: authHeader },
    });

    if (!ok) {
      console.error('[SOS Proxy] Main backend error:', status, body);
      return res.json({ success: true, data: [] });
    }

    // Main backend returns an array directly, wrap it
    const events: any[] = Array.isArray(body) ? body : (body.data || body || []);

    // Normalize fields to match the SosEvent interface the frontend expects
    const normalized = events.map((e: any) => ({
      id: e.id,
      userId: e.user?.id || e.userId || 'unknown',
      latitude: parseFloat(e.latitude) || 0,
      longitude: parseFloat(e.longitude) || 0,
      message: e.message || 'SOS Alert',
      status: (e.status || 'PENDING').toLowerCase(),
      createdAt: e.triggeredAt || e.createdAt || new Date().toISOString(),
      resolvedAt: e.resolvedAt || undefined,
      user: e.user
        ? {
            name: e.user.name || e.user.email || 'Unknown',
            phone: e.user.phone || '',
            email: e.user.email || '',
            medicalConditions: e.user.medicalConditions,
            allergies: e.user.allergies,
            emergencyContacts: e.user.emergencyContacts,
          }
        : undefined,
    }));

    return res.json({ success: true, data: normalized });
  } catch (error: any) {
    console.error('[SOS Proxy] Error:', error.message);
    return res.json({ success: true, data: [] });
  }
});

// GET /api/sos-alerts/:id
router.get('/api/sos-alerts/:id', async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const authHeader = req.headers.authorization || '';

    const { ok, status, body } = await proxyFetch(`/api/sos-alerts/${id}`, {
      method: 'GET',
      headers: { Authorization: authHeader },
    });

    if (!ok) {
      return res.status(status).json({ success: false, error: 'SOS event not found' });
    }

    return res.json({ success: true, data: body });
  } catch (error: any) {
    console.error('[SOS Proxy] Error fetching by ID:', error.message);
    return res.status(500).json({ success: false, error: 'Proxy error' });
  }
});

// POST /api/sos-alerts — forward to Main Backend
router.post('/api/sos-alerts', async (req: Request, res: Response) => {
  try {
    const authHeader = req.headers.authorization || '';

    const { ok, status, body } = await proxyFetch('/api/sos-alerts', {
      method: 'POST',
      headers: { Authorization: authHeader },
      body: JSON.stringify(req.body),
    });

    if (!ok) {
      return res.status(status).json({ success: false, error: body?.message || 'Failed to create SOS' });
    }

    return res.status(201).json({ success: true, data: body });
  } catch (error: any) {
    console.error('[SOS Proxy] Error creating SOS:', error.message);
    return res.status(500).json({ success: false, error: 'Proxy error' });
  }
});

// PATCH /api/sos-alerts/:id/status — forward to Main Backend
router.patch('/api/sos-alerts/:id/status', async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const { status } = req.body;
    const authHeader = req.headers.authorization || '';

    // Map lowercase statuses to the enum the Main Backend expects
    const statusMap: Record<string, string> = {
      pending: 'PENDING',
      acknowledged: 'ACKNOWLEDGED',
      resolved: 'RESOLVED',
    };

    const { ok, status: httpStatus, body } = await proxyFetch(`/api/sos-alerts/${id}/status`, {
      method: 'PATCH',
      headers: { Authorization: authHeader },
      body: JSON.stringify({ status: statusMap[status] || status }),
    });

    if (!ok) {
      return res.status(httpStatus).json({ success: false, error: 'Failed to update status' });
    }

    return res.json({ success: true, data: body });
  } catch (error: any) {
    console.error('[SOS Proxy] Error updating status:', error.message);
    return res.status(500).json({ success: false, error: 'Proxy error' });
  }
});

export default router;
