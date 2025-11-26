/**
 * Main Dashboard component
 * Assembles all dashboard components and handles real-time updates
 */

import React, { useState, useEffect, useCallback } from 'react';
import toast, { Toaster } from 'react-hot-toast';
import Header from '../Layout/Header';
import Sidebar from '../Layout/Sidebar';
import MapView from './MapView';
import SosList from './SosList';
import EventDetailPanel from './EventDetailPanel';
import NearbyResources from './NearbyResources';
import UserInfoCard from './UserInfoCard';
import EmergencyContacts from './EmergencyContacts';
import CommunicationLog from './CommunicationLog';
import { SosEvent } from '../../types';
import { sosApi } from '../../services/api';
import { initializeSocket, onSosNew, onSosUpdate, disconnectSocket } from '../../services/socket';

const Dashboard: React.FC = () => {
    const [sidebarOpen, setSidebarOpen] = useState(false);
    const [events, setEvents] = useState<SosEvent[]>([]);
    const [selectedEvent, setSelectedEvent] = useState<SosEvent | null>(null);
    const [loading, setLoading] = useState(true);
    const [newEventId, setNewEventId] = useState<string | null>(null);

    // Fetch initial events
    useEffect(() => {
        const fetchEvents = async () => {
            try {
                const data = await sosApi.listEvents();
                setEvents(data);
            } catch (error) {
                toast.error('Failed to load SOS events');
            } finally {
                setLoading(false);
            }
        };

        fetchEvents();
    }, []);

    // Initialize Socket.IO
    useEffect(() => {
        const socket = initializeSocket();

        // Handle new SOS events
        onSosNew((event: SosEvent) => {
            console.log('New SOS event received:', event);
            setEvents((prev) => [event, ...prev]);
            setNewEventId(event.id);

            // Show toast notification
            toast.custom(
                (t) => (
                    <div
                        className={`${t.visible ? 'animate-bounce-subtle' : 'opacity-0'
                            } bg-danger text-white px-6 py-4 rounded-lg shadow-2xl pulse-glow cursor-pointer`}
                        onClick={() => {
                            setSelectedEvent(event);
                            toast.dismiss(t.id);
                        }}
                    >
                        <div className="flex items-center">
                            <div className="mr-3">
                                <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path
                                        strokeLinecap="round"
                                        strokeLinejoin="round"
                                        strokeWidth={2}
                                        d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
                                    />
                                </svg>
                            </div>
                            <div>
                                <p className="font-bold">NEW SOS ALERT!</p>
                                <p className="text-sm">{event.user?.name || 'Unknown User'}</p>
                                <p className="text-xs opacity-90">{event.message || 'Emergency'}</p>
                            </div>
                        </div>
                    </div>
                ),
                { duration: 10000 }
            );

            // Clear new event highlight after animation
            setTimeout(() => setNewEventId(null), 3000);
        });

        // Handle SOS updates
        onSosUpdate((event: SosEvent) => {
            console.log('SOS event updated:', event);
            setEvents((prev) => prev.map((e) => (e.id === event.id ? event : e)));

            // Update selected event if it's the one being updated
            if (selectedEvent?.id === event.id) {
                setSelectedEvent(event);
            }

            toast.success(`Event ${event.status}`);
        });

        return () => {
            disconnectSocket();
        };
    }, [selectedEvent]);

    const handleEventClick = useCallback((event: SosEvent) => {
        setSelectedEvent(event);
    }, []);

    const handleEventUpdate = useCallback((updatedEvent: SosEvent) => {
        setEvents((prev) => prev.map((e) => (e.id === updatedEvent.id ? updatedEvent : e)));
        setSelectedEvent(updatedEvent);
    }, []);

    const handleCloseDetail = useCallback(() => {
        setSelectedEvent(null);
    }, []);

    if (loading) {
        return (
            <div className="h-screen flex items-center justify-center bg-navy-dark">
                <div className="text-white text-xl">Loading...</div>
            </div>
        );
    }

    return (
        <div className="h-screen flex flex-col bg-navy-dark">
            <Toaster position="top-right" />

            {/* Header */}
            <Header onMenuClick={() => setSidebarOpen(!sidebarOpen)} />

            {/* Main content */}
            <div className="flex-1 flex overflow-hidden">
                {/* Sidebar */}
                <Sidebar isOpen={sidebarOpen} onClose={() => setSidebarOpen(false)} />

                {/* Dashboard content */}
                <main className="flex-1 overflow-y-auto">
                    {/* Emergency SOS Banner */}
                    <div className="bg-danger text-white px-6 py-3 flex items-center justify-between">
                        <div className="flex items-center">
                            <span className="text-2xl font-bold mr-3">EMERGENCY SOS</span>
                            <span className="text-sm opacity-90">
                                {events.filter((e) => e.status === 'pending').length} pending alerts
                            </span>
                        </div>
                    </div>

                    {/* Main grid layout */}
                    <div className="min-h-[calc(100vh-140px)] p-4 grid grid-cols-12 gap-4">
                        {/* Left column: Map and list */}
                        <div className="col-span-12 lg:col-span-7 xl:col-span-8 flex flex-col gap-4">
                            {/* Map */}
                            <div className="h-[60%] relative">
                                <MapView
                                    events={events}
                                    selectedEvent={selectedEvent}
                                    onEventClick={handleEventClick}
                                    newEventId={newEventId}
                                />
                            </div>

                            {/* User info and emergency contacts */}
                            <div className="h-[40%] grid grid-cols-2 gap-4">
                                <UserInfoCard event={selectedEvent} />
                                <EmergencyContacts event={selectedEvent} />
                            </div>
                        </div>

                        {/* Right column: Details and resources */}
                        <div className="col-span-12 lg:col-span-5 xl:col-span-4 flex flex-col gap-4 h-full">
                            {/* Event detail or list */}
                            <div className="h-[50%] bg-navy-light rounded-lg overflow-hidden">
                                {selectedEvent ? (
                                    <EventDetailPanel
                                        event={selectedEvent}
                                        onClose={handleCloseDetail}
                                        onUpdate={handleEventUpdate}
                                    />
                                ) : (
                                    <SosList
                                        events={events}
                                        onEventClick={handleEventClick}
                                        selectedEventId={selectedEvent?.id}
                                    />
                                )}
                            </div>

                            {/* Resources and communication log */}
                            <div className="h-[25%]">
                                <NearbyResources event={selectedEvent} />
                            </div>

                            <div className="h-[25%]">
                                <CommunicationLog />
                            </div>
                        </div>
                    </div>
                </main>
            </div>
        </div>
    );
};

export default Dashboard;
