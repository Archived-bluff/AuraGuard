# AuraGuard Doorbell Security System

AuraGuard is a cross-platform smart doorbell security solution powered by AI face detection, Google Cloud integration, and a modern Flutter dashboard. It is designed for enhanced home security and daily review of doorbell activity.

---

## Features

- **AI Face Detection:** Uses OpenCV and face_recognition to detect and identify faces at your door.
- **Suspicious Activity Monitoring:** Records and flags unusual events for review.
- **Cloud Storage & Database:** Automatically uploads images/videos to Google Cloud Storage and logs metadata in Firestore.
- **Flutter Dashboard:** Intuitive UI for reviewing faces, monitoring suspicious activity, and managing user accounts.
- **Multi-Platform:** Runs on Windows, Linux, macOS, Android, and iOS.

---

## Workflow Overview

1. **Monitoring Start:**  
   The backend (FastAPI) starts monitoring when triggered, opening the camera feed and running AI face detection.
2. **Face Detection:**  
   Detected faces are captured, labeled, and sent to Google Cloud Storage. Metadata (timestamp, label, etc.) is stored in Firestore.
3. **Suspicious Activity:**  
   Unusual or unrecognized faces/events are flagged and recorded as short video clips.
4. **Cloud Sync:**  
   All images/videos and their metadata are synced to the cloud for secure storage and later review.
5. **Flutter Dashboard:**  
   The user interacts with the dashboard to:
   - Review and categorize detected faces (Daily Review)
   - Monitor flagged events and recordings (Suspicious Activity)
   - Manage account settings and preferences (User Account)
6. **User Actions:**  
   Users can label faces, mark events as safe/suspicious, and adjust notification or privacy settings.

---

## Project Structure

```
AuraGuard/
├── backend/                # FastAPI backend for monitoring, uploads, and cloud sync
├── flutter_app/            # Flutter dashboard app
│   ├── lib/
│   │   ├── main.dart       # App entry point and dashboard UI
│   │   └── screens/
│   │       ├── daily_review.dart
│   │       ├── suspicious_activity.dart
│   │       └── user_account.dart
│   ├── android/            # Android platform code
│   ├── ios/                # iOS platform code
│   ├── windows/            # Windows platform code
│   ├── linux/              # Linux platform code
│   └── macos/              # macOS platform code
└── README.md
```

---

## Getting Started

### Backend Setup

1. **Install dependencies:**
   ```sh
   cd backend
   pip install -r requirements.txt
   ```
2. **Google Cloud Setup:**
   - Create a Google Cloud project.
   - Enable Firestore and Cloud Storage.
   - Download your `service_account.json` and place it in the backend folder.
3. **Run the backend server:**
   ```sh
   uvicorn main:app --reload
   ```

### Flutter App Setup

1. **Install dependencies:**
   ```sh
   cd flutter_app
   flutter pub get
   ```
2. **Configure Firebase:**
   - Use the Firebase Console to set up your project.
   - Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS).
   - Update `lib/firebase_options.dart` with your Firebase config.
3. **Run the app:**
   ```sh
   flutter run
   ```
   - For desktop: `flutter run -d windows` / `-d linux` / `-d macos`
   - For mobile: `flutter run -d android` / `-d ios`

---

## API Endpoints (Backend)

- `POST /start-monitoring` — Start camera and face detection.
- `POST /stop-monitoring` — Stop monitoring and upload recordings.
- `GET /cloud-faces` — List recent detected faces.
- `GET /cloud-videos` — List recent suspicious activity videos.

---

## Flutter Dashboard Screens

- **Daily Review:**  
  View and categorize faces detected at your door. Mark known/unknown visitors.
- **Suspicious Activity:**  
  Monitor flagged events, watch recordings, and mark events as safe or suspicious.
- **User Account:**  
  Manage your profile, notification preferences, and privacy settings.

---

## Example Workflow

1. Doorbell camera detects a face.
2. Backend analyzes and uploads the image/video to Google Cloud.
3. Metadata is stored in Firestore.
4. User opens the Flutter dashboard:
   - Reviews faces and marks them as known/unknown.
   - Checks suspicious activity and watches flagged recordings.
   - Adjusts account settings as needed.

---

## License

MIT License

---
