import json
import os
from google.auth.transport.requests import Request
from google.oauth2 import service_account
import time
import logging

# Set up logging for debugging
logging.basicConfig(level=logging.DEBUG, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class ServiceAccountAuth:
    def __init__(self, credentials_path=None, project_id=None):
        logger.info("🔧 Initializing ServiceAccountAuth...")
        logger.debug(f"📁 Credentials path provided: {credentials_path}")
        logger.debug(f"🏷️ Project ID provided: {project_id}")
        
        self.credentials_path = 'reviewtext-ad5c6-vertex-ai.json'
        self.project_id = project_id or os.getenv('GOOGLE_CLOUD_PROJECT_ID')
        
        logger.info(f"📂 Using credentials file: {self.credentials_path}")
        logger.info(f"🏷️ Using project ID: {self.project_id}")
        logger.debug(f"🌍 GOOGLE_CLOUD_PROJECT_ID env var: {os.getenv('GOOGLE_CLOUD_PROJECT_ID')}")
        
        self.credentials = None
        self.token = None
        self.token_expiry = None
        
        if not self.credentials_path:
            logger.error("❌ Service account credentials path not provided")
            raise ValueError("Service account credentials path not provided")
        
        logger.info("📄 Loading credentials...")
        self._load_credentials()
    
    def _load_credentials(self):
        logger.info(f"🔑 Loading credentials from: {self.credentials_path}")
        
        # Check if file exists
        if not os.path.exists(self.credentials_path):
            logger.error(f"❌ Credentials file does not exist: {self.credentials_path}")
            logger.debug(f"🗂️ Current working directory: {os.getcwd()}")
            logger.debug(f"📋 Files in current directory: {os.listdir('.')}")
            raise FileNotFoundError(f"Service account file not found: {self.credentials_path}")
        
        logger.info(f"✅ Credentials file exists: {self.credentials_path}")
        logger.debug(f"📊 File size: {os.path.getsize(self.credentials_path)} bytes")
        
        try:
            with open(self.credentials_path, 'r') as f:
                credentials_info = json.load(f)
            
            logger.info("✅ JSON credentials loaded successfully")
            logger.debug(f"🔍 Credential keys: {list(credentials_info.keys())}")
            logger.debug(f"📧 Service account email: {credentials_info.get('client_email', 'NOT_FOUND')}")
            logger.debug(f"🆔 Project ID from creds: {credentials_info.get('project_id', 'NOT_FOUND')}")
            
            scopes = ['https://www.googleapis.com/auth/cloud-platform']
            logger.info(f"🎯 Using scopes: {scopes}")
            
            self.credentials = service_account.Credentials.from_service_account_info(
                credentials_info, scopes=scopes
            )
            
            logger.info("✅ Service account credentials created successfully")
            logger.debug(f"🔗 Credentials service account email: {self.credentials.service_account_email}")
            logger.debug(f"🎯 Credentials scopes: {self.credentials.scopes}")
            
        except FileNotFoundError:
            logger.error(f"❌ Service account file not found: {self.credentials_path}")
            raise FileNotFoundError(f"Service account file not found: {self.credentials_path}")
        except json.JSONDecodeError as e:
            logger.error(f"❌ Invalid JSON in service account file: {self.credentials_path}")
            logger.error(f"🔍 JSON error details: {str(e)}")
            raise ValueError(f"Invalid JSON in service account file: {self.credentials_path}")
        except Exception as e:
            logger.error(f"❌ Unexpected error loading credentials: {str(e)}")
            logger.error(f"🔍 Error type: {type(e).__name__}")
            raise
    
    def get_access_token(self):
        logger.info("🎫 Getting access token...")
        
        # Check if we have a valid cached token
        current_time = time.time()
        logger.debug(f"⏰ Current time: {current_time}")
        logger.debug(f"🎫 Current token: {self.token[:50] + '...' if self.token else 'None'}")
        logger.debug(f"⏳ Token expiry: {self.token_expiry}")
        
        if self.token and self.token_expiry and current_time < self.token_expiry:
            logger.info("✅ Using cached valid token")
            logger.debug(f"⏱️ Token expires in: {self.token_expiry - current_time:.2f} seconds")
            logger.info(f"🎫 CACHED TOKEN: {self.token}")
            return self.token
        
        logger.info("🔄 Token expired or not found, refreshing...")
        
        try:
            request = Request()
            logger.debug("📡 Created Request object for token refresh")
            
            logger.info("🔄 Refreshing credentials...")
            self.credentials.refresh(request)
            
            self.token = self.credentials.token
            self.token_expiry = self.credentials.expiry.timestamp() if self.credentials.expiry else None
            
            logger.info("✅ Token refreshed successfully!")
            logger.debug(f"🎫 New token length: {len(self.token) if self.token else 0}")
            logger.debug(f"⏳ New token expiry: {self.token_expiry}")
            logger.debug(f"⏱️ Token valid for: {self.token_expiry - current_time:.2f} seconds" if self.token_expiry else "No expiry set")
            
            # Print the actual token for debugging
            logger.info(f"🎫 NEW ACCESS TOKEN: {self.token}")
            
            return self.token
            
        except Exception as e:
            logger.error(f"❌ Error refreshing token: {str(e)}")
            logger.error(f"🔍 Error type: {type(e).__name__}")
            logger.error(f"🔍 Error details: {repr(e)}")
            raise
    
    def is_token_valid(self):
        logger.info("🔍 Checking token validity...")
        
        if not self.token:
            logger.warning("⚠️ No token available")
            return False
            
        if not self.token_expiry:
            logger.warning("⚠️ No token expiry set")
            return False
            
        current_time = time.time()
        buffer_time = 300  # 5 min buffer
        valid_until = self.token_expiry - buffer_time
        
        logger.debug(f"⏰ Current time: {current_time}")
        logger.debug(f"⏳ Token expiry: {self.token_expiry}")
        logger.debug(f"🛡️ Buffer time: {buffer_time} seconds")
        logger.debug(f"✅ Valid until: {valid_until}")
        logger.debug(f"⏱️ Time remaining: {valid_until - current_time:.2f} seconds")
        
        is_valid = current_time < valid_until
        logger.info(f"🎫 Token valid: {is_valid}")
        
        return is_valid