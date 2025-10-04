# AuraGuard: AI-Powered Smart Doorbell Security
### 🏆 Built for Samsung Innovation Hackathon 2025

AuraGuard is a premium AI-powered security layer for Samsung's FamilyHub™ and Doorbell ecosystem. By combining advanced face recognition, cloud intelligence, and seamless Samsung device integration, AuraGuard transforms your doorbell into a proactive security command center.

---

## 🎯 The Problem We're Solving

**Home AI & Smart Automation Challenge**: While smart doorbells can capture footage, they lack intelligent threat assessment and proactive response capabilities. Homeowners face:

- **Alert Fatigue**: Too many notifications for harmless visitors
- **Delayed Response**: Manual review after incidents occur
- **Disconnected Systems**: Security data trapped in isolated apps
- **Limited Automation**: No intelligent escalation for genuine threats

**AuraGuard's Solution**: Transform passive recording into active, intelligent security that categorizes visitors, prioritizes alerts, and integrates seamlessly with Samsung's ecosystem for automated threat response.

---

## 💡 Innovation Highlights

### 🎤 **Bixby Voice Control Integration**
Hands-free commands to mark/unmark faces, review flagged activity, request live feed playback, and trigger SOS alerts—perfect for when users are busy or away from their phone.

### 🔒 **SmartThings Security+ Premium Tier**
Opens a new revenue stream with extended cloud storage, AI-generated security summaries, priority alerts for recurring "marked" faces, and family sharing features.

### 🏠 **Samsung Ecosystem Advantage**
Unmatched integration across Samsung's Family Hub fridge displays, Galaxy devices, wearables, and Smart TVs. Competitors can't match this seamless cross-device experience.

### 📦 **Boosted Hardware Bundles**
Makes Family Hub + Doorbell packages more attractive by adding compelling AI features, supporting appliance upsells and strengthening brand stickiness.

### 🌐 **Smart Alert Mode with Auto-Escalation**
When suspicious behavior persists (marked individual loitering near the door for over 1 minute), the system auto-activates live feed streaming across Samsung devices and prompts immediate SOS activation—turning passive monitoring into active protection.

---

## 🚀 Key Features

| Feature | Description |
|---------|-------------|
| **AI Face Detection** | Real-time detection and recognition using OpenCV and face_recognition library |
| **Intelligent Categorization** | Instantly tags visitors as Recognised, Unrecognised, or Marked (watchlist) |
| **Cloud-Powered Storage** | Snapshots and videos uploaded to Google Cloud Storage |
| **Local Metadata Database** | Fast JSON-based storage for face and video metadata (production-ready Firestore migration planned) |
| **Flutter Dashboard** | Modern cross-platform UI for Samsung Galaxy devices and Family Hub displays |
| **Bixby Voice Commands** | Control security features hands-free via Samsung's voice assistant |
| **SmartThings Integration** | Auto-triggers alerts and live feeds across Samsung smart home devices |
| **Smart Alert Mode** | Auto-escalates to SOS when marked individuals persist near your door |
| **Timed Tracking** | Extended monitoring for flagged individuals with privacy-compliant auto-deletion |
| **Multi-Platform** | Works on Windows, Linux, macOS, Android, and iOS for development/testing |

---

## 🏗️ System Architecture

```
┌──────────────────┐       ┌──────────────────┐       ┌──────────────────┐
│  Samsung Family  │──────▶│   AI Detection   │──────▶│  Google Cloud    │
│  Hub™ Doorbell   │ Video │ (OpenCV + FR)    │ Data  │  Storage (GCS)   │
└──────────────────┘       └──────────────────┘       └──────────────────┘
                                    │                           │
                                    │                           │
                                    ▼                           ▼
                           ┌──────────────────┐       ┌──────────────────┐
                           │  FastAPI Backend │◀──────│ Flutter Dashboard│
                           │  + JSON Metadata │  API  │ (Samsung Devices)│
                           └──────────────────┘       └──────────────────┘
                                    │
                                    ▼
                           ┌──────────────────┐
                           │   SmartThings    │
                           │   Security+ API  │
                           └──────────────────┘
```

**See full workflow diagram above for detailed data flow.**

---

## 📂 Project Structure

```
AuraGuard/
├── backend/                # FastAPI backend (Python)
│   ├── main.py             # Main API and monitoring logic
│   ├── utils.py            # Cloud upload and metadata helpers
│   ├── gcp_client.py       # GCP client setup
│   ├── metadata/           # JSON metadata storage
│   │   ├── faces.json      # Face metadata
│   │   └── videos.json     # Video metadata
│   └── requirements.txt    # Python dependencies
├── flutter_app/            # Flutter dashboard app
│   ├── lib/
│   │   ├── main.dart       # App entry point and dashboard UI
│   │   └── screens/
│   │       ├── daily_review.dart
│   │       ├── suspicious_activity.dart
│   │       └── user_account.dart
│   └── pubspec.yaml
├── assets/                 # Screenshots and demo media
└── README.md
```

---

## 🧠 How It Works

### 1️⃣ **Monitoring & Detection**
- User starts monitoring from Flutter dashboard or via Bixby voice command
- Backend captures video feed from Samsung FamilyHub™ Doorbell
- AI continuously scans for human faces using OpenCV

### 2️⃣ **Smart Recognition**
- When a face is detected for **>10 seconds**:
  - Snapshot captured and uploaded to Google Cloud Storage
  - AI compares against known faces in Firestore database
  - Face categorized as: **Recognised** (trusted), **Unrecognised** (new), or **Marked** (watchlist)
  - Video recording begins (max 60s or until face disappears for 3s)

### 3️⃣ **Cloud Storage & Metadata**
- **Snapshots**: Stored in `faces/recognised/`, `faces/unrecognised/`, or `faces/marked/` on GCS
- **Videos**: Stored in `videos/` folder with H264 encoding
- **Metadata**: Face IDs, timestamps, URLs, and durations saved to local JSON files (`metadata/faces.json` and `metadata/videos.json`)
- Real-time sync to Flutter dashboard across all Samsung devices

### 4️⃣ **Interactive Dashboard**
- **Daily Review**: Swipe right (mark as trusted), swipe up (add to watchlist), swipe left (delete)
- **Suspicious Activity**: Monitor camera status, start/stop recording, trigger manual analysis
- **User Account**: View stats, manage trusted/watchlist faces, adjust settings
- **Bixby Integration**: Voice commands for hands-free control

### 5️⃣ **Smart Alert Mode (SOS Auto-Escalation)**
- If a **Marked** individual persists near the door for **>1 minute**:
  - System auto-activates live feed streaming across Samsung Galaxy devices, Smart TVs, and Family Hub displays
  - Prompts immediate SOS alert with option to contact emergency services
  - Perfect for identifying suspicious loiterers or unwanted visitors

---

## 📝 Core Backend Functions

| Function | Purpose |
|----------|---------|
| `monitor_suspicious_activity()` | Main loop for camera monitoring, face detection, snapshot/video recording |
| `get_known_face_encodings()` | Loads known faces from local JSON metadata and GCS for recognition |
| `analyze_face_from_cloud()` | Compares snapshots against cloud-stored faces for matching |
| `upload_file_to_gcs()` | Uploads files to Google Cloud Storage with automatic path management |
| `save_face_metadata()` | Saves face information to JSON file (faceID, name, type, timestamp, URL) |
| `save_video_metadata()` | Saves video metadata to JSON file (videoID, faceID, duration, URL) |
| `load_metadata()` | Reads JSON metadata files for face and video information | to Firestore (faceID, name, type, timestamp, URL) |
| `save_video_metadata()` | Saves video metadata to Firestore (videoID, faceID, duration, URL) |

---

## 🌐 API Reference

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/start-monitoring` | POST | Start camera monitoring and face detection |
| `/stop-monitoring` | POST | Stop monitoring and upload all recordings |
| `/cloud-faces` | GET | List recent faces (all types) |
| `/cloud-faces-unrecognised` | GET | List unrecognised faces for review |
| `/cloud-faces-folder/{folder}` | GET | List faces by folder (recognised/marked) |
| `/cloud-videos-storage` | GET | List recent videos with metadata |
| `/move-face` | POST | Move face to recognised/marked category |
| `/delete-face` | POST | Delete face image and metadata |
| `/account-stats` | GET | Get dashboard statistics (counts by category) |

---

## ⚡ Setup Instructions

### Prerequisites
- **Python**: 3.8+ (recommended: 3.10)
- **Flutter**: 3.10+ (for cross-platform dashboard)
- **Google Cloud Account**: With Firestore and Cloud Storage enabled
- **Samsung Account**: For SmartThings and Bixby integration (optional for testing)
- **Webcam/Camera**: For doorbell simulation during development

### 1. Google Cloud & Firebase Setup
```bash
# 1. Create a Google Cloud project at https://console.cloud.google.com
# 2. Enable Firestore Database and Cloud Storage
# 3. Create a service account and download service_account.json
# 4. Place service_account.json in backend/ directory
# 5. Set up Firebase for Flutter and update firebase_options.dart
```

### 2. Backend Setup (Python)
```bash
cd backend
pip install -r requirements.txt

# Start the FastAPI server
uvicorn main:app --reload

# Server runs at http://localhost:8000
# API docs available at http://localhost:8000/docs
```

**requirements.txt**:
```
opencv-python
dlib
face_recognition
google-cloud-storage
firebase-admin
fastapi
uvicorn
python-multipart
```

### 3. Flutter App Setup
```bash
cd flutter_app
flutter pub get

# Run on desktop (for testing)
flutter run -d windows  # or -d linux / -d macos

# Run on mobile devices
flutter run -d android  # or -d ios

# Build for production
flutter build apk  # Android
flutter build ios  # iOS
```

### 4. Testing the System
1. Start backend server: `uvicorn main:app --reload`
2. Launch Flutter app on Samsung Galaxy device or emulator
3. Navigate to "Suspicious Activity" tab
4. Click "Start Monitoring"
5. Backend opens camera window—show your face for 10+ seconds
6. Check "Daily Review" tab to see detected faces
7. Swipe to categorize faces and test workflow

---

## 🎬 Demo Instructions for Judges

### Quick Start (5 minutes)
1. **Clone the repository**: `git clone [your-repo-url]`
2. **Backend**: 
   ```bash
   cd backend
   pip install -r requirements.txt
   uvicorn main:app --reload
   ```
3. **Flutter**: 
   ```bash
   cd flutter_app
   flutter run -d [your-device]
   ```
4. **Test Workflow**:
   - Open app → Suspicious Activity → Start Monitoring
   - Face camera for 10+ seconds
   - Check Daily Review for detected faces
   - Swipe to categorize

### Live Demo Scenarios
1. **Scenario A**: Unknown visitor → Unrecognised face → Swipe right to mark as trusted
2. **Scenario B**: Suspicious person → Swipe up to add to watchlist → System triggers alert mode
3. **Scenario C**: Bixby voice command → "Hey Bixby, show me today's flagged activity"
4. **Scenario D**: Marked face persists 60+ seconds → Auto-escalation to SOS mode

### Demo Credentials (if applicable)
- **Backend URL**: `http://localhost:8000` (local testing)
- **Firebase Project**: [Your project ID]
- **Test Accounts**: [If you've set up demo accounts]

---

## 🏆 Samsung Hackathon Alignment

### Integration with Samsung Ecosystem
✅ **FamilyHub™ Doorbell**: Primary hardware integration point  
✅ **SmartThings API**: Auto-escalation for smart home security  
✅ **Bixby Voice**: Hands-free security management  
✅ **Galaxy Devices**: Cross-device dashboard synchronization  
✅ **Knox Security**: Encrypted face data storage (future roadmap)

### Revenue & Market Impact
- **Premium Subscription Model**: SmartThings Security+ tier unlocks AI features
- **Hardware Bundle Boost**: Makes Family Hub + Doorbell packages more compelling
- **Customer Retention**: Sticky features drive long-term Samsung ecosystem loyalty
- **Competitive Moat**: Integration depth competitors can't replicate

---

## 💪 Challenges We Overcame

### 🌩️ **First-Time Google Cloud Integration**
This was our team's first experience with Google Cloud Platform. Setting up Cloud Storage, Firestore, and service account authentication from scratch required diving deep into GCP documentation and understanding IAM roles, bucket permissions, and Firebase Admin SDK initialization. While we successfully implemented GCS for media storage, Firestore integration is still being debugged for the live demo.

### ⚙️ **Dependency Hell: The Version Compatibility Nightmare**
We faced significant compatibility issues between libraries:
- **OpenCV vs dlib**: Different Python versions required for optimal performance
- **face_recognition vs Firebase Admin SDK**: Conflicting dependencies on protobuf versions
- **Flutter packages**: Firebase plugins had breaking changes between versions
- **Solution**: Created isolated virtual environments, pinned exact versions in requirements.txt, and extensively tested on multiple Python versions (3.8, 3.9, 3.10) to find the sweet spot

### 🔄 **Real-Time Face Detection Performance**
Balancing detection accuracy with processing speed was tricky. Initial implementations caused significant lag and dropped frames. We optimized by:
- Reducing frame resolution for detection (while keeping original for recording)
- Implementing face detection cooldowns to prevent redundant processing
- Using threading to separate video capture from face recognition

### 🎨 **Cross-Platform Flutter Responsiveness**
Making the dashboard work seamlessly on desktop (Family Hub displays) and mobile (Galaxy devices) required adaptive layouts, proper state management, and handling different screen aspect ratios without compromising UX.

---

## 🎓 What We Learned

### 📚 **Documentation + StackOverflow > AI**
While AI tools helped with boilerplate code, nothing beat reading official documentation for Google Cloud, Firebase, and face_recognition library. StackOverflow was invaluable for solving obscure dependency conflicts and understanding edge cases that AI couldn't anticipate.

### 🧩 **Understanding the Full Stack**
We gained deep insight into how different technologies connect:
- **Backend-Cloud Communication**: How FastAPI endpoints trigger GCS uploads and Firestore writes
- **Flutter-Backend Integration**: RESTful API design patterns and async data fetching
- **CV Pipeline**: How OpenCV captures frames → dlib detects faces → face_recognition encodes features → cloud storage persists data
- **State Management**: How Flutter's provider pattern keeps UI synced with backend state changes

### 🎨 **UI/UX Design Principles**
- **Gestural Interfaces**: Swipe interactions reduce cognitive load compared to button-heavy UIs
- **Visual Feedback**: Loading states, success animations, and error messages are critical for user trust
- **Information Hierarchy**: Dashboard should show critical info (suspicious activity) prominently, with secondary features (settings) nested deeper
- **Accessibility**: Color contrast, font sizes, and touch target sizes matter for real-world usage

### 🔐 **Privacy-First Development**
We learned to think about data lifecycle from the start:
- What data do we really need to store?
- How long should we retain unrecognised faces?
- What happens when users delete their account?
- How do we communicate data usage transparently?

### ⚡ **Rapid Prototyping Best Practices**
- **Start Simple**: Get core functionality (face detection + storage) working before adding features
- **Modular Architecture**: Separate concerns (detection, storage, API, UI) made debugging easier
- **Version Control**: Frequent commits with descriptive messages saved us when things broke
- **Testing on Real Hardware**: Emulators don't capture camera quirks; testing on actual Galaxy devices revealed performance bottlenecks we wouldn't have found otherwise

### 🤝 **Team Collaboration**
- **Clear Communication**: Daily standups kept everyone aligned despite working on different modules
- **Code Reviews**: Catching bugs early and sharing knowledge across the team
- **Division of Labor**: Frontend/backend/cloud specialists allowed parallel development without blocking each other

---

## 🚧 Future Roadmap

### Phase 1 (Post-Hackathon)
- [ ] Samsung Knox integration for encrypted face storage
- [ ] Tizen OS support for Family Hub refrigerator displays
- [ ] Multi-user family accounts with role-based permissions

### Phase 2 (Premium Features)
- [ ] AI-generated daily security summaries (SmartThings Security+)
- [ ] Integration with Samsung SmartCam for multi-angle monitoring
- [ ] Geofencing: Auto-activate monitoring when family leaves home

### Phase 3 (Ecosystem Expansion)
- [ ] Galaxy Watch alerts for instant threat notifications
- [ ] Smart TV dashboard for whole-home monitoring
- [ ] Community safety features (anonymized threat sharing within neighborhoods)

---

## 📸 Screenshots

*[Add your Flutter app screenshots here]*

- Daily Review screen with swipeable face cards
- Suspicious Activity monitoring dashboard
- User Account with face management
- Bixby voice command interface

---

## 🛡️ Privacy & Security

- **Data Encryption**: All face data encrypted in transit and at rest (GCS)
- **User Consent**: Clear opt-in for face recognition during onboarding
- **Data Retention**: Unrecognised faces auto-deleted after 30 days
- **Local Processing**: Face detection runs locally; only encodings sent to cloud
- **GDPR Compliance**: Built-in data export and deletion tools

---

##
