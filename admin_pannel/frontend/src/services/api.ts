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
    // SOS events are ONLY incidents with CRITICAL severity AND 'SOS' in title
    listEvents: async (filters?: { status?: string; since?: string }): Promise<SosEvent[]> => {
        const params = new URLSearchParams();
        if (filters?.status) params.append('status', filters.status);
        if (filters?.since) params.append('since', filters.since);

        const response = await apiClient.get<any>(
            `/api/incidents?${params.toString()}`
        );
        // Backend returns array directly
        const data = Array.isArray(response.data) ? response.data : response.data?.data || [];

        // Transform incidents to SosEvent format - ONLY SOS alerts
        return data
            .filter((item: any) =>
                // Only include actual SOS alerts (CRITICAL severity with SOS in title)
                item.severity === 'CRITICAL' &&
                (item.title?.includes('SOS') || item.description?.includes('"category":"SOS"'))
            )
            .map((item: any) => {
                const loc = parseLocation(item.location);
                const desc = parseDescription(item.description);
                if (!loc) return null;

                // Extract user name from message like "SOS triggered by yogesh at..."
                const message = desc.message || item.title || '';
                const nameMatch = message.match(/SOS triggered by (\w+)/i);
                const userName = nameMatch ? nameMatch[1] : 'Unknown';

                return {
                    id: item.id,
                    userId: item.userId || '',
                    latitude: loc.latitude,
                    longitude: loc.longitude,
                    message: message,
                    status: desc.status === 'resolved' ? 'resolved' :
                        desc.status === 'acknowledged' ? 'acknowledged' : 'pending',
                    createdAt: item.createdAt,
                    user: item.user || { name: userName, phone: '', email: '' },
                } as SosEvent;
            })
            .filter((item: SosEvent | null): item is SosEvent =>
                item !== null &&
                !isNaN(item.latitude) &&
                !isNaN(item.longitude)
            )
            .sort((a: SosEvent, b: SosEvent) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());
    },

    getEventById: async (id: string): Promise<SosEvent> => {
        const response = await apiClient.get<SosEvent | ApiResponse<SosEvent>>(`/api/incidents/${id}`);
        // Handle both wrapped and unwrapped responses
        return 'data' in response.data && response.data.data ? response.data.data : response.data as SosEvent;
    },

    createEvent: async (event: {
        userId: string;
        latitude: number;
        longitude: number;
        accuracy?: number;
        message?: string;
    }): Promise<SosEvent> => {
        const response = await apiClient.post<SosEvent>('/api/incidents', {
            title: 'SOS Alert',
            description: JSON.stringify({ originalMessage: event.message, category: 'SOS', status: 'reported' }),
            severity: 'CRITICAL',
            location: JSON.stringify({ latitude: event.latitude, longitude: event.longitude, userId: event.userId }),
        });
        return response.data;
    },

    updateStatus: async (id: string, status: 'acknowledged' | 'resolved'): Promise<SosEvent> => {
        const response = await apiClient.patch<SosEvent | ApiResponse<SosEvent>>(`/api/incidents/${id}`, { status });
        return 'data' in response.data && response.data.data ? response.data.data : response.data as SosEvent;
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

