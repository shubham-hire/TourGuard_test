import React from "react";
import { Link, useLocation } from "react-router-dom";
import {
  LayoutDashboard,
  Users,
  AlertTriangle,
  FileText,
  Settings,
  Shield,
} from "lucide-react";

const Sidebar: React.FC = () => {
  const location = useLocation();

  const isActive = (path: string) => {
    return location.pathname === path
      ? "bg-danger text-white"
      : "text-gray-400 hover:text-white hover:bg-navy";
  };

  const navItems = [
    { path: "/dashboard", icon: LayoutDashboard, label: "Dashboard" },
    { path: "/incidents", icon: AlertTriangle, label: "Incidents" },
    { path: "/users", icon: Users, label: "Users" },
    { path: "/reports", icon: FileText, label: "Reports" },
    { path: "/settings", icon: Settings, label: "Settings" },
  ];

  return (
    <aside className="w-64 bg-navy-dark border-r border-gray-700 h-full flex flex-col">
      <div className="p-6">
        <div className="flex items-center space-x-2 text-danger mb-6">
          <Shield size={32} />
          <span className="text-white font-bold text-lg">SOS CENTER</span>
        </div>
      </div>

      <nav className="flex-1 px-4 space-y-2">
        {navItems.map((item) => (
          <Link
            key={item.path}
            to={item.path}
            className={`flex items-center space-x-3 px-4 py-3 rounded-lg transition-colors ${isActive(
              item.path
            )}`}
          >
            <item.icon size={20} />
            <span className="font-medium">{item.label}</span>
          </Link>
        ))}
      </nav>

      <div className="p-4 border-t border-gray-700">
        <div className="bg-navy p-4 rounded-lg">
          <h4 className="text-white text-sm font-bold mb-1">System Status</h4>
          <div className="flex items-center space-x-2 mt-2">
            <span className="w-2 h-2 bg-success rounded-full animate-pulse"></span>
            <span className="text-gray-400 text-xs">
              All Systems Operational
            </span>
          </div>
        </div>
      </div>
    </aside>
  );
};

export default Sidebar;
