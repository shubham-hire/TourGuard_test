# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project overview

This repo contains the TourGuard tourist safety application:
- **Flutter mobile app** in the repo root (`lib/`, `android/`, `ios/`, `web/`, etc.), providing geofenced safety guidance, maps, SOS, alerts, and chat.
- **Node.js/Express backend** in `backend/`, exposing REST APIs under `/api/*` backed by PostgreSQL + PostGIS, Redis caching, and real-time features.

The Flutter app talks to the backend via HTTP (and Socket.io for real-time) using services in `lib/services/` and the configuration in `lib/core/config/app_config.dart` and `lib/services/api_environment.dart`.

## Common commands

Run all commands from the repo root (`TourGuard_AppInterface`), unless noted.

### Flutter app

Dependency install:
- `flutter pub get`

Run the app (pick a device/emulator as usual):
- `flutter run`

Static analysis / linting (uses `analysis_options.yaml`):
- `flutter analyze`

Run all Flutter tests:
- `flutter test`

Run a single Flutter test file (examples based on existing tests):
- `flutter test test/geofence_helper_test.dart`
- `flutter test test/places_api_integration_test.dart`

### Backend service (`backend/`)

Install dependencies:
- `cd backend && npm install`

Environment setup (see `backend/SETUP_GUIDE.md` for full details):
- Copy env template: `cd backend && cp .env.example .env`
- Edit `.env` with PostgreSQL, Redis, JWT, Twilio, and Google Places values.

Database setup (PostgreSQL + PostGIS):
- Create DB (from your shell, user may differ):
  - `createdb tourguard`
- Enable PostGIS in the `tourguard` database and apply schema:
  - `psql -U postgres -d tourguard -f migrations/001_initial_schema.sql`

Run the backend server:
- Development (nodemon):
  - `cd backend && npm run dev`
- Production-style run:
  - `cd backend && npm start`

Basic health check for the backend:
- `curl http://localhost:3000/health`

#### Backend testing & security

The backend includes Jest config and tests under `backend/tests/` and a testing guide in `backend/TESTING_GUIDE.md`:
- Run all tests (once scripts are wired up in `backend/package.json`):
  - `cd backend && npm test`
- Run specific suites (as described in `TESTING_GUIDE.md`):
  - `cd backend && npm run test:api`
  - `cd backend && npm run test:integration`
- Run security checks:
  - `cd backend && npm run test:security`
  - `cd backend && node scripts/security-audit.js`
  - `cd backend && npm audit`

If these scripts are missing from `backend/package.json`, add them to point at Jest and the security scripts before running.

## High-level architecture

### Flutter app architecture

**Entry point & navigation**
- `lib/main.dart` is the entry point. It:
  - Initializes shared services before `runApp` (notifications, HTTP cache, chat, incident store, localization).
  - Wraps the app in a `MultiProvider` and a `ValueListenableBuilder` that listens to `LocalizationService.languageNotifier` to rebuild the UI on language changes.
  - Configures routes for the auth flow (`SplashScreen`, `LoginScreen`, `RegistrationScreen`, `OtpScreen`, `SuccessScreen`) and the main shell `MainNavigationScreen`.
- `MainNavigationScreen` defines the bottom navigation with five tabs:
  - `DashboardScreen`, `ProfileScreen`, `ExploreScreen`, `EmergencyScreen`, and `SettingsScreen`.

**Layered structure**
There are two overlapping structures:
- A more "clean" split under `lib/core`, `lib/data`, and `lib/presentation`:
  - `core/` – cross-cutting concerns (config, theming, validation helpers).
  - `data/` – data models and low-level services (e.g. `data/models/user_model.dart`, `data/services/auth_service.dart`).
  - `presentation/` – auth-related pages (`presentation/pages/*.dart`), widgets, and the `AuthProvider` in `presentation/providers/auth_provider.dart`.
- A feature/service-oriented split under `lib/screens`, `lib/services`, `lib/utils`, and `lib/widgets` powering the main in-app experience:
  - `screens/` – main feature screens (dashboard, emergency, explore, profile, incidents, settings, etc.).
  - `services/` – pure-Dart services for networking, location, geofencing, safety scoring, chat, notifications, weather, blockchain, translation, etc.
  - `utils/` – constants, geofence helpers, localization helpers.
  - `widgets/` – reusable UI components (alerts, bottom nav, etc.).

New work should generally plug into the existing services/utilities instead of duplicating HTTP or platform logic in screens.

**Configuration & networking**
- `lib/core/config/app_config.dart` centralizes API base URLs and endpoint helpers:
  - Resolves `baseUrl` from a compile-time `API_BASE_URL` override when provided.
  - Falls back to platform-aware defaults for Android emulators vs. iOS/desktop/web.
  - Exposes per-feature endpoint builders (`authUrl`, `zonesUrl`, `alertsUrl`, `safetyScoreUrl`, etc.) and a generic `getApiUrl` helper.
- `lib/services/api_environment.dart` resolves the `/api/places` base URL with a `PLACES_API_BASE_URL` dart-define override and platform-specific defaults, and also exposes a Google Places API key (overrideable via dart-define). Avoid inlining new keys; respect this mechanism.
- `lib/services/api_service.dart` is the main HTTP client for the mobile app:
  - Derives its backend base URL from `ApiEnvironment.placesBaseUrl` by stripping `/api/places`.
  - Uses `package:http` and a small Hive-backed cache box (`apiCache`) to implement a cache-aside pattern for GETs.
  - Provides higher-level methods for app features: `getNearbyZones`, `getAlerts`, `getSafetyScore`, `getUserProfile`, `getPlaces`, `reportIncident`, and `sendSOS`.
  - `sendSOS` hits `/api/sos/send` with a short timeout to keep the UI responsive.

When adding new backend endpoints, prefer adding a method to `ApiService` (and/or using `AppConfig.getApiUrl`) rather than constructing URLs ad hoc in widgets.

**Location, geofencing, safety, and alerts**
- `lib/screens/dashboard_screen.dart` is the main safety dashboard. It:
  - Subscribes to `Geolocator.getPositionStream` with throttling, tracks the current position, and periodically refreshes:
    - A live safety score via `SafetyScoreService.getLiveSafetyScore`.
    - Weather data via `WeatherService` (OpenWeather or PirateWeather fallback).
    - High-level "active alerts" via `ActiveAlertService.generateAlerts`.
  - Renders a `GoogleMap` with:
    - The user’s current location.
    - Incident markers sourced from locally stored incidents via `IncidentService`.
    - Safety geofence circles assembled via `GeofenceHelper.buildFixedCircles()` and `AppConstants.geofenceZones`.
  - Logs geofence "enter"/"exit" events to a dedicated Hive box (`geofence_events`) and surfaces them in the UI via `GeofenceEventsScreen`.
  - Uses `NotificationService.showAlertNotification` and an in-app dialog to notify the user when they enter/exit zones.
- `lib/services/geofence_service.dart` provides a separate, service-style implementation for geofencing and anomaly detection:
  - Maintains a static list of restricted zones with coordinates, radii, and risk levels.
  - Computes distances via a custom Haversine implementation.
  - Detects anomalies (sudden speed spikes or large jumps in recent locations) and exposes a listener API (`onAlert`) that other components can subscribe to.
- Weather and safety-score services (e.g. `SafetyScoreService`, `WeatherService`, `ActiveAlertService`) live under `lib/services/` and are orchestrated primarily by the dashboard.

**Notifications & platform integration**
- `lib/services/notification_service.dart` wraps a `MethodChannel('tourapp/notifications')` and exposes `showAlertNotification` / `showEmergencyNotification` for native notifications.
- The dashboard and geofencing code use this service in addition to in-app alerts.

**SOS and emergency flows**
- `lib/screens/emergency_screen.dart` provides the SOS UI and quick emergency actions:
  - Uses `AuthProvider.emergencyContacts` to build the target contact list.
  - On SOS press, immediately opens the SMS app with a prefilled message including a Google Maps URL when a location is available (using `LocationService` and `Geolocator` with timeouts and fallbacks).
  - In the background, sends an SOS payload to the backend via `ApiService.sendSOS` (non-blocking and tolerant of failures) and logs an `alerts` document in Firestore.
  - Exposes quick-call tiles (police, fire, ambulance, tourist helpline) and actions for reporting incidents and sharing location.
- `lib/services/emergency_service.dart` provides a more generic emergency helper (emergency numbers list, siren sound playback via `audioplayers`, basic SMS sharing logic). The UI layer mixes direct use of `url_launcher` with these utilities.

**State, persistence, and localization**
- State management:
  - Authentication and user/emergency-contact state is owned by `AuthProvider` (Provider/ChangeNotifier), used across dashboard and emergency features.
  - Dashboard state is local to `DashboardScreen`, with timers and listeners carefully cancelled in `dispose`.
- Persistence:
  - Hive is used for lightweight local storage: API cache (`apiCache`), geofence events, incident history, etc.
- Localization:
  - `LocalizationService` exposes a `languageNotifier` used at the top of the tree and throughout key screens to drive translated text via `tr('key')`.
  - When changing or adding features, prefer using this localization layer instead of hard-coded strings (the dashboard and emergency screens demonstrate the pattern).

### Backend architecture (`backend/`)

The backend is a Node.js/Express API server designed around PostgreSQL + PostGIS and Redis. Key concepts are documented in `backend/BACKEND_ARCHITECTURE.md`, `BACKEND_SUMMARY.md`, `README.md`, and `SETUP_GUIDE.md`.

**Directory structure (conceptual)**
- `config/` – low-level infrastructure configuration:
  - `database.js` for PostgreSQL connection pooling.
  - `redis.js` for Redis client and cache helpers.
  - `env.js` for environment validation (as described in the architecture doc).
- `models/` – domain models (`User`, `Incident`, `Zone`, `Alert`, `SOSAlert`, etc.) encapsulating DB access (see `BACKEND_ARCHITECTURE.md`).
- `controllers/` – HTTP controllers for each feature area:
  - `authController`, `incidentController`, `zoneController`, `alertController`, `sosController`, `profileController`, `safetyScoreController`, `placesController`.
- `services/` – business logic and integration with external systems (Twilio, cache, safety-score algorithms, etc.):
  - `authService`, `incidentService`, `sosService`, `zoneService`, `alertService`, `profileService`, `safetyScoreService`, `placesService`, `cacheService`.
- `routes/` – Express routers grouped by feature, all mounted under `/api` in `server.js`.
- `middleware/` – cross-cutting request handling:
  - `auth.js` (JWT verification), `validation.js` (Joi-based validation), `errorHandler.js` (centralized error handling), `rateLimiter.js` (per-IP rate limiting).
- `utils/` – logging and shared constants (`logger.js`, `constants.js`, helpers).
- `migrations/` – SQL migrations, notably `001_initial_schema.sql` defining users, incidents, safety_zones, alerts, sos_alerts with spatial indexes.
- `tests/` – Jest tests for API, integration, and security; configured by `jest.config.js`.

**Core flows**
- **Authentication**
  - OTP-based login with Twilio: `POST /api/auth/send-otp` and `POST /api/auth/verify-otp` issue and verify SMS OTPs and produce JWTs.
  - JWTs are required for protected endpoints (profile, incidents, SOS, alerts, etc.) via `Authorization: Bearer <token>` and enforced by `middleware/auth.js`.
- **Safety data & location**
  - Incidents, safety zones, alerts, and SOS alerts use PostGIS geography columns and GIST indexes for efficient spatial queries (`ST_DWithin`, etc.).
  - Endpoints like `/api/incidents/nearby`, `/api/zones`, `/api/safety-score`, and `/api/alerts/nearby` take `lat`, `lng`, and `radius` parameters to power the mobile app’s dashboard and map.
- **Caching**
  - Redis is used as a cache layer for expensive or frequently accessed queries:
    - Keys follow patterns like `zones:{lat}:{lng}:{radius}`, `incidents:{lat}:{lng}:{radius}`, `safety_score:{lat}:{lng}`, `user:{userId}`, etc.
  - Services are responsible for cache invalidation when underlying data changes (e.g., new incidents or profile updates).
- **Real-time features**
  - `server.js` also configures Socket.io for real-time updates.
  - Rooms (e.g. `user:{userId}`, `zone:{zoneId}`, `admin`) and events (`location:update`, `sos:alert`, `incident:new`, `alert:new`, `chat:message`) are defined in `BACKEND_ARCHITECTURE.md` and surfaced to clients using `socket_io_client` on the Flutter side.

**Environment and deployment**
- Required environment variables (see `.env.example` and `SETUP_GUIDE.md`) include:
  - Server: `NODE_ENV`, `PORT`.
  - Database: `DATABASE_URL` and individual `DB_*` fields.
  - Redis: `REDIS_URL`.
  - JWT: `JWT_SECRET`, `JWT_EXPIRES_IN`.
  - Twilio: `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, `TWILIO_SERVICE_SID`.
  - Google Places: `GOOGLE_PLACES_API_KEY`.
- The architecture docs reference Docker and docker-compose for local development; consult them if you need containerized workflows.

### Frontend–backend integration

- Base URL selection:
  - At build time, `PLACES_API_BASE_URL` and/or `API_BASE_URL` dart-defines can override the default `http://localhost:3000` / `http://10.0.2.2:3000` behavior.
  - For real devices, you must point these to the machine or gateway where the backend is reachable.
- Endpoint mapping:
  - `ApiService` methods in Flutter directly correlate with Express routes documented in `BACKEND_ARCHITECTURE.md` and `backend/README.md`:
    - `/auth` ↔ auth controller/routes.
    - `/incidents` ↔ incident reporting and nearby incidents.
    - `/sos` ↔ SOS handling.
    - `/zones` ↔ safety zones.
    - `/alerts` ↔ active and nearby alerts.
    - `/safety-score` ↔ aggregated safety scoring logic.
    - `/places` ↔ nearby places (backend or direct Google Places, depending on configuration).
- Safety and SOS in the app depend on:
  - Accurate geolocation and geofencing in the Flutter layer.
  - Correct backend base URLs and healthy `/health`, `/api/safety-score`, `/api/zones`, and `/api/sos/send` endpoints.

When implementing new features, keep the separation of concerns consistent:
- Add or extend backend controllers/services/routes first, then expose them via `ApiService`/`AppConfig`/`ApiEnvironment`, and finally integrate them into screens or providers.
