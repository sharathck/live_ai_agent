window.addEventListener("load", (event) => {
    console.log("Hello Gemini Realtime Demo!");

    // Don't show any status on initial load - keep bottom bar hidden
    hideStatusBar();
    
    setAvailableCamerasOptions();
    setAvailableMicrophoneOptions();
});

// Automatically select URL based on hostname
const PROXY_URL = window.location.host.includes('8077')
    ? "ws://localhost:8080"
    : window.location.hostname.startsWith('live-agent') 
        ? "wss://live-agent-learn-english-892085575649.us-central1.run.app//wss"
        : "ws://localhost:8000/ws";
const PROJECT_ID = "reviewtext-ad5c6";
const MODEL = "gemini-live-2.5-flash-preview-native-audio";
//const MODEL = "gemini-2.0-flash-live-preview-04-09";
//const MODEL = "gemini-2.5-flash-preview-native-audio-dialog";
const API_HOST = "us-central1-aiplatform.googleapis.com";


console.log("Dynamic logic PROXY_URL: ", PROXY_URL);
console.log("Using PROJECT_ID: ", PROJECT_ID);
console.log("Using MODEL: ", MODEL);
console.log("Using API_HOST: ", API_HOST);

const projectInput = document.getElementById("project");
const systemInstructionsInput = document.getElementById("systemInstructions");

CookieJar.init("project");
CookieJar.init("systemInstructions");

const disconnected = document.getElementById("disconnected");
const connecting = document.getElementById("connecting");
const connected = document.getElementById("connected");
const speaking = document.getElementById("speaking");

const micBtn = document.getElementById("micBtn");
const micOffBtn = document.getElementById("micOffBtn");
const cameraBtn = document.getElementById("cameraBtn");
const screenBtn = document.getElementById("screenBtn");

const cameraSelect = document.getElementById("cameraSource");
const micSelect = document.getElementById("audioSource");

const geminiLiveApi = new GeminiLiveAPI(PROXY_URL, PROJECT_ID, MODEL, API_HOST);

geminiLiveApi.onErrorMessage = (message) => {
    showDialogWithMessage(message);
    setAppStatus("disconnected");
    stopAudioInput();
};

function getSelectedResponseModality() {
    // return "AUDIO";
    const radioButtons = document.querySelectorAll(
        'md-radio[name="responseModality"]',
    );

    let selectedValue;
    for (const radioButton of radioButtons) {
        if (radioButton.checked) {
            selectedValue = radioButton.value;
            break;
        }
    }
    return selectedValue;
}

function getSystemInstructions() {
    return systemInstructionsInput.value;
}

function connectBtnClick() {
    setAppStatus("connecting");

    geminiLiveApi.responseModalities = getSelectedResponseModality();
    geminiLiveApi.systemInstructions = getSystemInstructions();

    geminiLiveApi.onConnectionStarted = () => {
        setAppStatus("connected");
        startAudioInput();
    };

    geminiLiveApi.setProjectId(projectInput.value);
    geminiLiveApi.connect();
}

function disconnectBtnClick() {
    hideStatusBar();
    geminiLiveApi.disconnect();
    stopAudioInput();
}

const liveAudioOutputManager = new LiveAudioOutputManager();

geminiLiveApi.onReceiveResponse = (messageResponse) => {
    if (messageResponse.type == "AUDIO") {
        // Set status to "speaking" when receiving audio response
        setAppStatus("speaking");
        liveAudioOutputManager.playAudioChunk(messageResponse.data);
        
        // Set a timer to return to "connected" after audio finishes
        // This is a rough estimate - you may want to use audio events for more precision
        setTimeout(() => {
            setAppStatus("connected");
        }, 2000); // Adjust timing as needed
        
    } else if (messageResponse.type == "TEXT") {
        console.log("Gemini said: ", messageResponse.data);
        newModelMessage(messageResponse.data);
        
        // For text responses, briefly show speaking then return to connected
        setAppStatus("speaking");
        setTimeout(() => {
            setAppStatus("connected");
        }, 1000);
    }
};

const liveAudioInputManager = new LiveAudioInputManager();

liveAudioInputManager.onNewAudioRecordingChunk = (audioData) => {
    geminiLiveApi.sendAudioMessage(audioData);
};

function addMessageToChat(message) {
    const textChat = document.getElementById("text-chat");
    const newParagraph = document.createElement("p");
    newParagraph.textContent = message;
    textChat.appendChild(newParagraph);
}

function newModelMessage(message) {
    addMessageToChat(">> " + message);
}

function newUserMessage() {
    const textMessage = document.getElementById("text-message");
    addMessageToChat("User: " + textMessage.value);
    geminiLiveApi.sendTextMessage(textMessage.value);

    textMessage.value = "";
}

function startAudioInput() {
    liveAudioInputManager.connectMicrophone();
}

function stopAudioInput() {
    liveAudioInputManager.disconnectMicrophone();
}

function micBtnClick() {
    console.log("micBtnClick");
    stopAudioInput();
    micBtn.hidden = true;
    micOffBtn.hidden = false;
}

function micOffBtnClick() {
    console.log("micOffBtnClick");
    startAudioInput();

    micBtn.hidden = false;
    micOffBtn.hidden = true;
}

const videoElement = document.getElementById("video");
const canvasElement = document.getElementById("canvas");

const liveVideoManager = new LiveVideoManager(videoElement, canvasElement);

const liveScreenManager = new LiveScreenManager(videoElement, canvasElement);

liveVideoManager.onNewFrame = (b64Image) => {
    geminiLiveApi.sendImageMessage(b64Image);
};

liveScreenManager.onNewFrame = (b64Image) => {
    geminiLiveApi.sendImageMessage(b64Image);
};

function startCameraCapture() {
    liveScreenManager.stopCapture();
    liveVideoManager.startWebcam();
}

function startScreenCapture() {
    liveVideoManager.stopWebcam();
    liveScreenManager.startCapture();
}

function cameraBtnClick() {
    startCameraCapture();
    console.log("cameraBtnClick");
}

function screenShareBtnClick() {
    startScreenCapture();
    console.log("screenShareBtnClick");
}

function newCameraSelected() {
    console.log("newCameraSelected ", cameraSelect.value);
    liveVideoManager.updateWebcamDevice(cameraSelect.value);
}

function newMicSelected() {
    console.log("newMicSelected", micSelect.value);
    liveAudioInputManager.updateMicrophoneDevice(micSelect.value);
}


function showDialogWithMessage(messageText) {
    const dialog = document.getElementById("dialog");
    const dialogMessage = document.getElementById("dialogMessage");
    dialogMessage.innerHTML = messageText;
    dialog.show();
}

async function getAvailableDevices(deviceType) {
    const allDevices = await navigator.mediaDevices.enumerateDevices();
    const devices = [];
    allDevices.forEach((device) => {
        if (device.kind === deviceType) {
            devices.push({
                id: device.deviceId,
                name: device.label || device.deviceId,
            });
        }
    });
    return devices;
}

async function getAvailableCameras() {
    return await this.getAvailableDevices("videoinput");
}

async function getAvailableAudioInputs() {
    return await this.getAvailableDevices("audioinput");
}

function setMaterialSelect(allOptions, selectElement) {
    allOptions.forEach((optionData) => {
        const option = document.createElement("md-select-option");
        option.value = optionData.id;

        const slotDiv = document.createElement("div");
        slotDiv.slot = "headline";
        slotDiv.innerHTML = optionData.name;
        option.appendChild(slotDiv);

        selectElement.appendChild(option);
    });
}

async function setAvailableCamerasOptions() {
    const cameras = await getAvailableCameras();
    const videoSelect = document.getElementById("cameraSource");
    setMaterialSelect(cameras, videoSelect);
}

async function setAvailableMicrophoneOptions() {
    const mics = await getAvailableAudioInputs();
    const audioSelect = document.getElementById("audioSource");
    setMaterialSelect(mics, audioSelect);
}

function showStatusBar() {
    const statusBar = document.getElementById("model-state");
    if (statusBar) {
        statusBar.style.display = "flex";
        document.body.classList.add("status-bar-visible");
    }
}

function hideStatusBar() {
    const statusBar = document.getElementById("model-state");
    if (statusBar) {
        statusBar.style.display = "none";
        document.body.classList.remove("status-bar-visible");
    }
    // When status bar is hidden, show connect button and hide disconnect button
    showConnectButton();
    hideDisconnectButton();
}

function showConnectButton() {
    const connectBtn = document.querySelector('md-outlined-button[onclick*="connectBtnClick"]');
    if (connectBtn) connectBtn.style.display = "inline-flex";
}

function hideConnectButton() {
    const connectBtn = document.querySelector('md-outlined-button[onclick*="connectBtnClick"]');
    if (connectBtn) connectBtn.style.display = "none";
}

function showDisconnectButton() {
    const disconnectBtn = document.querySelector('md-outlined-button[onclick*="disconnectBtnClick"]');
    if (disconnectBtn) disconnectBtn.style.display = "inline-flex";
}

function hideDisconnectButton() {
    const disconnectBtn = document.querySelector('md-outlined-button[onclick*="disconnectBtnClick"]');
    if (disconnectBtn) disconnectBtn.style.display = "none";
}

function setAppStatus(status) {
    // Show status bar when setting any status
    showStatusBar();
    
    // Hide ALL status elements first
    disconnected.hidden = true;
    connecting.hidden = true;
    connected.hidden = true;
    speaking.hidden = true;

    // Also hide via CSS display for extra safety
    disconnected.style.display = "none";
    connecting.style.display = "none";
    connected.style.display = "none";
    speaking.style.display = "none";

    // Show ONLY the current status and manage button visibility
    // Show all 4 individual states: disconnected, connecting, connected, speaking
    switch (status) {
        case "disconnected":
            disconnected.hidden = false;
            disconnected.style.display = "flex";
            // Show connect button, hide disconnect button
            showConnectButton();
            hideDisconnectButton();
            break;
        case "connecting":
            connecting.hidden = false;
            connecting.style.display = "flex";
            // Show connect button (still connecting), hide disconnect button
            showConnectButton();
            hideDisconnectButton();
            break;
        case "connected":
            connected.hidden = false;
            connected.style.display = "flex";
            // Hide connect button, show disconnect button
            hideConnectButton();
            showDisconnectButton();
            break;
        case "speaking":
            speaking.hidden = false;
            speaking.style.display = "flex";
            // Hide connect button, show disconnect button
            hideConnectButton();
            showDisconnectButton();
            break;
        default:
            // Default to disconnected if unknown status
            disconnected.hidden = false;
            disconnected.style.display = "flex";
            // Show connect button, hide disconnect button
            showConnectButton();
            hideDisconnectButton();
    }
    
    console.log("Status changed to:", status);
}