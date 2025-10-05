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
BUCKET_NAME='aura-guard'

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

def monitor_suspicious_activity():
    """Cloud-integrated monitoring with video recording"""
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

    video_capture = cv2.VideoCapture(0)
    fps = int(video_capture.get(cv2.CAP_PROP_FPS)) or 20
    width = int(video_capture.get(cv2.CAP_PROP_FRAME_WIDTH))
    height = int(video_capture.get(cv2.CAP_PROP_FRAME_HEIGHT))
    
    print(f"\n=== AuraGuard Monitoring Started ===")
    print(f"Video resolution: {width}x{height} at {fps} FPS")

    while monitoring_active:
        ret, frame = video_capture.read()
        if not ret:
            break

        current_time = time.time()
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        faces = face_cascade.detectMultiScale(gray, scaleFactor=1.1, minNeighbors=5, minSize=(30, 30))
        display_frame = frame.copy()

        if len(faces) > 0:
            last_face_seen_time = current_time
            
            if face_start_time is None:
                face_start_time = current_time
                print("Face detected - Starting timer")
            
            elapsed_time = current_time - face_start_time
            cv2.putText(display_frame, f"Face Detected: {int(elapsed_time)}s", (10, 30), 
                       cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 0, 255), 2)

            if elapsed_time > SUSPICIOUS_THRESHOLD_SECONDS and not snapshot_taken:
                timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
                face_id = f"face_{timestamp}"
                
                temp_snapshot = tempfile.NamedTemporaryFile(suffix='.jpg', delete=False)
                temp_snapshot.close()
                cv2.imwrite(temp_snapshot.name, frame)
                
                try:
                    snapshot_url = upload_file_to_gcs(temp_snapshot.name, "faces/unrecognised", f"{face_id}.jpg")
                    print(f"Snapshot uploaded: {face_id}")
                    snapshot_taken = True
                    
                    # Start recording
                    temp_video_path = tempfile.NamedTemporaryFile(suffix='.mp4', delete=False).name
                    fourcc = cv2.VideoWriter_fourcc(*'avc1')
                    video_writer = cv2.VideoWriter(temp_video_path, fourcc, fps, (width, height))
                    
                    if video_writer.isOpened():
                        is_recording = True
                        recording_start_time = current_time
                        print("Recording started")
                
                except Exception as e:
                    print(f"Error: {e}")
                finally:
                    try:
                        os.unlink(temp_snapshot.name)
                    except:
                        pass

        else:
            if face_start_time is not None and not is_recording:
                face_start_time = None
                snapshot_taken = False

        if is_recording and video_writer is not None:
            video_writer.write(frame)
            cv2.circle(display_frame, (width - 30, 30), 10, (0, 0, 255), -1)
            cv2.putText(display_frame, "REC", (width - 80, 35), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 0, 255), 2)
            
            recording_duration = current_time - recording_start_time
            time_since_last_face = current_time - (last_face_seen_time or current_time)
            
            should_stop = False
            if len(faces) == 0 and time_since_last_face > NO_FACE_STOP_SECONDS:
                should_stop = True
            elif recording_duration > 60:
                should_stop = True
            
            if should_stop:
                print(f"Stopping recording after {recording_duration:.1f}s")
                video_writer.release()
                video_writer = None
                is_recording = False
                
                try:
                    video_url = upload_file_to_gcs(temp_video_path, "videos", f"{face_id}_video.mp4")
                    save_video_metadata(face_id, video_url, recording_duration)
                    print(f"Video uploaded")
                except Exception as e:
                    print(f"Upload failed: {e}")
                
                try:
                    os.unlink(temp_video_path)
                except:
                    pass
                
                face_start_time = None
                last_face_seen_time = None
                snapshot_taken = False
                temp_video_path = None
                face_id = None

        for (x, y, w, h) in faces:
            cv2.rectangle(display_frame, (x, y), (x+w, y+h), (0, 255, 0), 2)

        cv2.imshow('AuraGuard Monitor', display_frame)

        if cv2.waitKey(1) & 0xFF == ord('q'):
            monitoring_active = False
            break

    if is_recording and video_writer:
        video_writer.release()
        if temp_video_path and os.path.exists(temp_video_path):
            try:
                upload_file_to_gcs(temp_video_path, "videos", f"{face_id}_partial.mp4")
                os.unlink(temp_video_path)
            except:
                pass
    
    video_capture.release()
    cv2.destroyAllWindows()
    print("=== Monitoring stopped ===")

# API Endpoints
@app.get("/")
def read_root():
    return {"message": "AuraGuard Backend", "status": "ready"}

@app.post("/start-monitoring")
def start_monitoring():
    global monitoring_active, monitoring_thread
    if monitoring_active:
        return {"message": "Already active", "status": "running"}
    monitoring_active = True
    monitoring_thread = threading.Thread(target=monitor_suspicious_activity)
    monitoring_thread.start()
    return {"message": "Monitoring started", "status": "active"}

@app.post("/stop-monitoring")
def stop_monitoring():
    global monitoring_active, monitoring_thread
    monitoring_active = False
    if monitoring_thread:
        monitoring_thread.join(timeout=5)
    return {"message": "Monitoring stopped", "status": "inactive"}

@app.get("/cloud-faces-unrecognised")
def get_unrecognised_faces():
    try:
        blobs = bucket.list_blobs(prefix="faces/unrecognised/")
        faces = []
        for blob in blobs:
            if blob.name.endswith(".jpg"):
                faces.append({
                    "name": blob.name.split("/")[-1],
                    "url": f"https://storage.googleapis.com/{BUCKET_NAME}/{blob.name}"
                })
        return {"faces": faces[::-1]}
    except Exception as e:
        return {"error": str(e)}

@app.get("/cloud-videos-storage")
def get_cloud_videos_storage():
    try:
        blobs = bucket.list_blobs(prefix="videos/")
        videos = []
        for blob in blobs:
            if blob.name.endswith(".mp4"):
                videos.append({
                    "name": blob.name.split("/")[-1],
                    "url": f"https://storage.googleapis.com/{BUCKET_NAME}/{blob.name}"
                })
        return {"videos": videos[::-1]}
    except Exception as e:
        return {"videos": []}

@app.post("/move-face")
def move_face(face_url: str = Body(..., embed=True), target_folder: str = Body(..., embed=True)):
    try:
        if target_folder not in ["recognised", "marked"]:
            raise HTTPException(status_code=400, detail="Invalid folder")
        blob_name = face_url.replace(f"https://storage.googleapis.com/{BUCKET_NAME}/", "")
        source_blob = bucket.blob(blob_name)
        filename = os.path.basename(blob_name)
        dest_path = f"faces/{target_folder}/{filename}"
        dest_blob = bucket.blob(dest_path)
        dest_blob.rewrite(source_blob)
        source_blob.delete()
        return {"message": f"Moved to {target_folder}"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/delete-face")
def delete_face(face_url: str = Body(..., embed=True)):
    try:
        blob_name = face_url.replace(f"https://storage.googleapis.com/{BUCKET_NAME}/", "")
        blob = bucket.blob(blob_name)
        blob.delete()
        return {"message": "Deleted"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/account-stats")
def get_account_stats():
    try:
        recognised_count = sum(1 for blob in bucket.list_blobs(prefix="faces/recognised/") if blob.name.endswith(('.jpg', '.jpeg', '.png')))
        marked_count = sum(1 for blob in bucket.list_blobs(prefix="faces/marked/") if blob.name.endswith(('.jpg', '.jpeg', '.png')))
        unrecognised_count = sum(1 for blob in bucket.list_blobs(prefix="faces/unrecognised/") if blob.name.endswith(('.jpg', '.jpeg', '.png')))
        video_count = sum(1 for blob in bucket.list_blobs(prefix="videos/") if blob.name.endswith('.mp4'))
        return {
            "recognised": recognised_count,
            "marked": marked_count,
            "unrecognised": unrecognised_count,
            "videos": video_count,
            "total_faces": recognised_count + marked_count + unrecognised_count
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/cloud-faces-folder/{folder_name}")
def get_faces_by_folder(folder_name: str):
    """Get faces from recognised or marked folder"""
    try:
        if folder_name not in ["recognised", "marked"]:
            raise HTTPException(status_code=400, detail="Invalid folder")
        
        blobs = bucket.list_blobs(prefix=f"faces/{folder_name}/")
        faces = []
        
        for blob in blobs:
            if blob.name.endswith(('.jpg', '.jpeg', '.png')):
                faces.append({
                    "name": blob.name.split("/")[-1],
                    "url": f"https://storage.googleapis.com/{BUCKET_NAME}/{blob.name}",
                    "folder": folder_name
                })
        
        return {"faces": faces[::-1], "count": len(faces)}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)