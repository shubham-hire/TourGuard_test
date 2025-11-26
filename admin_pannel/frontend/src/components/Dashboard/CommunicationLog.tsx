/**
 * Communication log component
 */

import React from 'react';

const CommunicationLog: React.FC = () => {
    const logs = [
        {
            time: '[18:38:29]',
            message: 'SOS activated by Jane D.',
            details: 'Anomaly Detection: Location Deviation Dispatcher Alec: Contacting Police.',
        },
    ];

    return (
        <div className="card h-full">
            <h3 className="font-semibold text-white mb-4">COMMUNICATION LOG</h3>
            <div className="space-y-2">
                {logs.map((log, idx) => (
                    <div key={idx} className="p-3 bg-navy rounded text-sm">
                        <p className="text-danger font-mono">{log.time}</p>
                        <p className="text-white mt-1">{log.message}</p>
                        <p className="text-gray-400 text-xs mt-1">{log.details}</p>
                    </div>
                ))}
            </div>
        </div>
    );
};

export default CommunicationLog;
