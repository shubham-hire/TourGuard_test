import React, { useState, useEffect } from "react";
import { io } from "socket.io-client";
import toast, { Toaster } from "react-hot-toast";
import Header from "../Layout/Header";
import Sidebar from "../Layout/Sidebar";
import SosList from "./SosList";
import MapView from "./MapView";
import EventDetailPanel from "./EventDetailPanel";
import { sosApi } from "../../services/api";
import { SosEvent } from "../../types";

// Initialize socket connection
const SOCKET_URL =
  import.meta.env.VITE_API_BASE_URL || "https://tourguard-test.onrender.com";
const socket = io(SOCKET_URL, {
  transports: ["websocket"],
  autoConnect: true,
});

const Dashboard: React.FC = () => {
  const [events, setEvents] = useState<SosEvent[]>([]);
  const [selectedEvent, setSelectedEvent] = useState<SosEvent | null>(null);
  const [loading, setLoading] = useState(true);
  const [newEventId, setNewEventId] = useState<string | null>(null);

  // Fetch initial events
  useEffect(() => {
    const fetchEvents = async () => {
      try {
        const response = await sosApi.listEvents();
        // Ensure response.data is an array if it exists, otherwise use response directly if it is an array
        const eventList = Array.isArray(response)
          ? response
          : (response as any).data || [];
        setEvents(eventList);
      } catch (error) {
        console.error("Failed to fetch events:", error);
        toast.error("Failed to load SOS events");
      } finally {
        setLoading(false);
      }
    };

    fetchEvents();
  }, []);

  // Socket.IO event listeners
  useEffect(() => {
    socket.on("connect", () => {
      console.log("Connected to socket server");
    });

    socket.on("new-sos", (event: SosEvent) => {
      console.log("New SOS event received:", event);

      // Add to list immediately
      setEvents((prev) => [event, ...prev]);

      // Flash notification/sound
      toast.custom(
        (t) => (
          <div
            className={`${
              t.visible ? "animate-enter" : "animate-leave"
            } max-w-md w-full bg-danger shadow-lg rounded-lg pointer-events-auto flex ring-1 ring-black ring-opacity-5`}
          >
            <div className="flex-1 w-0 p-4">
              <div className="flex items-start">
                <div className="flex-shrink-0 pt-0.5">
                  <span className="text-2xl">🚨</span>
                </div>
                <div className="ml-3 flex-1">
                  <p className="text-sm font-medium text-white">
                    CRITICAL ALERT: New SOS!
                  </p>
                  <p className="mt-1 text-sm text-white opacity-90">
                    {event.user?.name || "Unknown User"} needs help!
                  </p>
                </div>
              </div>
            </div>
            <div className="flex border-l border-white border-opacity-20">
              <button
                onClick={() => {
                  toast.dismiss(t.id);
                  setSelectedEvent(event);
                }}
                className="w-full border border-transparent rounded-none rounded-r-lg p-4 flex items-center justify-center text-sm font-medium text-white hover:bg-red-700 focus:outline-none"
              >
                View
              </button>
            </div>
          </div>
        ),
        { duration: 10000 }
      );

      setNewEventId(event.id);
      setTimeout(() => setNewEventId(null), 5000);
    });

    socket.on("sos-status-updated", (updatedEvent: SosEvent) => {
      setEvents((prev) =>
        prev.map((e) => (e.id === updatedEvent.id ? updatedEvent : e))
      );

      if (selectedEvent?.id === updatedEvent.id) {
        setSelectedEvent(updatedEvent);
      }
    });

    return () => {
      socket.off("connect");
      socket.off("new-sos");
      socket.off("sos-status-updated");
    };
  }, [selectedEvent]);

  const handleEventSelect = (event: SosEvent) => {
    setSelectedEvent(event);
  };

  const handleEventUpdate = (updatedEvent: SosEvent) => {
    setEvents((prev) =>
      prev.map((e) => (e.id === updatedEvent.id ? updatedEvent : e))
    );
    setSelectedEvent(updatedEvent);
  };

  return (
    <div className="flex h-screen bg-navy-darker text-gray-100 font-sans">
      <Toaster position="top-right" />

      {/* Sidebar */}
      <div className="hidden md:block">
        <Sidebar />
      </div>

      {/* Main Content */}
      <div className="flex-1 flex flex-col min-w-0 overflow-hidden">
        <Header />

        <main className="flex-1 flex overflow-hidden">
          {/* Left Panel: Map & List */}
          <div
            className={`flex-1 flex flex-col min-w-0 ${
              selectedEvent ? "hidden lg:flex" : "flex"
            }`}
          >
            {/* Map Area */}
            <div className="h-1/2 p-4 pb-2">
              <div className="h-full bg-navy rounded-lg shadow-lg border border-gray-700 overflow-hidden relative">
                <MapView
                  events={events}
                  selectedEvent={selectedEvent}
                  onEventClick={handleEventSelect}
                  newEventId={newEventId}
                />
              </div>
            </div>

            {/* List Area */}
            <div className="h-1/2 p-4 pt-2">
              <div className="h-full bg-navy rounded-lg shadow-lg border border-gray-700 overflow-hidden">
                {loading ? (
                  <div className="flex items-center justify-center h-full">
                    <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-danger"></div>
                  </div>
                ) : (
                  <SosList
                    events={events}
                    onEventClick={handleEventSelect}
                    selectedEventId={selectedEvent?.id}
                  />
                )}
              </div>
            </div>
          </div>

          {/* Right Panel: Detail View */}
          {(selectedEvent || window.innerWidth >= 1024) && (
            <div
              className={`
                            ${
                              selectedEvent
                                ? "w-full lg:w-96 border-l border-gray-700"
                                : "hidden lg:block lg:w-0 lg:border-none"
                            }
                            bg-navy-light transition-all duration-300 ease-in-out
                        `}
            >
              {selectedEvent ? (
                <EventDetailPanel
                  event={selectedEvent}
                  onClose={() => setSelectedEvent(null)}
                  onUpdate={handleEventUpdate}
                />
              ) : (
                <div className="h-full flex flex-col items-center justify-center text-gray-500 p-8 text-center">
                  <div className="bg-navy p-4 rounded-full mb-4">
                    <span className="text-4xl">👈</span>
                  </div>
                  <h3 className="text-xl font-bold text-white mb-2">
                    Select an Event
                  </h3>
                  <p>
                    Click on a map marker or list item to view incident details.
                  </p>
                </div>
              )}
            </div>
          )}
        </main>
      </div>
    </div>
  );
};

export default Dashboard;
