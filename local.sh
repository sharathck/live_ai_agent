#!/bin/bash

# Script to start both frontend and backend services
# Author: Generated for oauth_refresh_docker-gemini-live-customer-care project

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to cleanup processes on script exit
cleanup() {
    echo -e "\n${YELLOW}Shutting down services...${NC}"
    if [ ! -z "$FRONTEND_PID" ]; then
        kill $FRONTEND_PID 2>/dev/null
        echo -e "${RED}Frontend server stopped${NC}"
    fi
    if [ ! -z "$BACKEND_PID" ]; then
        kill $BACKEND_PID 2>/dev/null
        echo -e "${RED}Backend server stopped${NC}"
    fi
    exit 0
}

# Set trap to cleanup on script exit
trap cleanup SIGINT SIGTERM EXIT

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo -e "${GREEN}Starting services from: $SCRIPT_DIR${NC}"

# Start frontend server
echo -e "${GREEN}Starting frontend server on port 8077...${NC}"
cd "$SCRIPT_DIR/frontend"
python3 -m http.server 8077 > /dev/null 2>&1 &
FRONTEND_PID=$!

# Wait a moment for frontend to start
sleep 2

# Check if frontend started successfully
if kill -0 $FRONTEND_PID 2>/dev/null; then
    echo -e "${GREEN}✓ Frontend server started (PID: $FRONTEND_PID)${NC}"
    echo -e "${GREEN}  Access frontend at: http://localhost:8077${NC}"
else
    echo -e "${RED}✗ Failed to start frontend server${NC}"
    exit 1
fi

# Start backend server
echo -e "${GREEN}Starting backend server...${NC}"
cd "$SCRIPT_DIR/backend"
python3 main.py > /dev/null 2>&1 &
BACKEND_PID=$!

# Wait a moment for backend to start
sleep 2

# Check if backend started successfully
if kill -0 $BACKEND_PID 2>/dev/null; then
    echo -e "${GREEN}✓ Backend server started (PID: $BACKEND_PID)${NC}"
    echo -e "${GREEN}  Backend WebSocket available at: ws://localhost:8080${NC}"
else
    echo -e "${RED}✗ Failed to start backend server${NC}"
    kill $FRONTEND_PID 2>/dev/null
    exit 1
fi

echo -e "\n${GREEN}🚀 Both services are running!${NC}"
echo -e "${GREEN}Frontend: http://localhost:8077${NC}"
echo -e "${GREEN}Backend WebSocket: ws://localhost:8080${NC}"
echo -e "\n${YELLOW}Press Ctrl+C to stop both services${NC}"

# Keep the script running and monitor the processes
while true; do
    # Check if frontend is still running
    if ! kill -0 $FRONTEND_PID 2>/dev/null; then
        echo -e "${RED}Frontend server stopped unexpectedly${NC}"
        break
    fi
    
    # Check if backend is still running
    if ! kill -0 $BACKEND_PID 2>/dev/null; then
        echo -e "${RED}Backend server stopped unexpectedly${NC}"
        break
    fi
    
    sleep 5
done

# Cleanup will be called automatically by the trap
