# Multimodal Live API Demo

In this tutorial, you will be building a web application that enables you to use your voice and camera to talk to Gemini 2.0 through the [Multimodal Live API](https://cloud.google.com/vertex-ai/generative-ai/docs/model-reference/multimodal-live).

The [Multimodal Live API](https://cloud.google.com/vertex-ai/generative-ai/docs/model-reference/multimodal-live) is a low-latency bidirectional streaming API that supports audio and video streaming inputs and can output audio.

```
The backend WebSocket server is running
  on port 8080 inside the container, but the frontend is connecting
  to port 8000. However, this is actually correct because of how the
   Docker setup works:

  1. Backend WebSocket server: Runs on port 8080 inside the
  container
  2. Nginx: Runs on port 8000 inside the container and proxies /ws
  requests to the backend on port 8080
  3. Docker: Exposes port 8000 from the container to the host

  So the flow is:
  - Frontend connects to ws://localhost:8000/ws
  - Docker forwards this to port 8000 inside the container
  - Nginx receives the request on port 8000 and proxies it to the
  backend on port 8080

  This is the correct architecture. The fact that you're seeing
  "websocket open" means the connection is working properly through
  this proxy chain. The WebSocket connection is successfully
  established!

  The configuration is correct as it stands.

```
### Commands
```shell
gcloud components update
gcloud components install beta
gcloud config set project reviewtext-ad5c6
gcloud auth print-access-token
```
### Local Docker
```shell
docker build --load -t websocket-demo-app .
docker build -t websocket-demo-app .
docker build -t websocket-demo-app . --no-cache
docker run -d -p 8000:8000 websocket-demo-app

docker run -d -p 8000:8000 --name websocket-demo-app websocket-demo-app
docker run -d -p 8000:8000 -v
      ~/.config/gcloud:/root/.config/gcloud --name
      websocket-demo-app websocket-demo-app

⏺ Bash(docker ps -q)
  ⎿  c9215eaf35dc

⏺ Bash(docker stop c9215eaf35dc && docker rm c9215eaf35dc)
  ⎿  c9215eaf35dc
     c9215eaf35dc
⏺ Bash(docker system prune -af --volumes)

docker logs -f websocket-demo-app # gives real time log information
```

### successful local docker
```

⏺ I'll stop the current Docker container, rebuild it, and run it
  again with the updated configuration.

⏺ Bash(docker stop websocket-demo-app && docker rm
      websocket-demo-app)
  ⎿  websocket-demo-app
     websocket-demo-app

⏺ Bash(docker build -t websocket-demo-app .)
  ⎿  #0 building with "desktop-linux" instance using docker driver

     #1 [internal] load build definition from Dockerfile
     … +67 lines (ctrl+r to expand)

⏺ Bash(docker run -d -p 8000:8000 -v
      ~/.config/gcloud:/root/.config/gcloud --name
      websocket-demo-app websocket-demo-app)
  ⎿ d83803f39efa528bbf905189b7e2a6905a5b5f0fac23998403870b35f82feb0f


⏺ Bash(docker ps)
  ⎿  CONTAINER ID   IMAGE                           COMMAND
             CREATED          STATUS          PORTS
                            NAMES
     … +6 lines (ctrl+r to expand)

⏺ Bash(sleep 30 && docker exec websocket-demo-app netstat -tlnp)
  ⎿  Active Internet connections (only servers)
     Proto Recv-Q Send-Q Local Address           Foreign Address
         State       PID/Program name
     … +6 lines (ctrl+r to expand)

⏺ Perfect! The Docker container has been successfully rebuilt and is
   running:

  ✅ Container Status:
  - Container ID: d83803f39efa
  - Status: Up and running
  - Port Mapping: 0.0.0.0:8000->8000/tcp

  ✅ Services Running:
  - Frontend: nginx on port 8000 (PID 100)
  - Backend: Python WebSocket server on localhost:8080 (PID 99)
  - gcloud: Mounted with credentials from ~/.config/gcloud

  ✅ Access Points:
  - Frontend: http://localhost:8000
  - WebSocket: ws://localhost:8000/ws (proxied to backend:8080)

  The container is now ready to use with the updated configuration
  and gcloud credentials properly mounted!
```

## Architecture

- **Backend (Python WebSockets Server):** Handles authentication and acts as an intermediary between your frontend and the Gemini API.
- **Frontend (HTML/JavaScript):** Provides the user interface and interacts with the backend via WebSockets.

## Successful backend log looks like this
```
2025-08-27 10:11:37,769 - INFO - 🎬 Starting application...
2025-08-27 10:11:37,769 - INFO - ⏰ Start time: 2025-08-27 10:11:37.769562
2025-08-27 10:11:37,769 - DEBUG - Using selector: KqueueSelector
2025-08-27 10:11:37,769 - INFO - 🚀 Starting WebSocket server...
2025-08-27 10:11:37,769 - INFO - 🔧 Initializing authentication service...
2025-08-27 10:11:37,769 - INFO - 🔧 Initializing ServiceAccountAuth...
2025-08-27 10:11:37,769 - DEBUG - 📁 Credentials path provided: None
2025-08-27 10:11:37,769 - DEBUG - 🏷️ Project ID provided: reviewtext-ad5c6
2025-08-27 10:11:37,769 - INFO - 📂 Using credentials file: reviewtext-ad5c6-vertex-ai.json
2025-08-27 10:11:37,769 - INFO - 🏷️ Using project ID: reviewtext-ad5c6
2025-08-27 10:11:37,769 - DEBUG - 🌍 GOOGLE_CLOUD_PROJECT_ID env var: None
2025-08-27 10:11:37,769 - INFO - 📄 Loading credentials...
2025-08-27 10:11:37,769 - INFO - 🔑 Loading credentials from: reviewtext-ad5c6-vertex-ai.json
2025-08-27 10:11:37,770 - INFO - ✅ Credentials file exists: reviewtext-ad5c6-vertex-ai.json
2025-08-27 10:11:37,770 - DEBUG - 📊 File size: 2358 bytes
2025-08-27 10:11:37,770 - INFO - ✅ JSON credentials loaded successfully
2025-08-27 10:11:37,770 - DEBUG - 🔍 Credential keys: ['type', 'project_id', 'private_key_id', 'private_key', 'client_email', 'client_id', 'auth_uri', 'token_uri', 'auth_provider_x509_cert_url', 'client_x509_cert_url', 'universe_domain']
2025-08-27 10:11:37,770 - DEBUG - 📧 Service account email: vertexai@reviewtext-ad5c6.iam.gserviceaccount.com
2025-08-27 10:11:37,770 - DEBUG - 🆔 Project ID from creds: reviewtext-ad5c6
2025-08-27 10:11:37,770 - INFO - 🎯 Using scopes: ['https://www.googleapis.com/auth/cloud-platform']
2025-08-27 10:11:37,843 - INFO - ✅ Service account credentials created successfully
2025-08-27 10:11:37,843 - DEBUG - 🔗 Credentials service account email: vertexai@reviewtext-ad5c6.iam.gserviceaccount.com
2025-08-27 10:11:37,843 - DEBUG - 🎯 Credentials scopes: ['https://www.googleapis.com/auth/cloud-platform']
2025-08-27 10:11:37,843 - INFO - ✅ Authentication service initialized successfully
2025-08-27 10:11:37,843 - INFO - 🌐 Starting server on localhost:8080...
2025-08-27 10:11:37,846 - INFO - server listening on [::1]:8080
2025-08-27 10:11:37,846 - INFO - server listening on 127.0.0.1:8080
2025-08-27 10:11:37,846 - INFO - ✅ WebSocket server running on localhost:8080
2025-08-27 10:11:37,846 - INFO - ⏳ Waiting for connections...
```
## Pre-requisites

While some web development experience, particularly with localhost, port numbers, and the distinction between WebSockets and HTTP requests, can be beneficial for this tutorial, don't worry if you're not familiar with these concepts. We'll provide guidance along the way to ensure you can successfully follow along.

### File Structure

- `backend/main.py`: The Python backend code
- `backend/requirements.txt`: Lists the required Python dependencies

- `frontend/index.html`: The frontend HTML app
- `frontend/script.js`: Main frontend JavaScript code
- `frontend/gemini-live-api.js`: Script for interacting with the Gemini API
- `frontend/live-media-manager.js`: Script for handling media input and output
- `frontend/pcm-processor.js`: Script for processing PCM audio
- `frontend/cookieJar.js`: Script for managing cookies

![Demo](https://storage.googleapis.com/cloud-samples-data/generative-ai/image/demo-UI.png)

## Setup instructions

You can set up this app locally or via Cloud Shell.

### Setup locally

1. Clone the repository and cd into the correct directory

    ```sh
    git clone https://github.com/GoogleCloudPlatform/generative-ai.git
    cd generative-ai/gemini/multimodal-live-api/websocket-demo-app
    ```

1. Create a new virtual environment and activate it:

    ```sh
    python3 -m venv env
    source env/bin/activate
    ```

1. Install dependencies:

    ```sh
    pip3 install -r backend/requirements.txt
    ```

1. Start the Python WebSocket server:

    ```sh
    python3 backend/main.py
    ```

1. Start the frontend:

    - Navigate to `script.js` on line 9, `const PROXY_URL = "wss://[THE_URL_YOU_COPIED_WITHOUT_HTTP]";` and replace `PROXY_URL` value with `ws://localhost:8000`. It should look like: `const PROXY_URL = "ws://localhost:8000";`. Note the absence of the second "s" in "wss" as "ws" indicates a non-secure WebSocket connection.
    - Right below on line 10, update `PROJECT_ID` with your Google Cloud project ID.
    - Save the changes you've made to `script.js`
    - Now make sure to open a **separate** terminal window from the backend to run this command (keep the backend server running in the first terminal).

    ```sh
    cd frontend
    python3 -m http.server 8077
    ```

1. Point your browser to the demo app UI based on the output of the terminal. (e.g., it may be `http://localhost:8000`, or it may use a different port.)

1. Get your Google Cloud access token:
   Run the following command in a terminal with gcloud installed to set your project, and to retrieve your access token.

    ```sh
    gcloud components update
    gcloud components install beta
    gcloud config set project YOUR-PROJECT-ID
    gcloud auth print-access-token
    ```

1. Copy the access token from the previous step into the UI that you have open in your browser.

1. Enter the model ID in the UI:
   Replace `YOUR-PROJECT-ID` in the input with your Google Cloud Project ID.

1. Connect and interact with the demo:

    - After entering your Access Token and Model ID, press the connect button to connect your web app. Now you should be able to interact with Gemini 2.0 with the Multimodal Live API.

1. To interact with the app, you can do the following:

    - Text input: You can write a text prompt to send to the model by entering your message in the box and pressing the send arrow. The model will then respond via audio (turn up your volume!).
    - Voice input: Press the microphone button to stop speaking. The model will respond via audio. If you would like to mute your microphone, press the button with a slash through the microphone.
    - Video input: The model will also capture your camera input and send it to Gemini. You can ask questions about current or previous video footage. For more details on how this works, visit the [documentation page for the Multimodal Live API](https://cloud.google.com/vertex-ai/generative-ai/docs/model-reference/multimodal-live).

### Setup in Cloud Shell

1. Open [Cloud Shell](https://cloud.google.com/shell/docs/editor-overview)

1. Upload the frontend and backend folders to your Cloud Shell Editor project. Alternatively, you can clone the repository and cd into the correct directory:

    ```sh
    git clone https://github.com/GoogleCloudPlatform/generative-ai.git
    cd generative-ai/gemini/multimodal-live-api/websocket-demo-app
    ```

1. Open two new terminal windows.
1. Navigate to whichever folder in Cloud Shell you uploaded the code files to (i.e., using `cd your_folder_name`)

1. Install dependencies: In one of the terminal windows run:

    ```sh
    pip3 install -r backend/requirements.txt
    ```

1. Start the Python WebSocket server in one terminal.

    ```sh
    python3 backend/main.py
    ```

1. In order for index.html to work properly, you will need to update the app URL inside script.js to point to the correct proxy server URL you just set up in the previous step. To do so:

    - Click on Web Preview (to the right of the Open Terminal button near the top)
    - Click "Preview on port 8080" (the port where you've setup the proxy server in the previous step)
    - Copy the URL, but make sure to discard everything at the end after "cloudshell.dev/"
    - Navigate to `const PROXY_URL = "wss://your websocket server";` in `frontend/script.js` on line 8
    - Replace `wss://your websocket server` with `wss://[THE_URL_YOU_COPIED_WITHOUT_HTTP]`. For example, it should look like: `const PROXY_URL = "wss://8080-cs-123456789-default.cs-us-central1-abcd.cloudshell.dev";`
    - Replace `your project id` with your project ID on line 9, for the `const PROJECT_ID`
    - save the changes you've made to script.js

1. Start the frontend:
   In the second terminal window, run the command below. Keep the backend server running in the first terminal.
   (Make sure you have navigated to the folder containing the code files, i.e. using `cd frontend`)

    ```sh
    cd frontend
    python3 -m http.server
    ```

1. Test the demo app:

    - Navigate to the Web Preview button again
    - Click on "Change port"
    - Change Preview Port to 8000, and then click on "Change and Preview". This should open up a new tab with the UI.

1. Going back to the tab with the Cloud Shell Editor, connect to the application by running the following command in a new terminal window:

    ```sh
    gcloud config set project reviewtext-ad5c6
    gcloud auth print-access-token
    ```
[Your Access Token Here]



    - Copy your access token and paste it in the Access Token field in the UI.
    - In the second field of the UI, labeled Project ID, add your Google Cloud Project ID
    - Press the "Connect" button. Now you should be able to interact with Gemini 2.0 with the Multimodal Live API.

1. To interact with the app, you can do the following:

    - Text input: You can write a text prompt to send to the model by entering your message in the box and pressing the send arrow. The model will then respond via audio (turn up your volume!).
    - Voice input: Press the pink microphone button and start speaking. The model will respond via audio. If you would like to mute your microphone, press the button with a slash through the microphone.
    - Video input: The model will also capture your camera input and send it to Gemini. You can ask questions about current or previous video footage. For more details on how this works, visit the [documentation page for the Multimodal Live API](https://cloud.google.com/vertex-ai/generative-ai/docs/model-reference/multimodal-live).

### Setup in Cloud Run

1. Clone the repository and cd into the correct directory

    ```sh
    git clone https://github.com/GoogleCloudPlatform/generative-ai.git
    cd generative-ai/gemini/multimodal-live-api/websocket-demo-app
    ```

1. Modify the frontend code to point the WebSocket endpoint to the same container:

    - Navigate to the `script.js` file on line 9, `const PROXY_URL = "wss://[THE_URL_YOU_COPIED_WITHOUT_HTTP]";` and replace `PROXY_URL` value with `/ws`. It should look like: `const PROXY_URL = "/ws";`. Note the absence of the second "s" in "wss" as "ws" indicates a non-secure WebSocket connection. And there is no host part as it will use the same container as the frontend and backend.
    - Right below on line 10, update `PROJECT_ID` with your Google Cloud project ID.
    - Save the changes you've made to `script.js`

1. Deploy the code to Cloud Run using the following `gcloud` command:

    ```sh
    gcloud run deploy --project=YOUR-PROJECT-ID \
    --region=us-central1 \
    --source=./ \
    --allow-unauthenticated \
    --port=8000  \
    gemini-live-demo
    ```

1. Last step command will output a link for the deployment if it run successfully. Copy the link to your browser and navigate to the demo app UI.

1. Get your Google Cloud access token: Run the following command in a terminal with gcloud installed to set your project, and to retrieve your access token.

    ```sh
    gcloud components update
    gcloud components install beta
    gcloud config set project YOUR-PROJECT-ID
    gcloud auth print-access-token
    ```

1. Copy the access token from the previous step into the UI that you have open in your browser.

1. Enter the model ID in the UI:
   Replace `YOUR-PROJECT-ID` in the input with your Google Cloud Project ID.

1. Connect and interact with the demo:

    - After entering your Access Token and Model ID, press the connect button to connect your web app. Now you should be able to interact with Gemini 2.0 with the Multimodal Live API.

1. To interact with the app, you can do the following:

    - Text input: You can write a text prompt to send to the model by entering your message in the box and pressing the send arrow. The model will then respond via audio (turn up your volume!).
    - Voice input: Press the microphone button to stop speaking. The model will respond via audio. If you would like to mute your microphone, press the button with a slash through the microphone.
    - Video input: The model will also capture your camera input and send it to Gemini. You can ask questions about current or previous video footage. For more details on how this works, visit the [documentation page for the Multimodal Live API](https://cloud.google.com/vertex-ai/generative-ai/docs/model-reference/multimodal-live).
