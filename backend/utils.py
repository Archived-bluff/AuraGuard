from gcp_client import storage_client, firestore_client, bucket, BUCKET_NAME
from datetime import datetime
from google.cloud import firestore
import traceback
import os

def upload_file_to_gcs(local_path, subfolder, dest_name):
    """Upload file to your aura-guard bucket with subfolder structure"""
    try:
        blob_path = f"{subfolder}/{dest_name}"  # faces/filename.jpg or videos/filename.mp4
        print(f"📤 Uploading {local_path} to gs://{BUCKET_NAME}/{blob_path}")
        
        blob = bucket.blob(blob_path)
        blob.upload_from_filename(local_path)
        
        # Don't call make_public() - construct public URL manually
        public_url = f"https://storage.googleapis.com/{BUCKET_NAME}/{blob_path}"
        
        print(f"✅ Upload successful: {public_url}")
        return public_url
        
    except Exception as e:
        print(f"❌ Upload failed: {e}")
        print(f"Traceback: {traceback.format_exc()}")
        raise e

def save_face_metadata(face_id, gcs_url, name="Unknown", face_type="unrecognised"):
    """Save face metadata matching your Firestore schema"""
    try:
        print(f"💾 Saving face metadata to Firestore: {face_id}")
        
        doc_ref = firestore_client.collection("faces").document(face_id)
        doc_data = {
            "faceID": face_id,
            "name": name,
            "timestamp": firestore.SERVER_TIMESTAMP,  # This creates the proper Firestore timestamp
            "type": face_type,  # "recognised", "unrecognised", or "marked"
            "url": gcs_url
        }
        
        doc_ref.set(doc_data)
        print(f"✅ Face metadata saved: {face_id} ({face_type}) - {name}")
        
    except Exception as e:
        print(f"❌ Failed to save face metadata: {e}")
        print(f"Traceback: {traceback.format_exc()}")
        raise e

def save_video_metadata(face_id, gcs_url, duration_seconds):
    """Save video metadata matching your Firestore schema"""
    try:
        video_id = f"{face_id}_video"
        print(f"🎬 Saving video metadata to Firestore: {video_id}")
        
        doc_ref = firestore_client.collection("videos").document(video_id)
        doc_data = {
            "faceID": face_id,
            "timestamp": firestore.SERVER_TIMESTAMP,
            "url": gcs_url,
            "duration": int(duration_seconds),  # duration in seconds as number
            "videoID": video_id
        }
        
        doc_ref.set(doc_data)
        print(f"✅ Video metadata saved: {video_id}, duration: {duration_seconds}s")
        
    except Exception as e:
        print(f"❌ Failed to save video metadata: {e}")
        print(f"Traceback: {traceback.format_exc()}")
        raise e

def test_firestore_connection():
    """Test if Firestore is working"""
    try:
        # Try to read from faces collection
        docs = firestore_client.collection("faces").limit(1).get()
        print(f"✅ Firestore connection test successful")
        return True
    except Exception as e:
        print(f"❌ Firestore connection test failed: {e}")
        return False

def test_gcs_connection():
    """Test if Google Cloud Storage is working"""
    try:
        # Try to list blobs in bucket
        blobs = list(bucket.list_blobs(max_results=1))
        print(f"✅ Google Cloud Storage connection test successful")
        return True
    except Exception as e:
        print(f"❌ Google Cloud Storage connection test failed: {e}")
        return False