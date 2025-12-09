#!/bin/bash

echo "╔════════════════════════════════════════════════════════════╗"
echo "║       TourGuard System - Complete Health Check            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check service
check_service() {
    local name=$1
    local check_cmd=$2
    
    echo -n "  $name: "
    if eval "$check_cmd" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Running${NC}"
        return 0
    else
        echo -e "${RED}❌ Not Running${NC}"
        return 1
    fi
}

# Function to check HTTP endpoint
check_http() {
    local name=$1
    local url=$2
    
    echo -n "  $name: "
    response=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null)
    if [ "$response" = "200" ] || [ "$response" = "000" ]; then
        echo -e "${GREEN}✅ Responding ($url)${NC}"
        return 0
    else
        echo -e "${RED}❌ Not Responding ($url)${NC}"
        return 1
    fi
}

echo "🔍 Checking Services..."
echo ""

echo "1. Blockchain Layer"
check_service "Ganache" "ps aux | grep -v grep | grep ganache"
echo ""

echo "2. ML Engine (FastAPI + LLM)"
check_http "Health Endpoint" "http://localhost:8000/health"
check_http "LLM Service" "http://localhost:8000/llm/health"
echo ""

echo "3. Admin Panel Backend"
check_http "Backend API" "http://localhost:5000/health"
echo ""

echo "4. Admin Panel Frontend"
if curl -s http://localhost:3000 > /dev/null 2>&1; then
    echo -e "  Frontend: ${GREEN}✅ Running on http://localhost:3000${NC}"
elif curl -s http://localhost:5173 > /dev/null 2>&1; then
    echo -e "  Frontend: ${GREEN}✅ Running on http://localhost:5173${NC}"
else
    echo -e "  Frontend: ${YELLOW}⏳ Starting... (check terminals)${NC}"
fi
echo ""

echo "═══════════════════════════════════════════════════════════"
echo "📊 Quick Commands:"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "  Test ML Engine:"
echo "    curl http://localhost:8000/health"
echo ""
echo "  Test Admin Backend:"
echo "    curl http://localhost:5000/health"
echo ""
echo "  View ML Engine Logs:"
echo "    tail -f /tmp/ml-engine.log"
echo ""
echo "  Open Admin Panel:"
echo "    open http://localhost:3000  # or http://localhost:5173"
echo ""
echo "═══════════════════════════════════════════════════════════"
