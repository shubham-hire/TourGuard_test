/**
 * SOS events list/table component
 */

import React, { useState } from 'react';
import { SosEvent } from '../../types';
import { formatDistanceToNow } from 'date-fns';

interface SosListProps {
    events: SosEvent[];
    onEventClick: (event: SosEvent) => void;
    selectedEventId?: string | null;
}

const SosList: React.FC<SosListProps> = ({ events, onEventClick, selectedEventId }) => {
    const [filter, setFilter] = useState<string>('all');
    const [search, setSearch] = useState('');

    const filteredEvents = events.filter((event) => {
        const matchesFilter = filter === 'all' || event.status === filter;
        const matchesSearch =
            search === '' ||
            event.user?.name.toLowerCase().includes(search.toLowerCase()) ||
            event.message?.toLowerCase().includes(search.toLowerCase());
        return matchesFilter && matchesSearch;
    });

    const getStatusBadge = (status: string) => {
        switch (status) {
            case 'pending':
                return <span className="badge-pending">PENDING</span>;
            case 'acknowledged':
                return <span className="badge-acknowledged">ACKNOWLEDGED</span>;
            case 'resolved':
                return <span className="badge-resolved">RESOLVED</span>;
            default:
                return null;
        }
    };

    return (
        <div className="flex flex-col h-full">
            {/* Search and filter */}
            <div className="p-4 bg-navy-light border-b border-gray-700">
                <input
                    type="text"
                    placeholder="Search by name or message..."
                    value={search}
                    onChange={(e) => setSearch(e.target.value)}
                    className="w-full px-4 py-2 bg-navy border border-gray-600 rounded-lg text-white mb-3 focus:outline-none focus:border-danger"
                />

                <div className="flex space-x-2">
                    <button
                        onClick={() => setFilter('all')}
                        className={`px-3 py-1 rounded text-sm ${filter === 'all' ? 'bg-danger text-white' : 'bg-navy text-gray-300'
                            }`}
                    >
                        All
                    </button>
                    <button
                        onClick={() => setFilter('pending')}
                        className={`px-3 py-1 rounded text-sm ${filter === 'pending' ? 'bg-danger text-white' : 'bg-navy text-gray-300'
                            }`}
                    >
                        Pending
                    </button>
                    <button
                        onClick={() => setFilter('acknowledged')}
                        className={`px-3 py-1 rounded text-sm ${filter === 'acknowledged' ? 'bg-warning text-white' : 'bg-navy text-gray-300'
                            }`}
                    >
                        Acknowledged
                    </button>
                    <button
                        onClick={() => setFilter('resolved')}
                        className={`px-3 py-1 rounded text-sm ${filter === 'resolved' ? 'bg-success text-white' : 'bg-navy text-gray-300'
                            }`}
                    >
                        Resolved
                    </button>
                </div>
            </div>

            {/* Events list */}
            <div className="flex-1 overflow-y-auto">
                {filteredEvents.length === 0 ? (
                    <div className="p-8 text-center text-gray-400">No SOS events found</div>
                ) : (
                    <div className="divide-y divide-gray-700">
                        {filteredEvents.map((event) => (
                            <div
                                key={event.id}
                                onClick={() => onEventClick(event)}
                                className={`p-4 cursor-pointer hover:bg-navy transition-colors ${selectedEventId === event.id ? 'bg-navy-dark border-l-4 border-danger' : ''
                                    } ${event.status === 'resolved' ? 'opacity-60' : ''}`}
                            >
                                <div className="flex items-start justify-between mb-2">
                                    <div>
                                        <h4 className="font-semibold text-white">{event.user?.name || 'Unknown'}</h4>
                                        <p className="text-xs text-gray-400">
                                            {formatDistanceToNow(new Date(event.createdAt), { addSuffix: true })}
                                        </p>
                                    </div>
                                    {getStatusBadge(event.status)}
                                </div>
                                <p className="text-sm text-gray-300 truncate">{event.message || 'No message'}</p>
                                <p className="text-xs text-gray-500 mt-1">
                                    {event.latitude.toFixed(6)}, {event.longitude.toFixed(6)}
                                </p>
                            </div>
                        ))}
                    </div>
                )}
            </div>
        </div>
    );
};

export default SosList;
