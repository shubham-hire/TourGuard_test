# Admin Panel Backend

Secure Express + Socket.IO API that powers the TourGuard admin dashboard.
It mirrors SOS alerts from the core platform, exposes REST endpoints for the
React frontend, and emits real-time updates over an authenticated WebSocket
namespace.

## Getting Started

```bash
cd admin_pannel/backend
npm install
# create a .env file with the variables listed below
npm run dev             # or `npm run build && npm start`
```

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `JWT_SECRET` | ✅ | Secret used to sign/verify admin JWTs. Must match the token issued during login. |
| `DISABLE_ADMIN_AUTH` | ❌ | Set to `true` **only** for local UI demos where you want to bypass authentication. Defaults to `false`, meaning every request and socket connection must be authenticated. |

> The Socket.IO server runs under the `/admin` namespace and reuses the same
> `JWT_SECRET`. React clients must send the JWT in the handshake (`auth.token`)
> when connecting to `${VITE_SOCKET_URL}/admin`.

## Verification Checklist

1. Attempt to log in with an incorrect password → expect HTTP 401 and no JWT.
2. Log in with valid credentials → JWT returned and stored, dashboard loads.
3. Dashboard loads with no token → socket connection skipped and user stays on the login screen.
4. Corrupt the JWT in `localStorage` → Socket.IO emits `connect_error` and code redirects to `/login`.
5. Trigger a new SOS event via API → authenticated sockets receive `sos:new` in the dashboard.

