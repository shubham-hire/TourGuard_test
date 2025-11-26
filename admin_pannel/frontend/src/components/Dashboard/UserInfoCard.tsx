/**
 * User information card component
 */

import React from 'react';
import { SosEvent } from '../../types';
import { format } from 'date-fns';

interface UserInfoCardProps {
    event: SosEvent | null;
}

const UserInfoCard: React.FC<UserInfoCardProps> = ({ event }) => {
    if (!event || !event.user) {
        return (
            <div className="card h-full flex items-center justify-center text-gray-400">
                Select an event to view user information
            </div>
        );
    }

    const { user } = event;

    return (
        <div className="card h-full">
            <h3 className="font-semibold text-white mb-4">USER INFORMATION</h3>

            <div className="flex items-center mb-4">
                <div className="w-16 h-16 rounded-full bg-gradient-to-br from-danger to-warning flex items-center justify-center text-white text-2xl font-bold mr-4">
                    {user.name.charAt(0)}
                </div>
                <div>
                    <h4 className="text-white font-bold">{user.name}</h4>
                    <p className="text-gray-400 text-sm">ID: {event.userId.slice(0, 8)}...</p>
                </div>
            </div>

            <div className="space-y-2 text-sm">
                <div className="flex justify-between">
                    <span className="text-gray-400">Registered Since:</span>
                    <span className="text-white">2023-01-15</span>
                </div>
                <div className="mt-3">
                    <span className="text-gray-400">Medical Conditions:</span>
                    <p className="text-white mt-1">{user.medicalConditions || 'None reported'}</p>
                </div>
                <div className="mt-3">
                    <span className="text-gray-400">Allergies:</span>
                    <p className="text-white mt-1">{user.allergies || 'None reported'}</p>
                </div>
            </div>
        </div>
    );
};

export default UserInfoCard;
