/**
 * Event detail panel
 * Shows full SOS event details with action buttons
 */

import React, { useState } from 'react';
import { SosEvent } from '../../types';
import { sosApi } from '../../services/api';
import toast from 'react-hot-toast';
import { format } from 'date-fns';

interface EventDetailPanelProps {
    event: SosEvent;
    onClose: () => void;
    onUpdate: (updatedEvent: SosEvent) => void;
}

const EventDetailPanel: React.FC<EventDetailPanelProps> = ({ event, onClose, onUpdate }) => {
    const [updating, setUpdating] = useState(false);

    const handleStatusUpdate = async (status: 'acknowledged' | 'resolved') => {
        setUpdating(true);
        try {
            const updatedEvent = await sosApi.updateStatus(event.id, status);
            onUpdate(updatedEvent);
            toast.success(`Event ${status}`);
        } catch (error: any) {
            toast.error(error.response?.data?.error || 'Failed to update status');
        } finally {
            setUpdating(false);
        }
    };

    const handleNavigate = () => {
        const url = `https://www.google.com/maps?q=${event.latitude},${event.longitude}`;
        window.open(url, '_blank');
    };

    return (
        <div className="bg-navy-light h-full overflow-y-auto">
            {/* Header */}
            <div className="p-4 border-b border-gray-700 flex items-center justify-between">
                <h2 className="text-lg font-bold text-white">Event Details</h2>
                <button onClick={onClose} className="text-gray-400 hover:text-white">
                    <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                    </svg>
                </button>
            </div>

            {/* Content */}
            <div className="p-4 space-y-4">
                {/* User Info */}
                <div className="card">
                    <h3 className="font-semibold text-white mb-3">User Information</h3>
                    <div className="space-y-2 text-sm">
                        <div>
                            <span className="text-gray-400">Name:</span>{' '}
                            <span className="text-white font-medium">{event.user?.name || 'Unknown'}</span>
                        </div>
                        <div>
                            <span className="text-gray-400">Phone:</span>{' '}
                            <span className="text-white">{event.user?.phone || 'N/A'}</span>
                        </div>
                        <div>
                            <span className="text-gray-400">Email:</span>{' '}
                            <span className="text-white">{event.user?.email || 'N/A'}</span>
                        </div>
                        {event.user?.medicalConditions && (
                            <div>
                                <span className="text-gray-400">Medical:</span>{' '}
                                <span className="text-danger font-medium">{event.user.medicalConditions}</span>
                            </div>
                        )}
                        {event.user?.allergies && (
                            <div>
                                <span className="text-gray-400">Allergies:</span>{' '}
                                <span className="text-warning font-medium">{event.user.allergies}</span>
                            </div>
                        )}
                    </div>
                </div>

                {/* Event Details */}
                <div className="card">
                    <h3 className="font-semibold text-white mb-3">Event Details</h3>
                    <div className="space-y-2 text-sm">
                        <div>
                            <span className="text-gray-400">Status:</span>{' '}
                            <span
                                className={
                                    event.status === 'pending'
                                        ? 'text-danger font-semibold'
                                        : event.status === 'acknowledged'
                                            ? 'text-warning font-semibold'
                                            : 'text-success font-semibold'
                                }
                            >
                                {event.status.toUpperCase()}
                            </span>
                        </div>
                        <div>
                            <span className="text-gray-400">Message:</span>{' '}
                            <p className="text-white mt-1">{event.message || 'No message provided'}</p>
                        </div>
                        <div>
                            <span className="text-gray-400">Time:</span>{' '}
                            <span className="text-white">
                                {format(new Date(event.createdAt), 'PPpp')}
                            </span>
                        </div>
                        {event.acknowledgedAt && (
                            <div>
                                <span className="text-gray-400">Acknowledged:</span>{' '}
                                <span className="text-white">
                                    {format(new Date(event.acknowledgedAt), 'PPpp')}
                                </span>
                            </div>
                        )}
                        {event.resolvedAt && (
                            <div>
                                <span className="text-gray-400">Resolved:</span>{' '}
                                <span className="text-white">
                                    {format(new Date(event.resolvedAt), 'PPpp')}
                                </span>
                            </div>
                        )}
                    </div>
                </div>

                {/* Location */}
                <div className="card">
                    <h3 className="font-semibold text-white mb-3">Location</h3>
                    <div className="space-y-2 text-sm">
                        <div>
                            <span className="text-gray-400">Coordinates:</span>{' '}
                            <span className="text-white font-mono">
                                {event.latitude.toFixed(6)}, {event.longitude.toFixed(6)}
                            </span>
                        </div>
                        {event.accuracyMeters !== undefined && (
                            <div>
                                <span className="text-gray-400">Accuracy:</span>{' '}
                                <span className="text-white">±{event.accuracyMeters} meters</span>
                            </div>
                        )}
                        <button
                            onClick={handleNavigate}
                            className="w-full mt-2 px-4 py-2 bg-info hover:bg-info-dark text-white rounded transition-colors flex items-center justify-center"
                        >
                            <svg className="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path
                                    strokeLinecap="round"
                                    strokeLinejoin="round"
                                    strokeWidth={2}
                                    d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"
                                />
                                <path
                                    strokeLinecap="round"
                                    strokeLinejoin="round"
                                    strokeWidth={2}
                                    d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"
                                />
                            </svg>
                            Navigate to Location
                        </button>
                    </div>
                </div>

                {/* Emergency Contacts */}
                {event.user?.emergencyContacts && event.user.emergencyContacts.length > 0 && (
                    <div className="card">
                        <h3 className="font-semibold text-white mb-3">Emergency Contacts</h3>
                        <div className="space-y-2">
                            {event.user.emergencyContacts.map((contact, idx) => (
                                <div key={idx} className="flex items-center justify-between text-sm">
                                    <div>
                                        <p className="text-white font-medium">{contact.name}</p>
                                        <p className="text-gray-400 text-xs">{contact.relation}</p>
                                    </div>
                                    <a
                                        href={`tel:${contact.phone}`}
                                        className="px-3 py-1 bg-success hover:bg-success-dark text-white text-xs rounded"
                                    >
                                        CALL
                                    </a>
                                </div>
                            ))}
                        </div>
                    </div>
                )}

                {/* Actions */}
                <div className="space-y-2">
                    {event.status === 'pending' && (
                        <button
                            onClick={() => handleStatusUpdate('acknowledged')}
                            disabled={updating}
                            className="w-full btn-success disabled:opacity-50"
                        >
                            {updating ? 'Updating...' : 'Acknowledge'}
                        </button>
                    )}
                    {event.status === 'acknowledged' && (
                        <button
                            onClick={() => handleStatusUpdate('resolved')}
                            disabled={updating}
                            className="w-full btn-success disabled:opacity-50"
                        >
                            {updating ? 'Updating...' : 'Mark as Resolved'}
                        </button>
                    )}
                </div>
            </div>
        </div>
    );
};

export default EventDetailPanel;
