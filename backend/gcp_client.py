from google.cloud import storage, firestore
import os

# Set up authentication - choose ONE method:
# Method 1: Service account file
os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = "service_account.json"

# Initialize clients
storage_client = storage.Client()
firestore_client = firestore.Client()

# Your bucket configuration
BUCKET_NAME = "aura-guard"
bucket = storage_client.bucket(BUCKET_NAME)

print(f"✅ GCP clients initialized successfully")
print(f"📦 Using bucket: {BUCKET_NAME}")