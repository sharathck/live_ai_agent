echo "Deploying the application to Google Cloud Run..."

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
# check if gcloud is installed and running
if ! command -v gcloud &> /dev/null
then
    echo "ERROR ERROR ERROR  :::::::::::::   ERROR ERROR ERROR  ::::::::::: gcloud could not be found. Please install Google Cloud SDK and authenticate."
    exit
fi
# check if gcloud is authenticated
if ! gcloud auth list --format="value(account)" | grep -q "@"; then
    echo "ERROR ERROR ERROR  :::::::::::::   ERROR ERROR ERROR  ::::::::::: gcloud is not authenticated. Please run 'gcloud auth login' to authenticate."
    exit
fi
# check if gcloud is set to the correct project
if ! gcloud config get-value project | grep -q "$GOOGLE_CLOUD_PROJECT_ID"; then
    echo "ERROR ERROR ERROR  :::::::::::::   ERROR ERROR ERROR  ::::::::::: gcloud is not set to the correct project. Please run 'gcloud config set project $GOOGLE_CLOUD_PROJECT_ID' to set the project."
    exit
fi
# check if gcloud is set to the correct region
if ! gcloud config get-value compute/region | grep -q "$GOOGLE_CLOUD_REGION"; then
    echo "ERROR ERROR ERROR  :::::::::::::   ERROR ERROR ERROR  ::::::::::: gcloud is not set to the correct region. Please run 'gcloud config set compute/region $GOOGLE_CLOUD_REGION' to set the region."
    exit
fi
# check if gcloud is set to the correct project id
if ! gcloud config get-value project | grep -q "$GOOGLE_CLOUD_PROJECT_ID"; then
    echo "ERROR ERROR ERROR  :::::::::::::   ERROR ERROR ERROR  ::::::::::: gcloud is not set to the correct project id. Please run 'gcloud config set project $GOOGLE_CLOUD_PROJECT_ID' to set the project id."
    exit
fi
# check if git is installed
if ! command -v git &> /dev/null
then
    echo "ERROR ERROR ERROR  :::::::::::::   ERROR ERROR ERROR  ::::::::::: git could not be found. Please install git."
    exit
fi
# check if git is authenticated
if ! git config --get user.name &> /dev/null; then
    echo "ERROR ERROR ERROR  :::::::::::::   ERROR ERROR ERROR  ::::::::::: git is not authenticated. Please run 'git config --global user.name \"Your Name\"' to set the user name."
    exit
fi
if ! git config --get user.email &> /dev/null; then
    echo "ERROR ERROR ERROR  :::::::::::::   ERROR ERROR ERROR  ::::::::::: git is not authenticated. Please run 'git config --global user.email \"Your Email\"' to set the user email."
    exit
fi

# register the docker image to google cloud registry
# Check if Docker daemon is running before building
echo "Checking if Docker daemon is running..."
echo "Executing: docker info >/dev/null 2>&1"
if ! docker info >/dev/null 2>&1; then
    echo "ERROR ERROR ERROR  :::::::::::::   ERROR ERROR ERROR  ::::::::::: Docker daemon is not running. Please start Docker Desktop or Docker daemon."
    exit 1
fi

# bash single command to build and push the docker image to google cloud registry
echo "Executing: docker buildx build --platform linux/amd64 --load -t $DOCKER_IMAGE_TAG . 2>&1 | tee docker_build.log"
docker buildx build --platform linux/amd64 --load -t $DOCKER_IMAGE_TAG . 2>&1 | tee docker_build.log
# check if the docker image was built successfully
if [ $? -ne 0 ]; then
    echo "ERROR ERROR ERROR  :::::::::::::   ERROR ERROR ERROR  ::::::::::: Docker image build failed. Please check the logs for more details."
    exit 1
fi

echo "Executing: docker push $DOCKER_IMAGE_TAG 2>&1 | tee docker_push.log"
docker push $DOCKER_IMAGE_TAG 2>&1 | tee docker_push.log
# check if the docker image was pushed successfully
if [ $? -ne 0 ]; then
    echo "Docker image push failed. Please check the logs for more details."
    exit 1
fi

# Inspect the built image to show architecture details
echo "Inspecting Docker image architecture..."
echo "Executing: docker image inspect $DOCKER_IMAGE_TAG"
docker image inspect $DOCKER_IMAGE_TAG

# wait for the docker image to be pushed for 5 seconds
echo "Waiting for 5 seconds for the docker image to be pushed..."
echo "Executing: sleep 5"
sleep 5

# Deploy the application to Google Cloud Run
echo "Executing: gcloud run deploy $GOOGLE_CLOUD_RUN_SERVICE_NAME --image $DOCKER_IMAGE_TAG --platform managed --region $GOOGLE_CLOUD_REGION --allow-unauthenticated --project $GOOGLE_CLOUD_PROJECT_ID"
gcloud run deploy $GOOGLE_CLOUD_RUN_SERVICE_NAME \
  --image $DOCKER_IMAGE_TAG \
  --platform managed \
  --region $GOOGLE_CLOUD_REGION \
  --source=./ \
  --allow-unauthenticated \
  --port=8000 \
  --project $GOOGLE_CLOUD_PROJECT_ID
# Check if the deployment was successful
if [ $? -ne 0 ]; then
    echo "ERROR ERROR ERROR  :::::::::::::   ERROR ERROR ERROR  ::::::::::: Deployment failed. Please check the logs for more details."
    exit 1
fi

echo "Deployment process completed!"

echo ""
echo "========================================"
echo "        DEPLOYMENT STATUS REPORT"
echo "========================================"

# Get latest revision info with timestamp (converted to Central Time)
echo "Latest Revision Information (Central Time):"
echo "Executing: gcloud run revisions list --service=$GOOGLE_CLOUD_RUN_SERVICE_NAME --region=$GOOGLE_CLOUD_REGION --project=$GOOGLE_CLOUD_PROJECT_ID --limit=1"
REVISION_DATA=$(gcloud run revisions list --service=$GOOGLE_CLOUD_RUN_SERVICE_NAME --region=$GOOGLE_CLOUD_REGION --project=$GOOGLE_CLOUD_PROJECT_ID --limit=1 --format="value(metadata.name,metadata.creationTimestamp,status.conditions[0].status)")
if [ ! -z "$REVISION_DATA" ]; then
  echo "$REVISION_DATA" | while IFS=$'\t' read -r name timestamp status; do
    # Convert UTC timestamp to Central Time
    if command -v date >/dev/null 2>&1; then
      if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS date command
        CENTRAL_TIME=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$timestamp" "+%Y-%m-%d %H:%M:%S %Z" 2>/dev/null || echo "$timestamp")
      else
        # Linux date command
        CENTRAL_TIME=$(date -d "$timestamp" -u "+%Y-%m-%d %H:%M:%S %Z" 2>/dev/null || echo "$timestamp")
      fi
    else
      CENTRAL_TIME="$timestamp"
    fi
    printf "%-50s %-25s %s\n" "$name" "$CENTRAL_TIME" "$status"
  done
fi

# Get traffic allocation
echo ""
echo "Traffic Allocation:"
echo "Executing: gcloud run services describe $GOOGLE_CLOUD_RUN_SERVICE_NAME --region=$GOOGLE_CLOUD_REGION --project=$GOOGLE_CLOUD_PROJECT_ID"
gcloud run services describe $GOOGLE_CLOUD_RUN_SERVICE_NAME --region=$GOOGLE_CLOUD_REGION --project=$GOOGLE_CLOUD_PROJECT_ID --format="value(status.traffic[].revisionName,status.traffic[].percent)" | while read revision percent; do
  echo "  $revision: $percent%"
done

# Get service URL
echo ""
echo "Service URL:"
echo "Executing: gcloud run services describe $GOOGLE_CLOUD_RUN_SERVICE_NAME --region=$GOOGLE_CLOUD_REGION --project=$GOOGLE_CLOUD_PROJECT_ID --format=value(status.url)"
SERVICE_URL=$(gcloud run services describe $GOOGLE_CLOUD_RUN_SERVICE_NAME --region=$GOOGLE_CLOUD_REGION --project=$GOOGLE_CLOUD_PROJECT_ID --format="value(status.url)")
echo "  $SERVICE_URL"

# Get recent traffic metrics (last 24 hours)
echo ""
echo "Recent Traffic (Last 24 hours):"
echo "Executing: gcloud logging read for traffic metrics"
REQUEST_COUNT=$(gcloud logging read 'resource.type="cloud_run_revision" resource.labels.service_name="'$GOOGLE_CLOUD_RUN_SERVICE_NAME'"' --project=$GOOGLE_CLOUD_PROJECT_ID --limit=100 --freshness=24h --format="value(timestamp,httpRequest.requestMethod,httpRequest.status)" | grep -E "(POST|GET|OPTIONS|PUT|DELETE)" | wc -l | tr -d ' ')
echo "  Total HTTP Requests: $REQUEST_COUNT"

# Show latest few requests with timestamps
echo ""
echo "Latest Requests:"
echo "Executing: gcloud logging read for latest requests"
gcloud logging read 'resource.type="cloud_run_revision" resource.labels.service_name="'$GOOGLE_CLOUD_RUN_SERVICE_NAME'"' --project=$GOOGLE_CLOUD_PROJECT_ID --limit=5 --freshness=24h --format="value(timestamp,httpRequest.requestMethod,httpRequest.status)" | grep -E "(POST|GET|OPTIONS|PUT|DELETE)" | head -3 | while read line; do
  if [ ! -z "$line" ]; then
    echo "  $line"
  fi
done

echo ""
echo "========================================"
