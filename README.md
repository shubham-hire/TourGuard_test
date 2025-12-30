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

## 🧠 AI & LLM Powering TourGuard

TourGuard leverages **Generative AI** and **Large Language Models (LLMs)** to transform raw data into actionable safety intelligence. By integrating models like **Microsoft Phi-3 Mini** (for offline, local privacy) and **Google Gemini** (for cloud-based reasoning), the system acts as a proactive safety companion.

### How It Works

1.  **Input**: The system collects user location, danger zones, historical safety data, and user queries.
2.  **Processing**: The Python-based `ml-engine` processes this context using **Ollama** or **Gemini APIs**.
3.  **Output**: You get human-readable advice, risk assessments, and emergency summaries.

### Key AI Features for Tourists

- **💬 Smart Travel Assistant**: A context-aware chatbot that knows your location and safety levels. Ask _"Is it safe to walk here at night?"_ and get an answer backed by real-time risk data, not just generic travel tips.
- **🛡️ Automated Risk Advisories**: Instead of just showing a "Red Zone" on a map, the AI explains _why_ an area is risky (e.g., "High theft reported after 10 PM") and suggests specific precautions.
- **🗺️ Intelligent Itinerary Planning**: designing a trip? The AI creates day-by-day itineraries that prioritize safe routes and daylight travel, balancing fun with security.
- **🚨 Emergency Intelligence**: In a distress situation, the AI analyzes sensor data (speed, battery, movement) to generate a concise **Investigation Report** for first responders, highlighting critical anomalies instantly.

### Technical Implementation

The system utilizes a hybrid AI approach:

- **Local Inference**: Uses **Ollama** to run lightweight models (Phi-3) directly on the edge, ensuring privacy and functionality without internet.
- **Cloud Fallback**: Switches to **Google Gemini 1.5** for complex reasoning tasks when connectivity is available.

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
