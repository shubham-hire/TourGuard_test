/**
 * Top navigation header
 */

import React from 'react';

interface HeaderProps {
    onMenuClick: () => void;
}

const Header: React.FC<HeaderProps> = ({ onMenuClick }) => {
    const handleLogout = () => {
        localStorage.removeItem('token');
        localStorage.removeItem('user');
        window.location.href = '/login';
    };

    return (
        <header className="bg-navy-dark border-b border-gray-700 px-6 py-4 flex items-center justify-between">
            <div className="flex items-center">
                <button
                    onClick={onMenuClick}
                    className="mr-4 text-gray-300 hover:text-white lg:hidden"
                >
                    <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path
                            strokeLinecap="round"
                            strokeLinejoin="round"
                            strokeWidth={2}
                            d="M4 6h16M4 12h16M4 18h16"
                        />
                    </svg>
                </button>

                <div className="flex items-center">
                    <div className="bg-danger p-2 rounded mr-3">
                        <svg className="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path
                                strokeLinecap="round"
                                strokeLinejoin="round"
                                strokeWidth={2}
                                d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
                            />
                        </svg>
                    </div>
                    <h1 className="text-xl font-bold text-white">COMMUNITY SAFETY PLATFORM</h1>
                </div>
            </div>

            <button
                onClick={handleLogout}
                className="px-4 py-2 text-sm text-gray-300 hover:text-white hover:bg-navy-light rounded"
            >
                Logout
            </button>
        </header>
    );
};

export default Header;
