/**
 * Recent Incidents component - Shows regular reported incidents (not SOS)
 */

import React, { useState } from 'react';
import { Incident } from '../../types';
import { formatDistanceToNow } from 'date-fns';
import InvestigationReportViewer from '../InvestigationReportViewer';

interface RecentIncidentsProps {
    incidents: Incident[];
    onIncidentClick?: (incident: Incident) => void;
    selectedIncidentId?: string | null;
}

const RecentIncidents: React.FC<RecentIncidentsProps> = ({ 
    incidents, 
    onIncidentClick,
    selectedIncidentId 
}) => {
    const [analyzingIncident, setAnalyzingIncident] = useState<Incident | null>(null);

    const getSeverityBadge = (severity: string) => {
        switch (severity) {
            case 'CRITICAL':
                return <span className="badge-pending">CRITICAL</span>;
            case 'HIGH':
                return <span className="bg-red-600 text-white px-2 py-1 rounded text-xs font-semibold">HIGH</span>;
            case 'MEDIUM':
                return <span className="bg-yellow-600 text-white px-2 py-1 rounded text-xs font-semibold">MEDIUM</span>;
            case 'LOW':
                return <span className="bg-green-600 text-white px-2 py-1 rounded text-xs font-semibold">LOW</span>;
            default:
                return <span className="bg-gray-600 text-white px-2 py-1 rounded text-xs font-semibold">{severity}</span>;
        }
    };

    const getCategoryColor = (category: string) => {
        const cat = category.toLowerCase();
        if (cat.includes('theft') || cat.includes('assault')) return 'text-red-400';
        if (cat.includes('medical') || cat.includes('accident')) return 'text-yellow-400';
        return 'text-blue-400';
    };

    const handleAnalyzeClick = (e: React.MouseEvent, incident: Incident) => {
        e.stopPropagation();
        setAnalyzingIncident(incident);
    };

    return (
        <div className="flex flex-col h-full">
            <div className="p-4 bg-navy-light border-b border-gray-700">
                <h3 className="text-lg font-semibold text-white mb-1">Recent Incidents</h3>
                <p className="text-xs text-gray-400">{incidents.length} total incidents</p>
            </div>

            <div className="flex-1 overflow-y-auto">
                {incidents.length === 0 ? (
                    <div className="p-8 text-center text-gray-400">No incidents reported yet</div>
                ) : (
                    <div className="divide-y divide-gray-700">
                        {incidents.map((incident) => (
                            <div
                                key={incident.id}
                                onClick={() => onIncidentClick?.(incident)}
                                className={`p-4 cursor-pointer hover:bg-navy transition-colors ${
                                    selectedIncidentId === incident.id 
                                        ? 'bg-navy-dark border-l-4 border-blue-500' 
                                        : ''
                                }`}
                            >
                                <div className="flex items-start justify-between mb-2">
                                    <div className="flex-1">
                                        <h4 className="font-semibold text-white text-sm">
                                            {incident.title}
                                        </h4>
                                        <p className="text-xs text-gray-400 mt-1">
                                            {formatDistanceToNow(new Date(incident.createdAt), { addSuffix: true })}
                                        </p>
                                    </div>
                                    {getSeverityBadge(incident.severity)}
                                </div>
                                
                                <div className="flex items-center gap-2 mb-2">
                                    <span className={`text-xs font-medium ${getCategoryColor(incident.category)}`}>
                                        {incident.category}
                                    </span>
                                    {incident.user && (
                                        <span className="text-xs text-gray-500">
                                            • {incident.user.name}
                                        </span>
                                    )}
                                </div>

                                <p className="text-sm text-gray-300 line-clamp-2">
                                    {incident.description || 'No description'}
                                </p>

                                {incident.location && (
                                    <p className="text-xs text-gray-500 mt-2">
                                        📍 {incident.location.latitude.toFixed(4)}, {incident.location.longitude.toFixed(4)}
                                    </p>
                                )}

                                {/* AI Analysis Button */}
                                <button
                                    onClick={(e) => handleAnalyzeClick(e, incident)}
                                    className="mt-3 w-full flex items-center justify-center gap-2 px-3 py-2 bg-gradient-to-r from-purple-600 to-blue-600 hover:from-purple-700 hover:to-blue-700 text-white text-xs font-medium rounded-lg transition-all transform hover:scale-105"
                                >
                                    <span className="text-base">🤖</span>
                                    <span>Analyze with AI</span>
                                </button>

                            </div>
                        ))}
                    </div>
                )}
            </div>

            {/* AI Analysis Modal */}
            {analyzingIncident && (
                <div className="fixed inset-0 z-[9999] flex items-center justify-center bg-black/80 backdrop-blur-sm p-4">
                    <div className="bg-navy-dark rounded-xl shadow-2xl w-full max-w-4xl max-h-[90vh] overflow-hidden flex flex-col border border-gray-700">
                        <div className="flex items-center justify-between p-4 border-b border-gray-700 bg-navy-light/50">
                            <h3 className="text-xl font-bold text-white flex items-center gap-2">
                                🤖 AI Incident Analysis
                            </h3>
                            <button
                                onClick={() => setAnalyzingIncident(null)}
                                className="text-gray-400 hover:text-white transition-colors"
                            >
                                <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                                </svg>
                            </button>
                        </div>
                        <div className="flex-1 overflow-y-auto p-4">
                            <InvestigationReportViewer
                                touristId={analyzingIncident.user?.id || 'unknown'}
                                tripId={analyzingIncident.id}
                                incidentType={analyzingIncident.title.includes('SOS') ? 'SOS Event' : 'Incident Report'}
                            />
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
};

export default RecentIncidents;




