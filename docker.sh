# check if docker is installed and running
if ! command -v docker &> /dev/null
then
    echo "ERROR ERROR ERROR  :::::::::::::   ERROR ERROR ERROR  ::::::::::: Docker could not be found. Please install Docker and start the Docker daemon."
    exit
fi

# Stop and remove any existing container with the same name
if [ $(docker ps -aq -f name=websocket-demo-app) ]; then
    echo "Stopping and removing existing websocket-demo-app container..." | tee docker_build.log
    docker stop websocket-demo-app 2>/dev/null | tee docker_build.log
    docker rm websocket-demo-app 2>/dev/null | tee docker_build.log
fi
# bash single command to build and push the docker image to google cloud registry
docker buildx build --platform linux/amd64 --load -t local_docker_tesing . --no-cache 2>&1 | tee docker_build.log
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

