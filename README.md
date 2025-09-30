# AuraGuard: AI-Powered Smart Doorbell Security

AuraGuard is a cross-platform, cloud-integrated smart doorbell security system built for hackathons and rapid prototyping. It combines AI face detection, Google Cloud storage, and a Flutter dashboard for seamless monitoring, review, and management of doorbell activity.

---

## 🚀 Features

- **AI Face Detection:** Real-time detection and recognition using OpenCV and face_recognition.
- **Cloud Storage:** Snapshots and video recordings are uploaded to Google Cloud Storage.
- **Cloud Database:** Metadata for faces and videos is stored in Firestore.
- **Flutter Dashboard:** Modern UI for daily review, suspicious activity, and user account management.
- **Multi-Platform:** Works on Windows, Linux, macOS, Android, and iOS.
- **Interactive Workflow:** Swipe gestures to categorize faces, monitor suspicious activity, and manage trusted/watchlist faces.

---

## 🏗️ Project Structure

```
AuraGuard/
├── backend/                # FastAPI backend (Python)
│   ├── main.py             # Main API and monitoring logic
│   ├── utils.py            # Cloud upload and Firestore helpers
│   └── gcp_client.py       # GCP/Firebase client setup
├── flutter_app/            # Flutter dashboard app
│   ├── lib/
│   │   ├── main.dart       # App entry point and dashboard UI
│   │   └── screens/
│   │       ├── daily_review.dart
│   │       ├── suspicious_activity.dart
│   │       └── user_account.dart
└── README.md
```

---

## 🧠 Workflow Overview

### 1. Monitoring & Detection

- **Start Monitoring:**  
  - User triggers monitoring from the dashboard.
  - Backend opens the camera window (OpenCV).
  - Faces are detected in real-time.
- **Face Detection Logic:**  
  - If a face is detected for >10 seconds:
    - Snapshot is taken and uploaded to cloud.
    - AI face recognition runs against known faces in cloud.
    - Video recording starts (max 60s or until face disappears for 3s).
    - Video is uploaded to cloud and metadata saved.

### 2. Data Storage

- **Snapshots:**  
  - Uploaded to `faces/unrecognised/`, `faces/recognised/`, or `faces/marked/` in GCS.
  - Metadata (faceID, name, timestamp, type, url) saved in Firestore.
- **Videos:**  
  - Uploaded to `videos/` in GCS.
  - Metadata (faceID, videoID, timestamp, url, duration) saved in Firestore.

### 3. Flutter Dashboard

- **Daily Review:**  
  - Shows unrecognised faces.
  - Swipe right: Mark as recognised (trusted).
  - Swipe up: Add to watchlist (marked).
  - Swipe left: Delete.
  - Recent videos are listed and playable.
- **Suspicious Activity:**  
  - Start/stop monitoring.
  - See camera status and features.
  - Trigger face analysis.
- **User Account:**  
  - View profile info.
  - See stats (recognised, watchlist, etc.).
  - Manage trusted/watchlist faces.
  - Access settings, notifications, privacy, help, and logout.

---

## 📝 Major Code Functions

### Backend (`main.py` & `utils.py`)

- **monitor_suspicious_activity():**  
  Main loop for camera monitoring, face detection, snapshot/video recording, and cloud upload.
- **get_known_face_encodings():**  
  Loads known faces from Firestore and GCS for recognition.
- **analyze_face_from_cloud():**  
  Compares a snapshot against known faces for recognition.
- **upload_file_to_gcs():**  
  Uploads files to Google Cloud Storage.
- **save_face_metadata(), save_video_metadata():**  
  Saves metadata to Firestore.
- **API Endpoints:**  
  - `/start-monitoring`, `/stop-monitoring`: Control monitoring.
  - `/cloud-faces`, `/cloud-videos-storage`: List faces/videos.
  - `/cloud-faces-unrecognised`, `/cloud-faces-folder/{folder}`: List faces by category.
  - `/move-face`, `/delete-face`: Move/delete face images.
  - `/account-stats`: Get stats for dashboard.

### Flutter App

- **main.dart:**  
  Entry point, dashboard navigation.
- **daily_review.dart:**  
  - Fetches unrecognised faces and videos.
  - Swipeable card UI for face categorization.
  - Video player for recent recordings.
- **suspicious_activity.dart:**  
  - Start/stop monitoring.
  - Shows camera status and features.
  - Triggers backend analysis.
- **user_account.dart:**  
  - Displays user info and stats.
  - Lists recognised and marked faces.
  - Allows face removal.
  - Settings, notifications, privacy, help, and logout options.

---

## 🌐 API Reference

| Endpoint                        | Method | Description                                  |
|----------------------------------|--------|----------------------------------------------|
| `/start-monitoring`              | POST   | Start camera monitoring                      |
| `/stop-monitoring`               | POST   | Stop monitoring and upload recordings        |
| `/cloud-faces`                   | GET    | List recent faces (all types)                |
| `/cloud-faces-unrecognised`      | GET    | List unrecognised faces                      |
| `/cloud-faces-folder/{folder}`   | GET    | List faces by folder (recognised/marked)     |
| `/cloud-videos-storage`          | GET    | List recent videos                           |
| `/move-face`                     | POST   | Move face to recognised/marked               |
| `/delete-face`                   | POST   | Delete face image                            |
| `/account-stats`                 | GET    | Get dashboard stats                          |

---

## ⚡ Setup Instructions

### 1. Google Cloud & Firebase

- Create a Google Cloud project.
- Enable Firestore and Cloud Storage.
- Download `service_account.json` and place in `backend/`.
- Set up Firebase for your Flutter app and update `firebase_options.dart`.

### 2. Backend (Python)

```sh
cd backend
pip install -r requirements.txt
uvicorn main:app --reload
```

### 3. Flutter App

```sh
cd flutter_app
flutter pub get
flutter run
```
- For desktop: `flutter run -d windows` / `-d linux` / `-d macos`
- For mobile: `flutter run -d android` / `-d ios`

---

## 🏆 Future Scope

- **Extensibility:**  
  - Enable SOS mode for suspicious activity from 'marked' individuals.
  - Integrate with smart home devices.
  - Enhance privacy controls and user settings.

---

## 📚 Additional Notes

- **CORS:** Backend allows all origins for easy local testing.
- **Face Recognition:** Uses cloud-stored images for matching, not local files.
- **Video Encoding:** Uses H264 for compatibility.
- **Error Handling:** Most endpoints return clear error messages for debugging.
- **Security:** For hackathon/demo, public URLs are used; in production, restrict access.

## 📝 License

MIT License

---

AuraGuard was built for rapid prototyping and hackathon innovation. For questions or improvements, see code comments or reach out to the team!
