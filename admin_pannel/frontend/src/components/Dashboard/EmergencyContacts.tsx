/**
 * Emergency contacts component
 */

import React from 'react';
import { SosEvent } from '../../types';

interface EmergencyContactsProps {
    event: SosEvent | null;
}

const EmergencyContacts: React.FC<EmergencyContactsProps> = ({ event }) => {
    if (!event || !event.user?.emergencyContacts || event.user.emergencyContacts.length === 0) {
        return (
            <div className="card h-full flex items-center justify-center text-gray-400 text-sm">
                No emergency contacts available
            </div>
        );
    }

    const { emergencyContacts } = event.user;

    return (
        <div className="card h-full">
            <h3 className="font-semibold text-white mb-4">EMERGENCY CONTACTS</h3>
            <div className="space-y-3">
                {emergencyContacts.map((contact, idx) => (
                    <div key={idx} className="flex items-center justify-between p-3 bg-navy rounded">
                        <div>
                            <p className="text-white font-medium">{contact.name}</p>
                            <p className="text-gray-400 text-xs">{contact.relation} • {contact.phone}</p>
                        </div>
                        <a
                            href={`tel:${contact.phone}`}
                            className="btn-success text-xs px-3 py-1"
                        >
                            CALL NOW
                        </a>
                    </div>
                ))}
            </div>
        </div>
    );
};

export default EmergencyContacts;
