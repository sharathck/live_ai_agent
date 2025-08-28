#!/bin/bash

echo "Killing all Docker containers..."

# Kill all running containers
docker ps -q | xargs -r docker kill

# Remove all containers (running and stopped)
docker ps -aq | xargs -r docker rm

echo "All Docker containers have been killed and removed."

# Remove all images
echo "Removing all Docker images..."
docker images -q | xargs -r docker rmi -f

# Prune system to clean up everything
echo "Pruning Docker system..."
docker system prune -af --volumes

echo "Done! All Docker containers, images, and volumes have been removed."