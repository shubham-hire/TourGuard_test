import React from "react";
import { useNavigate } from "react-router-dom";

const Header: React.FC = () => {
  const navigate = useNavigate();
  const user = (() => {
    try {
      return JSON.parse(localStorage.getItem("user") || "{}");
    } catch {
      return {};
    }
  })();

  const handleLogout = () => {
    localStorage.removeItem("token");
    localStorage.removeItem("user");
    navigate("/login");
  };

  return (
    <header className="bg-navy-dark border-b border-gray-700 h-16 px-6 flex items-center justify-between">
      <div className="flex items-center space-x-4">
        <h1 className="text-xl font-bold text-white tracking-wide">
          TOUR<span className="text-danger">GUARD</span>{" "}
          <span className="text-gray-400 font-normal text-sm ml-2">
            ADMIN CONSOLE
          </span>
        </h1>
      </div>

      <div className="flex items-center space-x-4">
        <div className="text-right hidden md:block">
          <p className="text-white text-sm font-medium">
            {user.name || "Admin User"}
          </p>
          <p className="text-gray-400 text-xs">{user.email}</p>
        </div>
        <button
          onClick={handleLogout}
          className="px-4 py-2 bg-navy hover:bg-navy-light text-gray-300 hover:text-white rounded transition-colors text-sm"
        >
          Logout
        </button>
      </div>
    </header>
  );
};

export default Header;
