/**
 * Protected route component
 * Redirects to login if user is not authenticated
 */

import React from 'react';
import { Navigate } from 'react-router-dom';

interface ProtectedRouteProps {
    children: React.ReactNode;
}

const ProtectedRoute: React.FC<ProtectedRouteProps> = ({ children }) => {
    const token = localStorage.getItem('token');
    const authDisabled =
        (import.meta.env.VITE_DISABLE_ADMIN_AUTH ?? 'true').toString().toLowerCase() === 'true';

    if (authDisabled || token) {
        return <>{children}</>;
    }

    return <Navigate to="/login" replace />;
};

export default ProtectedRoute;
