# Docker Setup for WebSocket Demo App

This Docker configuration runs both the backend (on port 8080) and frontend (on port 8000) in a single container.

## Architecture

- **Frontend**: Served by nginx on port 8000
- **Backend**: Python WebSocket server on port 8080 (internal)
- **Proxy**: nginx proxies `/ws` requests to the backend
- **Process Management**: supervisord manages both nginx and Python processes

## Quick Start

### Using Docker Compose (Recommended)

```bash
# Build and run the container
docker-compose up --build

# Run in background
docker-compose up -d --build

# Stop the container
docker-compose down
```

### Using Docker directly

```bash
# Build the image
docker build -t websocket-demo-app .

# Run the container with gcloud credentials (recommended)
docker run -d -p 8000:8000 -v ~/.config/gcloud:/root/.config/gcloud --name websocket-demo-app websocket-demo-app

# Alternative: Run without gcloud credentials (manual token entry required)
docker run -d -p 8000:8000 --name websocket-demo-app websocket-demo-app
```

## Access the Application

Once running, access the application at:
- **Frontend**: http://localhost:8000
- **WebSocket endpoint**: ws://localhost:8000/ws (proxied to backend)

## Authentication Setup

### Prerequisites

Before running the container, authenticate with Google Cloud:

```bash
# Login to Google Cloud
gcloud auth login

# Set your project
gcloud config set project reviewtext-ad5c6

# Verify authentication
gcloud auth print-access-token
```

### Automatic Token Injection

The container includes gcloud CLI and will:
1. Use your mounted gcloud credentials (`~/.config/gcloud`)
2. Automatically run the following commands on startup:
   - `gcloud components update`
   - `gcloud components install beta`
   - `gcloud config set project reviewtext-ad5c6`
   - `gcloud auth print-access-token`
3. Inject the fresh access token into the frontend automatically

## Configuration

The Docker setup uses:
- `Dockerfile`: Multi-service container configuration with gcloud CLI
- `docker-compose.yml`: Easy orchestration
- `supervisord.conf`: Process management
- `nginx.conf`: Web server and proxy configuration

## Local Development Equivalent

This Docker setup replicates your local development commands:

```bash
# Backend (equivalent to: python3 backend/main.py)
# Runs on port 8080 internally

# Frontend (equivalent to: cd frontend && python3 -m http.server)
# Served by nginx on port 8000
```

## Logs

View logs:
```bash
# Using docker-compose
docker-compose logs -f

# Using docker directly
docker logs -f websocket-demo-app
```

## Troubleshooting

1. **Port conflicts**: Make sure ports 8000 isn't in use
2. **Build issues**: Ensure all files are present in the build context
3. **WebSocket connections**: Check nginx proxy configuration in `nginx.conf`