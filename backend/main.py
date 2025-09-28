from fastapi import FastAPI, HTTPException
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

    # Face detection state
    face_start_time = None
    last_face_seen_time = None
    
    # Recording state
    is_recording = False
    recording_start_time = None
    video_writer = None
    face_id = None
    temp_video_path = None
    
    # Flags
    snapshot_taken = False

    video_capture = cv2.VideoCapture(0)
    
    # Get video properties for recording
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

        # Face detection logic
        if len(faces) > 0:
            # Update last seen time
            last_face_seen_time = current_time
            
            # Start timer if this is first detection
            if face_start_time is None:
                face_start_time = current_time
                print("👤 Face detected - Starting 10-second timer")
            
            elapsed_time = current_time - face_start_time
            timer_text = f"Face Detected: {int(elapsed_time)}s"
            cv2.putText(display_frame, timer_text, (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 0, 255), 2)

            # After 10 seconds: take snapshot and start recording
            if elapsed_time > SUSPICIOUS_THRESHOLD_SECONDS and not is_recording:
                print("🚨 10 seconds elapsed - Taking snapshot and starting recording")
                
                # Generate unique ID
                timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
                face_id = f"face_{timestamp}"
                
                # Take snapshot first
                if not snapshot_taken:
                    temp_snapshot = tempfile.NamedTemporaryFile(suffix='.jpg', delete=False)
                    temp_snapshot.close()  # Close the file handle before using it
                    cv2.imwrite(temp_snapshot.name, frame)
                    
                    try:
                        snapshot_url = upload_file_to_gcs(temp_snapshot.name, "faces", f"{face_id}.jpg")
                        face_type, person_name = analyze_face_from_cloud(f"{face_id}.jpg")
                        save_face_metadata(face_id, snapshot_url, person_name, face_type)
                        print(f"📸 Snapshot uploaded: {person_name} ({face_type})")
                        snapshot_taken = True
                    except Exception as e:
                        print(f"❌ Snapshot upload failed: {e}")
                    finally:
                        try:
                            os.unlink(temp_snapshot.name)
                        except PermissionError:
                            print(f"Warning: Could not delete temp file {temp_snapshot.name}")
                
                # Start video recording
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
            # No face detected
            if face_start_time is not None and not is_recording:
                print("👤 Face lost before 10 seconds - Resetting timer")
                face_start_time = None
                snapshot_taken = False

        # Handle video recording
        if is_recording and video_writer is not None:
            # Write current frame to video
            video_writer.write(frame)
            
            # Show recording indicator
            cv2.circle(display_frame, (width - 30, 30), 10, (0, 0, 255), -1)
            cv2.putText(display_frame, "REC", (width - 80, 35), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 0, 255), 2)
            
            recording_duration = current_time - recording_start_time
            
            # Stop recording if no face for 3+ seconds OR recording too long (safety)
            time_since_last_face = current_time - (last_face_seen_time or current_time)
            
            should_stop = False
            stop_reason = ""
            
            if len(faces) == 0 and time_since_last_face > NO_FACE_STOP_SECONDS:
                should_stop = True
                stop_reason = f"no face for {time_since_last_face:.1f}s"
            elif recording_duration > 60:  # Safety limit: 60 seconds max
                should_stop = True
                stop_reason = "maximum duration reached"
            
            if should_stop:
                print(f"🎬 Stopping recording after {recording_duration:.1f}s ({stop_reason})")
                
                # Stop recording
                video_writer.release()
                video_writer = None
                is_recording = False
                
                # Upload video to cloud
                try:
                    video_url = upload_file_to_gcs(temp_video_path, "videos", f"{face_id}_video.mp4")
                    save_video_metadata(face_id, video_url, recording_duration)
                    print(f"☁️ Video uploaded successfully: {recording_duration:.1f}s duration")
                except Exception as e:
                    print(f"❌ Video upload failed: {e}")
                
                # Clean up temp file
                try:
                    os.unlink(temp_video_path)
                except:
                    pass
                
                # Reset all states
                face_start_time = None
                last_face_seen_time = None
                snapshot_taken = False
                temp_video_path = None
                face_id = None

        # Draw green rectangles around faces
        for (x, y, w, h) in faces:
            cv2.rectangle(display_frame, (x, y), (x+w, y+h), (0, 255, 0), 2)

        # Show camera window
        cv2.imshow('AuraGuard - Cloud Security Monitor', display_frame)

        # Check for quit
        key = cv2.waitKey(1) & 0xFF
        if key == ord('q'):
            monitoring_active = False
            break

    # Cleanup on exit
    if is_recording and video_writer:
        print("🛑 Cleaning up recording on exit...")
        video_writer.release()
        if temp_video_path and os.path.exists(temp_video_path):
            try:
                # Try to upload partial recording
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

@app.get("/cloud-faces")
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

@app.get("/cloud-videos")
def get_cloud_videos():
    """Get recent videos from cloud storage"""
    try:
        docs = firestore_client.collection("videos").order_by("timestamp", direction="DESCENDING").limit(20).stream()
        videos = []
        for doc in docs:
            video_data = doc.to_dict()
            video_data['id'] = doc.id
            videos.append(video_data)
        return {"videos": videos}
    except Exception as e:
        return {"error": str(e)}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)