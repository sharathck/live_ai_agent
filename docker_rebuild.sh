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
# Load environment variables from .env file
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
else
  echo "ERROR ERROR ERROR  :::::::::::::   ERROR ERROR ERROR  ::::::::::: .env file not found!"
  exit 1
fi

# check if docker is installed and running
if ! command -v docker &> /dev/null
then
    echo "ERROR ERROR ERROR  :::::::::::::   ERROR ERROR ERROR  ::::::::::: Docker could not be found. Please install Docker and start the Docker daemon."
    exit
fi

# bash single command to build and push the docker image to google cloud registry
docker buildx build --platform linux/amd64 --load -t local_docker_tesing . 2>&1 | tee docker_build.log
# check if the docker image was built successfully
if [ $? -ne 0 ]; then
    echo "ERROR ERROR ERROR  :::::::::::::   ERROR ERROR ERROR  ::::::::::: Docker image build failed. Please check the logs for more details."
    exit 1
fi

docker run -d -p 8000:8000 --name websocket-demo-app local_docker_tesing 2>&1 | tee docker_run.log
# check if the docker image was run successfully
if [ $? -ne 0 ]; then
    echo "ERROR ERROR ERROR  :::::::::::::   ERROR ERROR ERROR  ::::::::::: Docker image run failed. Please check the logs for more details."
    exit 1
fi
docker logs -f websocket-demo-app