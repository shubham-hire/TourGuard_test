/**
 * API client using Axios
 * Configured with JWT interceptor
 */

import axios from 'axios';
import { LoginCredentials, LoginResponse, SosEvent, User, Incident, ApiResponse } from '../types';

// Use environment variable for API base URL, with fallback to Render deployment
// Set VITE_API_BASE_URL in .env for local development or Render environment
const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'https://tourguard-test.onrender.com';

const apiClient = axios.create({
    baseURL: API_BASE_URL,
    headers: {
        'Content-Type': 'application/json',
    },
    timeout: 30000, // 30 second timeout for slow Render cold starts
});

// Add JWT token to requests
apiClient.interceptors.request.use((config) => {
    const token = localStorage.getItem('token');
    if (token) {
        config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
});

// Handle 401 errors (redirect to login)
apiClient.interceptors.response.use(
    (response) => response,
    (error) => {
        if (error.response?.status === 401) {
            localStorage.removeItem('token');
            localStorage.removeItem('user');
            window.location.href = '/login';
        }
        return Promise.reject(error);
    }
);

export const authApi = {
    login: async (credentials: LoginCredentials): Promise<LoginResponse> => {
        const response = await apiClient.post<LoginResponse>('/api/auth/login', credentials);
        return response.data;
    },
};

export const userApi = {
    getUserById: async (id: string): Promise<User> => {
        const response = await apiClient.get<ApiResponse<User>>(`/api/users/${id}`);
        return response.data.data!;
    },
};

// Helper to parse location from various formats
const parseLocation = (location: any): { latitude: number; longitude: number } | null => {
    if (!location) return null;

    // If it's already an object with lat/lng
    if (typeof location === 'object' && location.latitude && location.longitude) {
        return { latitude: Number(location.latitude), longitude: Number(location.longitude) };
    }

    // If it's the string "[object Object]" (bad data)
    if (location === '[object Object]') return null;

    // If it's a JSON string, parse it
    if (typeof location === 'string') {
        try {
            const parsed = JSON.parse(location);
            if (parsed.latitude && parsed.longitude) {
                return { latitude: Number(parsed.latitude), longitude: Number(parsed.longitude) };
            }
        } catch {
            return null;
        }
    }

    return null;
};

// Helper to parse description
const parseDescription = (desc: any): { message?: string; status?: string } => {
    if (!desc) return {};
    if (typeof desc === 'string') {
        try {
            const parsed = JSON.parse(desc);
            return { message: parsed.originalMessage, status: parsed.status };
        } catch {
            return { message: desc };
        }
    }
    return { message: String(desc) };
};

export const sosApi = {
    // SOS events are fetched from the dedicated /api/sos-alerts endpoint
    listEvents: async (filters?: { status?: string; since?: string }): Promise<SosEvent[]> => {
        const params = new URLSearchParams();
        if (filters?.status) params.append('status', filters.status.toUpperCase()); // Backend uses uppercase
        if (filters?.since) params.append('since', filters.since);

        const response = await apiClient.get<any>(
            `/api/sos-alerts?${params.toString()}`
        );
        // Backend returns array directly from sos-alerts endpoint
        const data = Array.isArray(response.data) ? response.data : response.data?.data || [];

        console.log('[DEBUG] Raw SOS alerts from backend:', data.length, data);

        // Transform SOS alerts to SosEvent format
        return data
            .map((item: any) => {
                // Backend returns latitude/longitude directly, and status in uppercase
                const latitude = Number(item.latitude);
                const longitude = Number(item.longitude);

                // Skip invalid coordinates
                if (isNaN(latitude) || isNaN(longitude)) {
                    console.log('[DEBUG] Skipping SOS with invalid location:', item);
                    return null;
                }

                // Convert backend status (PENDING/ACKNOWLEDGED/RESOLVED) to lowercase for frontend
                const statusMap: { [key: string]: string } = {
                    'PENDING': 'pending',
                    'ACKNOWLEDGED': 'acknowledged',
                    'RESOLVED': 'resolved',
                };
                const status = statusMap[item.status] || 'pending';

                return {
                    id: item.id,
                    userId: item.user?.id || '',
                    latitude: latitude,
                    longitude: longitude,
                    message: item.message || 'SOS Widget Triggered',
                    status: status,
                    createdAt: item.triggeredAt || item.createdAt,
                    user: item.user || { name: 'Unknown', phone: '', email: '' },
                } as SosEvent;
            })
            .filter((item: SosEvent | null): item is SosEvent => item !== null)
            .sort((a: SosEvent, b: SosEvent) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());
    },

    getEventById: async (id: string): Promise<SosEvent> => {
        const response = await apiClient.get<any>(`/api/sos-alerts/${id}`);
        const item = response.data;
        
        const statusMap: { [key: string]: string } = {
            'PENDING': 'pending',
            'ACKNOWLEDGED': 'acknowledged',
            'RESOLVED': 'resolved',
        };

        return {
            id: item.id,
            userId: item.user?.id || '',
            latitude: Number(item.latitude),
            longitude: Number(item.longitude),
            message: item.message || 'SOS Alert',
            status: statusMap[item.status] || 'pending',
            createdAt: item.triggeredAt || item.createdAt,
            user: item.user || { name: 'Unknown', phone: '', email: '' },
        } as SosEvent;
    },

    createEvent: async (event: {
        userId: string;
        latitude: number;
        longitude: number;
        accuracy?: number;
        message?: string;
    }): Promise<SosEvent> => {
        const response = await apiClient.post<any>('/api/sos-alerts', {
            userId: event.userId,
            latitude: event.latitude,
            longitude: event.longitude,
            message: event.message || 'SOS Alert from Admin Panel',
        });
        
        const item = response.data;
        const statusMap: { [key: string]: string } = {
            'PENDING': 'pending',
            'ACKNOWLEDGED': 'acknowledged',
            'RESOLVED': 'resolved',
        };

        return {
            id: item.id,
            userId: item.user?.id || event.userId,
            latitude: Number(item.latitude),
            longitude: Number(item.longitude),
            message: item.message,
            status: statusMap[item.status] || 'pending',
            createdAt: item.triggeredAt || item.createdAt,
            user: item.user,
        } as SosEvent;
    },

    updateStatus: async (id: string, status: 'acknowledged' | 'resolved'): Promise<SosEvent> => {
        // Backend expects uppercase status
        const backendStatus = status.toUpperCase();
        const response = await apiClient.patch<any>(`/api/sos-alerts/${id}/status`, { status: backendStatus });
        
        const item = response.data;
        const statusMap: { [key: string]: string } = {
            'PENDING': 'pending',
            'ACKNOWLEDGED': 'acknowledged',
            'RESOLVED': 'resolved',
        };

        return {
            id: item.id,
            userId: item.user?.id || '',
            latitude: Number(item.latitude),
            longitude: Number(item.longitude),
            message: item.message,
            status: statusMap[item.status] || status,
            createdAt: item.triggeredAt || item.createdAt,
            user: item.user,
        } as SosEvent;
    },
};

export const incidentsApi = {
    // Regular incidents (excludes SOS alerts)
    listIncidents: async (filters?: { type?: 'sos' | 'regular'; status?: string; since?: string }): Promise<Incident[]> => {
        const params = new URLSearchParams();
        if (filters?.type) params.append('type', filters.type);
        if (filters?.status) params.append('status', filters.status);
        if (filters?.since) params.append('since', filters.since);

        const response = await apiClient.get<any[]>(
            `/api/incidents?${params.toString()}`
        );
        // Backend returns array directly
        const data = Array.isArray(response.data) ? response.data : (response.data as any)?.data || [];

        console.log('[DEBUG] Raw incidents from backend:', data.length, data);

        // Transform to proper Incident format - EXCLUDE SOS alerts
        const filtered = data
            .filter((item: any) => {
                // Exclude SOS alerts (they are shown in sosApi)
                const isSos = item.severity === 'CRITICAL' &&
                    (item.title?.includes('SOS') || item.description?.includes('"category":"SOS"'));
                if (isSos) console.log('[DEBUG] Filtering out SOS:', item.title);
                return !isSos;
            })
            .map((item: any) => {
                const loc = parseLocation(item.location);
                const desc = parseDescription(item.description);

                console.log('[DEBUG] Incident:', item.title, 'location raw:', item.location, 'parsed:', loc);

                return {
                    id: item.id,
                    title: item.title,
                    description: desc.message || item.description,
                    category: item.category || 'General',
                    severity: item.severity,
                    status: desc.status || item.status || 'reported',
                    location: loc || { latitude: 0, longitude: 0 },
                    createdAt: item.createdAt,
                    user: item.user,
                } as Incident;
            })
            .filter((item: Incident) => {
                const hasValidLocation = item.location &&
                    item.location.latitude !== 0 &&
                    item.location.longitude !== 0;
                if (!hasValidLocation) console.log('[DEBUG] Filtering out due to invalid location:', item.title, item.location);
                return hasValidLocation;
            })
            .sort((a: Incident, b: Incident) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());

        console.log('[DEBUG] Final incidents after filtering:', filtered.length);
        return filtered;
    },

    getIncidentById: async (id: string): Promise<Incident> => {
        const response = await apiClient.get<any>(`/api/incidents/${id}`);
        const item = response.data;
        const loc = parseLocation(item.location);
        const desc = parseDescription(item.description);

        return {
            id: item.id,
            title: item.title,
            description: desc.message || item.description,
            category: item.category || 'General',
            severity: item.severity,
            status: desc.status || item.status || 'reported',
            location: loc || { latitude: 0, longitude: 0 },
            createdAt: item.createdAt,
            user: item.user,
        } as Incident;
    },
};

export default apiClient;
