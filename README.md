# TourGuard - Intelligent Tourist Safety Ecosystem

TourGuard is a comprehensive safety monitoring and assistance platform designed to protect tourists through real-time tracking, AI-powered risk assessment, and secure identity management.

## 🏗 System Architecture

The project is structured as a monorepo containing multiple specialized components:

| Component        | Directory                       | Description                                | Stack                               |
| ---------------- | ------------------------------- | ------------------------------------------ | ----------------------------------- |
| **Mobile App**   | Root (`/lib`, `/android`, etc.) | User-facing application for tourists       | Flutter                             |
| **Main Backend** | `tourguard-backend Final`       | Core API, Auth, and Data Management        | NestJS, TypeORM, SQLite             |
| **Admin Panel**  | `admin_pannel`                  | Dashboard for authorities/admins           | React (Frontend), Node.js (Backend) |
| **ML Engine**    | `ml-engine`                     | AI service for anomaly detection & routing | Python, FastAPI                     |
| **Blockchain**   | `blockchain` / `ml-engine`      | Identity & secure logging                  | Web3, Solidity                      |

---

## 🚀 Getting Started

### 1. Main Backend (NestJS)

The core server that handles user data and app communication.

```bash
cd "tourguard-backend Final"
npm install
npm run start:dev
```

_Runs on `http://localhost:3000` (default)._

### 2. Machine Learning Engine (Python)

Handles safety scoring, route deviation detection, and geofencing.

```bash
cd ml-engine
python -m venv .venv
# Activate venv: source .venv/bin/activate (Mac/Linux) or .venv\Scripts\Activate (Windows)
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8082
```

_Runs on `http://localhost:8082`._

### 3. Admin Panel

A web dashboard for monitoring users and SOS alerts.

**Backend:**

```bash
cd admin_pannel/backend
npm install
npm run dev
```

**Frontend:**

```bash
cd admin_pannel/frontend
npm install
npm run dev
```

### 4. Mobile Application

The Flutter app for iOS and Android.

```bash
# From the root directory (TourGuard_AppInterface)
flutter pub get
flutter run
```

---

## ✨ Key Features

- **📍 Real-time Geofencing**: Monitors tourist location deviates from safe/planned zones.
- **🚨 SOS & Emergency**: Instant alerts to family and authorities with live location.
- **🧠 AI Risk Analysis**: ML models (`ml-engine`) analyze historical crime data to score route safety.
- **🛡️ Blockchain Identity**: Secure identity verification and immutable audit logs.
- **📶 Offline Support**: Critical features function even with poor connectivity.

## 📂 Project Structure

```
TourGuard_AppInterface/
├── lib/                     # Flutter App Source Code
├── tourguard-backend Final/ # Main NestJS Backend
├── admin_pannel/
│   ├── backend/             # Admin Backend (Node.js)
│   └── frontend/            # Admin Frontend (React+Vite)
├── ml-engine/               # Python AI/ML Service
├── blockchain/              # Blockchain contracts & scripts
└── ...
```

## ⚠️ Notes

- **Database**: The system uses SQLite (`database.sqlite`) for development ease. Ensure all backends are pointing to the correct database file.
- **Environment**: Check `.env.example` files in each directory to configure API keys (Google Maps, etc.) and port numbers.
