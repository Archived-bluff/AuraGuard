from fastapi import FastAPI, HTTPException, Body
from fastapi.middleware.cors import CORSMiddleware
import cv2
import time
import face_recognition
from datetime import datetime
from utils import upload_file_to_gcs, save_face_metadata, save_video_metadata, test_firestore_connection, test_gcs_connection
from gcp_client import firestore_client, storage_client, bucket
import uvicorn
import threading
import os
import tempfile

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Global monitoring control
monitoring_active = False
monitoring_thread = None

# Face detection setup
HAAR_CASCADE_PATH = cv2.data.haarcascades + "haarcascade_frontalface_default.xml"
face_cascade = cv2.CascadeClassifier(HAAR_CASCADE_PATH)

def get_known_face_encodings():
    """Load known faces from cloud storage instead of local files"""
    try:
        # Get all known faces from Firestore where type = "recognised"
        known_faces = []
        docs = firestore_client.collection("faces").where("type", "==", "recognised").stream()
        
        for doc in docs:
            face_data = doc.to_dict()
            # Download image from cloud storage
            blob_name = face_data['url'].split('/')[-1]  # Extract filename from URL
            blob = bucket.blob(f"faces/{blob_name}")
            
            # Download to temporary file
            with tempfile.NamedTemporaryFile(suffix='.jpg', delete=False) as temp_file:
                blob.download_to_filename(temp_file.name)
                
                # Load face encoding
                image = face_recognition.load_image_file(temp_file.name)
                encodings = face_recognition.face_encodings(image)
                
                if encodings:
                    known_faces.append({
                        'encoding': encodings[0],
                        'name': face_data.get('name', 'Unknown'),
                        'id': face_data['faceID']
                    })
                
                # Clean up temp file
                os.unlink(temp_file.name)
        
        print(f"Loaded {len(known_faces)} known faces from cloud")
        return known_faces
        
    except Exception as e:
        print(f"Error loading known faces from cloud: {e}")
        return []

def analyze_face_from_cloud(snapshot_blob_name):
    """Analyze a face snapshot against known faces in cloud"""
    try:
        known_faces = get_known_face_encodings()
        if not known_faces:
            print("No known faces found in cloud")
            return "unrecognised", "Unknown"
        
        # Download the snapshot to analyze
        snapshot_blob = bucket.blob(f"faces/{snapshot_blob_name}")
        with tempfile.NamedTemporaryFile(suffix='.jpg', delete=False) as temp_file:
            snapshot_blob.download_to_filename(temp_file.name)
            
            # Analyze the face
            unknown_image = face_recognition.load_image_file(temp_file.name)
            unknown_encodings = face_recognition.face_encodings(unknown_image)
            
            os.unlink(temp_file.name)  # Clean up
            
            if unknown_encodings:
                unknown_encoding = unknown_encodings[0]
                
                # Compare with known faces
                for known_face in known_faces:
                    results = face_recognition.compare_faces([known_face['encoding']], unknown_encoding, tolerance=0.6)
                    if results[0]:
                        return "recognised", known_face['name']
                
                return "unrecognised", "Unknown"
            else:
                return "unrecognised", "No Face Detected"
                
    except Exception as e:
        print(f"Error in face analysis: {e}")
        return "unrecognised", "Analysis Error"

def monitor_suspicious_activity():
    """Cloud-integrated monitoring with proper video recording"""
    global monitoring_active
    
    SUSPICIOUS_THRESHOLD_SECONDS = 10.0
    NO_FACE_STOP_SECONDS = 3.0

    face_start_time = None
    last_face_seen_time = None
    
    is_recording = False
    recording_start_time = None
    video_writer = None
    face_id = None
    temp_video_path = None
    
    snapshot_taken = False
    event_triggered = False  # New flag to ensure one snapshot per event

    video_capture = cv2.VideoCapture(0)
    
    fps = int(video_capture.get(cv2.CAP_PROP_FPS)) or 20
    width = int(video_capture.get(cv2.CAP_PROP_FRAME_WIDTH))
    height = int(video_capture.get(cv2.CAP_PROP_FRAME_HEIGHT))
    
    print(f"\n=== AuraGuard Cloud Monitoring Started ===")
    print(f"Video resolution: {width}x{height} at {fps} FPS")
    print("All recordings will be saved to Google Cloud Storage")
    print("Face recognition uses cloud-stored known faces")
    print("Press 'q' in camera window to quit")

    while monitoring_active:
        ret, frame = video_capture.read()
        if not ret:
            print("Could not read frame")
            break

        current_time = time.time()
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        faces = face_cascade.detectMultiScale(gray, scaleFactor=1.1, minNeighbors=5, minSize=(30, 30))
        display_frame = frame.copy()

        if len(faces) > 0:
            last_face_seen_time = current_time
            
            if face_start_time is None:
                face_start_time = current_time
                print("👤 Face detected - Starting 10-second timer")
            
            elapsed_time = current_time - face_start_time
            cv2.putText(display_frame, f"Face Detected: {int(elapsed_time)}s", (10, 30),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 0, 255), 2)

            if elapsed_time > SUSPICIOUS_THRESHOLD_SECONDS and not is_recording and not event_triggered:
                event_triggered = True  # ensure only one snapshot per event
                timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
                face_id = f"face_{timestamp}"

                temp_snapshot = tempfile.NamedTemporaryFile(suffix='.jpg', delete=False)
                temp_snapshot.close()
                cv2.imwrite(temp_snapshot.name, frame)

                try:
                    snapshot_url = upload_file_to_gcs(temp_snapshot.name, "faces/unrecognised", f"{face_id}.jpg")
                    face_type, person_name = analyze_face_from_cloud(f"{face_id}.jpg")
                    save_face_metadata(face_id, snapshot_url, person_name, face_type)
                    print(f"📸 Snapshot uploaded: {person_name} ({face_type})")
                except Exception as e:
                    print(f"❌ Snapshot upload failed: {e}")
                finally:
                    try:
                        os.unlink(temp_snapshot.name)
                    except PermissionError:
                        print(f"Warning: Could not delete temp file {temp_snapshot.name}")

                temp_video_path = tempfile.NamedTemporaryFile(suffix='.mp4', delete=False).name
                fourcc = cv2.VideoWriter_fourcc(*'H264')
                video_writer = cv2.VideoWriter(temp_video_path, fourcc, fps, (width, height))

                if video_writer.isOpened():
                    is_recording = True
                    recording_start_time = current_time
                    print(f"🎥 Video recording started: {temp_video_path}")
                else:
                    print("❌ Failed to initialize video writer")

        else:
            if face_start_time is not None and not is_recording:
                face_start_time = None
                snapshot_taken = False
                event_triggered = False

        if is_recording and video_writer is not None:
            video_writer.write(frame)
            cv2.circle(display_frame, (width - 30, 30), 10, (0, 0, 255), -1)
            cv2.putText(display_frame, "REC", (width - 80, 35), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 0, 255), 2)
            
            recording_duration = current_time - recording_start_time
            time_since_last_face = current_time - (last_face_seen_time or current_time)

            should_stop = False
            stop_reason = ""

            if len(faces) == 0 and time_since_last_face > NO_FACE_STOP_SECONDS:
                should_stop = True
                stop_reason = f"no face for {time_since_last_face:.1f}s"
            elif recording_duration > 60:
                should_stop = True
                stop_reason = "maximum duration reached"

            if should_stop:
                print(f"🎬 Stopping recording after {recording_duration:.1f}s ({stop_reason})")
                video_writer.release()
                video_writer = None
                is_recording = False

                try:
                    video_url = upload_file_to_gcs(temp_video_path, "videos", f"{face_id}_video.mp4")
                    save_video_metadata(face_id, video_url, recording_duration)
                    print(f"☁️ Video uploaded successfully: {recording_duration:.1f}s duration")
                except Exception as e:
                    print(f"❌ Video upload failed: {e}")

                try:
                    os.unlink(temp_video_path)
                except:
                    pass

                face_start_time = None
                last_face_seen_time = None
                snapshot_taken = False
                temp_video_path = None
                face_id = None
                event_triggered = False

        for (x, y, w, h) in faces:
            cv2.rectangle(display_frame, (x, y), (x+w, y+h), (0, 255, 0), 2)

        cv2.imshow('AuraGuard - Cloud Security Monitor', display_frame)
        key = cv2.waitKey(1) & 0xFF
        if key == ord('q'):
            monitoring_active = False
            break

    if is_recording and video_writer:
        print("🛑 Cleaning up recording on exit...")
        video_writer.release()
        if temp_video_path and os.path.exists(temp_video_path):
            try:
                video_url = upload_file_to_gcs(temp_video_path, "videos", f"{face_id}_partial.mp4")
                print(f"☁️ Partial recording uploaded on exit")
                os.unlink(temp_video_path)
            except:
                print("❌ Failed to upload partial recording")

    video_capture.release()
    cv2.destroyAllWindows()
    print("=== Monitoring stopped - All data saved to cloud ===")

# API Endpoints
@app.get("/")
def read_root():
    return {"message": "AuraGuard Cloud Backend", "status": "ready"}

@app.get("/test-connections")
def test_connections():
    """Test Firebase and GCS connections"""
    firestore_ok = test_firestore_connection()
    gcs_ok = test_gcs_connection()
    
    return {
        "firestore": "connected" if firestore_ok else "failed",
        "gcs": "connected" if gcs_ok else "failed",
        "overall_status": "ready" if (firestore_ok and gcs_ok) else "connection_issues"
    }

@app.post("/start-monitoring")
def start_monitoring():
    global monitoring_active, monitoring_thread
    
    if monitoring_active:
        return {"message": "Monitoring already active", "status": "running"}
    
    monitoring_active = True
    monitoring_thread = threading.Thread(target=monitor_suspicious_activity)
    monitoring_thread.start()
    
    return {"message": "Cloud monitoring started - Check camera window", "status": "active"}

@app.post("/stop-monitoring")
def stop_monitoring():
    global monitoring_active, monitoring_thread
    
    monitoring_active = False
    if monitoring_thread:
        monitoring_thread.join(timeout=5)
    
    return {"message": "Monitoring stopped - All data saved to cloud", "status": "inactive"}

@app.get("/monitoring-status")
def get_monitoring_status():
    return {"monitoring_active": monitoring_active}

@app.get("/cloud-faces-recognised")
def get_cloud_faces():
    """Get recent faces from cloud storage"""
    try:
        docs = firestore_client.collection("faces").order_by("timestamp", direction="DESCENDING").limit(20).stream()
        faces = []
        for doc in docs:
            face_data = doc.to_dict()
            face_data['id'] = doc.id
            faces.append(face_data)
        return {"faces": faces}
    except Exception as e:
        return {"error": str(e)}

@app.get("/cloud-faces-unrecognised")
def get_unrecognised_faces_from_gcs():
    """Fetch all unrecognised face snapshots directly from GCS"""
    try:
        blobs = storage_client.list_blobs(bucket.name, prefix="faces/unrecognised/")
        faces = []
        for blob in blobs:
            if blob.name.endswith(".jpg") or blob.name.endswith(".png"):
                faces.append({
                    "name": "Unknown",
                    "url": f"https://storage.googleapis.com/{bucket.name}/{blob.name}"
                })
        # Return most recent first
        faces = sorted(faces, key=lambda x: x['url'], reverse=True)
        return {"faces": faces}
    except Exception as e:
        return {"error": str(e)}

@app.get("/cloud-videos-storage")
def cloud_videos_storage():
    """Fetch all videos from GCS"""
    try:
        bucket_name = bucket.name  # aura-guard bucket
        prefix = "videos/"
        blobs = storage_client.list_blobs(bucket_name, prefix=prefix)
        videos = []
        for blob in blobs:
            if not blob.name.endswith('/'):
                videos.append({
                    "name": blob.name.split('/')[-1],
                    "url": blob.public_url
                })
        return {"videos": videos}
    except Exception as e:
        return {"error": str(e)}

@app.post("/move-face")
def move_face(face_url: str = Body(...), target_folder: str = Body(...)):
    """Move face image to another folder in GCS"""
    try:
        # Extract blob name from URL
        blob_name = face_url.split('/')[-1]
        source_blob = bucket.blob(f"faces/unrecognised/{blob_name}")
        destination_blob = bucket.blob(f"faces/{target_folder}/{blob_name}")
        
        # Copy and delete original
        bucket.copy_blob(source_blob, bucket, destination_blob.name)
        source_blob.delete()

        # Optionally, update Firestore metadata if needed
        return {"status": "success", "message": f"Moved to {target_folder}"}
    except Exception as e:
        return {"status": "error", "message": str(e)}
    
@app.post("/delete-face")
def delete_face(body: dict = Body(...)):
    try:
        face_url = body.get("face_url")
        if not face_url:
            return {"status": "error", "message": "Missing face_url"}

        blob_name = face_url.split('/')[-1]
        blob = bucket.blob(f"faces/unrecognised/{blob_name}")
        blob.delete()
        return {"status": "success", "message": "Face deleted"}
    except Exception as e:
        return {"status": "error", "message": str(e)}

@app.get("/cloud-faces-folder/{folder_name}")
def cloud_faces_folder(folder_name: str):
    """
    Fetch all faces from a specific folder in GCS.
    folder_name can be: 'recognised', 'marked', or 'unrecognised'
    """
    try:
        bucket_name = bucket.name
        prefix = f"faces/{folder_name}/"
        blobs = storage_client.list_blobs(bucket_name, prefix=prefix)
        faces = []

        for blob in blobs:
            if not blob.name.endswith('/'):
                faces.append({
                    "name": blob.name.split('/')[-1],
                    "url": blob.public_url
                })

        return {"faces": faces}
    except Exception as e:
        return {"error": str(e)}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)