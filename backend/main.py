import asyncio
import json
import os
import subprocess
import logging
import traceback
from datetime import datetime

import websockets
from websockets.legacy.protocol import WebSocketCommonProtocol
from websockets.legacy.server import WebSocketServerProtocol

# Import our auth module
from auth import ServiceAccountAuth

# Set up comprehensive logging
logging.basicConfig(
    level=logging.DEBUG, 
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler('websocket_debug.log')
    ]
)
logger = logging.getLogger(__name__)

HOST = "us-central1-aiplatform.googleapis.com"
SERVICE_URL = f"wss://{HOST}/ws/google.cloud.aiplatform.v1beta1.LlmBidiService/BidiGenerateContent"

DEBUG = True

# Initialize service account auth
auth_service = None

def init_auth():
    """Initialize authentication service"""
    global auth_service
    try:
        logger.info("🔧 Initializing authentication service...")
        auth_service = ServiceAccountAuth(project_id="reviewtext-ad5c6")
        logger.info("✅ Authentication service initialized successfully")
        return True
    except Exception as e:
        logger.error(f"❌ Failed to initialize authentication: {str(e)}")
        logger.error(f"🔍 Error traceback: {traceback.format_exc()}")
        return False

def get_access_token():
    """Get access token using service account authentication"""
    logger.info("🎫 Attempting to get access token...")
    
    # Try service account first
    if auth_service:
        try:
            logger.info("🔑 Using service account authentication...")
            token = auth_service.get_access_token()
            logger.info(f"✅ Service account token obtained: {token[:50]}...")
            logger.info(f"🎫 FULL SERVICE ACCOUNT TOKEN: {token}")
            return token
        except Exception as e:
            logger.error(f"❌ Service account auth failed: {str(e)}")
            logger.error(f"🔍 Error traceback: {traceback.format_exc()}")
    
    # Fallback to gcloud CLI
    logger.info("🔄 Falling back to gcloud CLI authentication...")
    try:
        logger.debug("📡 Running: gcloud auth print-access-token")
        result = subprocess.run(['gcloud', 'auth', 'print-access-token'], 
                               capture_output=True, text=True, check=True)
        token = result.stdout.strip()
        logger.info(f"✅ Gcloud token obtained: {token[:50]}...")
        logger.info(f"🎫 FULL GCLOUD TOKEN: {token}")
        return token
    except subprocess.CalledProcessError as e:
        logger.error(f"❌ Gcloud auth failed: {e}")
        logger.error(f"🔍 Stderr: {e.stderr}")
        logger.error(f"🔍 Stdout: {e.stdout}")
        return None
    except Exception as e:
        logger.error(f"❌ Unexpected error getting token: {str(e)}")
        logger.error(f"🔍 Error traceback: {traceback.format_exc()}")
        return None


async def proxy_task(
    client_websocket: WebSocketCommonProtocol, server_websocket: WebSocketCommonProtocol
) -> None:
    """
    Forwards messages from one WebSocket connection to another.

    Args:
        client_websocket: The WebSocket connection from which to receive messages.
        server_websocket: The WebSocket connection to which to send messages.
    """
    logger.info("🔄 Starting proxy task...")
    message_count = 0
    
    try:
        async for message in client_websocket:
            message_count += 1
            logger.info(f"📨 Message #{message_count} received")
            logger.debug(f"📝 Raw message: {message}")
            
            try:
                data = json.loads(message)
                logger.info(f"✅ Message parsed successfully")
                logger.debug(f"📊 Parsed data keys: {list(data.keys()) if isinstance(data, dict) else 'Not a dict'}")
                
                if DEBUG:
                    logger.debug(f"🔍 Full message data: {data}")
                
                logger.info(f"📤 Sending message to server...")
                await server_websocket.send(json.dumps(data))
                logger.info(f"✅ Message sent successfully")
                
            except json.JSONDecodeError as e:
                logger.error(f"❌ JSON decode error: {str(e)}")
                logger.error(f"🔍 Raw message: {message}")
            except Exception as e:
                logger.error(f"❌ Error processing message #{message_count}: {str(e)}")
                logger.error(f"🔍 Error traceback: {traceback.format_exc()}")
                
    except Exception as e:
        logger.error(f"❌ Error in proxy task: {str(e)}")
        logger.error(f"🔍 Error traceback: {traceback.format_exc()}")
    finally:
        logger.info(f"🔚 Proxy task ending. Processed {message_count} messages")
        try:
            await server_websocket.close()
            logger.info("🔐 Server websocket closed")
        except Exception as e:
            logger.error(f"❌ Error closing server websocket: {str(e)}")


async def create_proxy(
    client_websocket: WebSocketCommonProtocol
) -> None:
    """
    Establishes a WebSocket connection to the server and creates two tasks for
    bidirectional message forwarding between the client and the server.

    Args:
        client_websocket: The WebSocket connection of the client.
    """
    logger.info("🔗 Creating proxy connection...")
    
    logger.info("🎫 Getting bearer token...")
    bearer_token = get_access_token()
    
    if not bearer_token:
        logger.error("❌ Failed to get access token")
        raise Exception("Failed to get access token")
    
    logger.info(f"✅ Bearer token obtained: {bearer_token[:50]}...")
    logger.debug(f"🎫 Full bearer token: {bearer_token}")
    
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {bearer_token}",
    }
    
    logger.info(f"📋 Headers prepared:")
    logger.debug(f"🔍 Content-Type: {headers['Content-Type']}")
    logger.debug(f"🔍 Authorization: Bearer {bearer_token[:50]}...")
    
    logger.info(f"🌐 Connecting to service: {SERVICE_URL}")
    
    try:
        async with websockets.connect(
            SERVICE_URL, 
            extra_headers=headers
        ) as server_websocket:
            logger.info("✅ Connected to Gemini service successfully!")
            
            logger.info("🔄 Creating bidirectional proxy tasks...")
            client_to_server_task = asyncio.create_task(
                proxy_task(client_websocket, server_websocket)
            )
            server_to_client_task = asyncio.create_task(
                proxy_task(server_websocket, client_websocket)
            )
            
            logger.info("⏳ Waiting for proxy tasks to complete...")
            await asyncio.gather(client_to_server_task, server_to_client_task)
            logger.info("✅ Proxy tasks completed")
            
    except websockets.exceptions.InvalidStatusCode as e:
        logger.error(f"❌ WebSocket connection failed with status: {e.status_code}")
        logger.error(f"🔍 Response headers: {e.response_headers}")
        logger.error(f"🔍 Error details: {str(e)}")
        raise
    except websockets.exceptions.ConnectionClosed as e:
        logger.error(f"❌ WebSocket connection closed: {e.code} - {e.reason}")
        raise
    except Exception as e:
        logger.error(f"❌ Unexpected error in create_proxy: {str(e)}")
        logger.error(f"🔍 Error traceback: {traceback.format_exc()}")
        raise


async def handle_client(client_websocket: WebSocketServerProtocol) -> None:
    """
    Handles a new client connection and establishes a proxy connection to the server.

    Args:
        client_websocket: The WebSocket connection of the client.
    """
    client_id = f"{client_websocket.remote_address[0]}:{client_websocket.remote_address[1]}"
    logger.info(f"🔌 New client connection from: {client_id}")
    
    try:
        logger.info(f"🔗 Creating proxy for client: {client_id}")
        await create_proxy(client_websocket)
        logger.info(f"✅ Proxy completed for client: {client_id}")
        
    except Exception as e:
        logger.error(f"❌ Error handling client {client_id}: {str(e)}")
        logger.error(f"🔍 Error traceback: {traceback.format_exc()}")
        
        try:
            await client_websocket.close(code=1011, reason="Internal server error")
            logger.info(f"🔐 Client {client_id} websocket closed with error code")
        except Exception as close_error:
            logger.error(f"❌ Error closing client websocket: {str(close_error)}")


async def main() -> None:
    """
    Starts the WebSocket server and listens for incoming client connections.
    """
    logger.info("🚀 Starting WebSocket server...")
    
    # Initialize authentication
    if not init_auth():
        logger.error("❌ Failed to initialize authentication. Continuing with gcloud fallback.")
    
    logger.info("🌐 Starting server on localhost:8080...")
    
    try:
        async with websockets.serve(handle_client, "localhost", 8080):
            logger.info("✅ WebSocket server running on localhost:8080")
            logger.info("⏳ Waiting for connections...")
            
            # Run forever
            await asyncio.Future()
            
    except Exception as e:
        logger.error(f"❌ Error starting server: {str(e)}")
        logger.error(f"🔍 Error traceback: {traceback.format_exc()}")
        raise


if __name__ == "__main__":
    logger.info("🎬 Starting application...")
    logger.info(f"⏰ Start time: {datetime.now()}")
    
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        logger.info("⛔ Application interrupted by user")
    except Exception as e:
        logger.error(f"❌ Application crashed: {str(e)}")
        logger.error(f"🔍 Error traceback: {traceback.format_exc()}")
    finally:
        logger.info("🏁 Application ended")
