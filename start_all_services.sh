#!/bin/bash

echo "🚀 Starting all TourGuard services in separate terminals..."
echo ""

# Kill existing services first
echo "Stopping existing services..."
pkill -f "ganache" 2>/dev/null
pkill -f "uvicorn.*ml-engine" 2>/dev/null
pkill -f "ts-node-dev.*admin_pannel/backend" 2>/dev/null  
pkill -f "vite.*admin_pannel/frontend" 2>/dev/null

sleep 2

# Start Ganache in new terminal
osascript <<EOF
tell application "Terminal"
    do script "cd /Users/shubham/alternnate/TourGuard_AppInterface && clear && echo '╔════════════════════════════════════════════╗' && echo '║   GANACHE - Blockchain Service             ║' && echo '╚════════════════════════════════════════════╝' && echo '' && npx ganache"
    set custom title of front window to "🔗 Ganache (Blockchain)"
end tell
EOF

sleep 2

# Start ML Engine in new terminal
osascript <<EOF
tell application "Terminal"
    do script "cd /Users/shubham/alternnate/TourGuard_AppInterface/ml-engine && clear && echo '╔════════════════════════════════════════════╗' && echo '║   ML ENGINE - AI/LLM Service               ║' && echo '╚════════════════════════════════════════════╝' && echo '' && source venv/bin/activate 2>/dev/null || true && uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload"
    set custom title of front window to "🤖 ML Engine (AI/LLM)"
end tell
EOF

sleep 2

# Start Admin Backend in new terminal
osascript <<EOF
tell application "Terminal"
    do script "cd /Users/shubham/alternnate/TourGuard_AppInterface/admin_pannel/backend && clear && echo '╔════════════════════════════════════════════╗' && echo '║   ADMIN BACKEND - API Server               ║' && echo '╚════════════════════════════════════════════╝' && echo '' && npm start"
    set custom title of front window to "🔧 Admin Backend (API)"
end tell
EOF

sleep 2

# Start Admin Frontend in new terminal
osascript <<EOF
tell application "Terminal"
    do script "cd /Users/shubham/alternnate/TourGuard_AppInterface/admin_pannel/frontend && clear && echo '╔════════════════════════════════════════════╗' && echo '║   ADMIN FRONTEND - React Dashboard         ║' && echo '╚════════════════════════════════════════════╝' && echo '' && npm run dev"
    set custom title of front window to "🎨 Admin Frontend (React)"
end tell
EOF

echo ""
echo "✅ All services starting in separate terminal windows!"
echo ""
echo "Services:"
echo "  1. 🔗 Ganache (Blockchain) - Port 8545"
echo "  2. 🤖 ML Engine (AI/LLM) - Port 8000"
echo "  3. 🔧 Admin Backend (API) - Port 5000"
echo "  4. 🎨 Admin Frontend (React) - Port 5173 or 3000"
echo ""
echo "Wait 30-60 seconds for all services to start, then run:"
echo "  ./check_services.sh"
echo ""
