# Smart Parking System (SmartPS)

An AI-powered smart parking system featuring **license plate recognition (LPR)** using PaddleOCR, a **FastAPI backend** with real-time parking management, and a polished **Flutter mobile app** for reservations and plate scanning.

---

## Table of Contents

- [Features](#features)
- [Architecture](#architecture)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Installation Guide](#installation-guide)
  - [1. Installing Python](#1-installing-python)
  - [2. Installing Flutter SDK](#2-installing-flutter-sdk)
  - [3. Setting Up Android Studio](#3-setting-up-android-studio)
  - [4. Setting Up the Backend](#4-setting-up-the-backend)
  - [5. Setting Up the Mobile App](#5-setting-up-the-mobile-app)
- [Running the Application](#running-the-application)
- [API Documentation](#api-documentation)
- [Screenshots](#screenshots)
- [License](#license)

---

## Features

### Backend (AI + API)
- **License Plate Recognition** using PaddleOCR (PP-OCRv5) with 90-97% accuracy on mobile phone images
- **REST API** with 24 endpoints built on FastAPI
- **JWT Authentication** (register, login, token-based auth)
- **Real-time parking availability** tracking
- **Reservation management** with conflict checking
- **WebSocket** support for live updates
- **SQLite** database (easily switchable to PostgreSQL)
- **In-memory caching** (Redis-compatible fallback)
- **Swagger UI** auto-generated API docs at `/docs`

### Mobile App (Flutter)
- **Material 3** design with Google Fonts (Inter)
- **Login / Register** screens with form validation
- **Home dashboard** with live parking stats
- **Parking map** with color-coded spot grid
- **License plate scanner** - capture via camera or gallery
- **Reservation booking** with time picker
- **Reservation history** with cost tracking
- **Profile** management
- **Riverpod** state management
- **GoRouter** navigation with auth guards

---

## Architecture

```
┌─────────────────────────────────────────────────────┐
│              Mobile App (Flutter)                    │
│  ┌──────────┐  ┌──────────┐  ┌───────────┐          │
│  │ Camera   │  │ Reserv.  │  │ Real-time │          │
│  │ + OCR UI │  │ Booking  │  │ Avail.    │          │
│  └────┬─────┘  └────┬─────┘  └─────┬─────┘          │
└───────┼─────────────┼──────────────┼────────────────┘
        │  REST API   │  REST API    │  WebSocket
        ▼             ▼              ▼
┌─────────────────────────────────────────────────────┐
│           Backend (FastAPI + Python)                 │
│  ┌──────────┐  ┌──────────┐  ┌───────────┐          │
│  │ PaddleOCR│  │ Reserv.  │  │  Parking  │          │
│  │ LPR Svc  │  │ Service  │  │  Service  │          │
│  └────┬─────┘  └────┬─────┘  └─────┬─────┘          │
└───────┼─────────────┼──────────────┼────────────────┘
        ▼             ▼              ▼
┌─────────────────────────────────────────────────────┐
│        SQLite (dev) / PostgreSQL (prod)              │
│        In-Memory Cache / Redis                       │
└─────────────────────────────────────────────────────┘
```

### OCR Flow

```
1. User opens "Scan Plate" in Flutter app
2. Camera captures license plate image
3. Image sent to POST /api/ocr/recognize (multipart)
4. Backend: PaddleOCR detects & reads plate text
5. Returns plate number + confidence score (>85% threshold)
6. User confirms → triggers entry/exit or reservation
```

---

## Tech Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| Backend | Python 3.13 / FastAPI | REST API + WebSocket server |
| AI/OCR | PaddleOCR (PP-OCRv5) | License plate text recognition |
| Database | SQLite / PostgreSQL | Persistent storage |
| Cache | In-Memory / Redis | Real-time availability |
| Mobile | Flutter 3.x (Dart) | Cross-platform mobile app |
| State | Riverpod | State management |
| Nav | GoRouter | Declarative routing |
| HTTP | Dio | HTTP client |
| Camera | image_picker | Camera/gallery capture |

---

## Project Structure

```
Smart-Parking-System/
├── backend/
│   ├── app/
│   │   ├── main.py              # FastAPI app entry point
│   │   ├── config.py            # Settings & environment variables
│   │   ├── database.py          # DB connection & session
│   │   ├── models/              # SQLAlchemy ORM models
│   │   │   ├── user.py
│   │   │   ├── parking.py
│   │   │   ├── vehicle.py
│   │   │   └── reservation.py
│   │   ├── schemas/             # Pydantic request/response schemas
│   │   │   ├── user.py
│   │   │   ├── parking.py
│   │   │   ├── vehicle.py
│   │   │   └── reservation.py
│   │   ├── routers/             # API endpoint handlers
│   │   │   ├── auth.py          # /api/auth/* (register, login, me)
│   │   │   ├── parking.py       # /api/parking/* (spots, stats, lot)
│   │   │   ├── ocr.py           # /api/ocr/* (recognize, entry, exit)
│   │   │   ├── reservation.py   # /api/reservations/*
│   │   │   └── ws.py            # /ws/parking (WebSocket)
│   │   ├── services/            # Business logic
│   │   │   ├── parking_service.py
│   │   │   ├── reservation_service.py
│   │   │   └── cache_service.py
│   │   └── utils/
│   │       ├── security.py      # JWT, password hashing
│   │       └── image_utils.py   # Image preprocessing
│   ├── alembic/                 # DB migrations
│   ├── tests/                   # Unit tests
│   ├── requirements.txt         # Python dependencies
│   ├── alembic.ini              # Alembic config
│   └── .env.example             # Environment template
│
├── mobile/
│   ├── lib/
│   │   ├── main.dart            # App entry point
│   │   ├── config/
│   │   │   ├── api_config.dart  # API base URL
│   │   │   ├── router.dart      # GoRouter configuration
│   │   │   └── theme.dart       # Material 3 theme
│   │   ├── models/              # Data models
│   │   │   ├── user.dart
│   │   │   ├── parking_spot.dart
│   │   │   └── reservation.dart
│   │   ├── services/
│   │   │   └── api_service.dart # HTTP client (Dio)
│   │   ├── providers/           # Riverpod state
│   │   │   ├── auth_provider.dart
│   │   │   └── parking_provider.dart
│   │   ├── screens/
│   │   │   ├── splash_screen.dart
│   │   │   ├── auth/
│   │   │   │   ├── login_screen.dart
│   │   │   │   └── register_screen.dart
│   │   │   ├── home/
│   │   │   │   ├── home_screen.dart
│   │   │   │   └── parking_map_screen.dart
│   │   │   ├── camera/
│   │   │   │   └── plate_scan_screen.dart
│   │   │   ├── reservation/
│   │   │   │   ├── reservation_screen.dart
│   │   │   │   └── reservation_history_screen.dart
│   │   │   └── profile/
│   │   │       └── profile_screen.dart
│   │   └── widgets/             # Reusable widgets
│   ├── android/                 # Android platform files
│   ├── ios/                     # iOS platform files
│   └── pubspec.yaml             # Flutter dependencies
│
├── .gitignore
└── README.md
```

---

## Prerequisites

Before you begin, ensure you have the following installed:

| Requirement | Version | Purpose |
|-------------|---------|---------|
| **Python** | 3.10+ (3.13 recommended) | Backend runtime |
| **pip** | Latest | Python package manager |
| **Flutter SDK** | 3.x | Mobile app framework |
| **Android Studio** | Latest | Android emulator & IDE |
| **Git** | Latest | Version control |

---

## Installation Guide

### 1. Installing Python

#### Windows

1. Download Python from [python.org](https://www.python.org/downloads/)
2. Run the installer
3. **IMPORTANT**: Check **"Add Python to PATH"** during installation
4. Click "Install Now"
5. Verify installation:
   ```bash
   python --version
   # Should output: Python 3.13.x
   ```

#### macOS

```bash
# Using Homebrew
brew install python@3.13

# Verify
python3 --version
```

#### Linux (Ubuntu/Debian)

```bash
sudo apt update
sudo apt install python3 python3-pip python3-venv

# Verify
python3 --version
```

---

### 2. Installing Flutter SDK

#### Step 1: Download Flutter

1. Go to [flutter.dev/docs/get-started/install](https://flutter.dev/docs/get-started/install)
2. Select your operating system (Windows / macOS / Linux)
3. Download the Flutter SDK `.zip` file

#### Step 2: Extract Flutter

**Windows:**
```
1. Create folder: C:\src\flutter
2. Extract the zip contents into C:\src\flutter
3. The result should be: C:\src\flutter\bin\flutter.bat
```

**macOS/Linux:**
```bash
cd ~/development
unzip ~/Downloads/flutter_*.zip
```

#### Step 3: Add Flutter to PATH

**Windows:**
1. Search "Environment Variables" in Start Menu
2. Click "Environment Variables" button
3. Under "User variables", select `Path` → click "Edit"
4. Click "New" and add: `C:\src\flutter\bin`
5. Click OK on all dialogs
6. **Restart your terminal/PowerShell**

**macOS:**
```bash
echo 'export PATH="$HOME/development/flutter/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

**Linux:**
```bash
echo 'export PATH="$HOME/development/flutter/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

#### Step 4: Verify Flutter Installation

```bash
flutter --version
# Should output: Flutter 3.x.x

flutter doctor
# Check for any issues - resolve them before proceeding
```

#### Step 5: Accept Android Licenses

```bash
flutter doctor --android-licenses
# Type 'y' to accept all licenses
```

---

### 3. Setting Up Android Studio

#### Step 1: Install Android Studio

1. Download from [developer.android.com/studio](https://developer.android.com/studio)
2. Run the installer with default settings
3. On first launch, select **"Standard"** installation type
4. Accept all license agreements
5. Wait for the SDK and tools to download

#### Step 2: Install Flutter & Dart Plugins

1. Open Android Studio
2. Go to **File → Settings** (or **Android Studio → Preferences** on macOS)
3. Navigate to **Plugins**
4. Search for **"Flutter"** and click **Install**
5. The Dart plugin will be installed automatically
6. Click **Restart IDE**

#### Step 3: Set Up an Android Emulator

1. Open Android Studio
2. Go to **Tools → Device Manager** (or **AVD Manager**)
3. Click **Create Device**
4. Select **Phone** category → choose **Pixel 7** (or any device)
5. Click **Next**
6. Download a system image (e.g., **API 34** / Android 14) if not already downloaded
7. Select the downloaded image → click **Next**
8. Name your AVD → click **Finish**
9. Click the **Play** button to launch the emulator

#### Step 4: Verify Android Setup

```bash
flutter doctor
# Should show green checkmarks for:
# - Flutter
# - Android toolchain
# - Android Studio
```

---

### 4. Setting Up the Backend

#### Step 1: Clone the Repository

```bash
git clone https://github.com/AnirudhMKumar/Smart-Parking-System.git
cd Smart-Parking-System
```

#### Step 2: Create Virtual Environment

```bash
# Navigate to backend directory
cd backend

# Create virtual environment
python -m venv .venv

# Activate virtual environment
# Windows:
.venv\Scripts\activate
# macOS/Linux:
source .venv/bin/activate
```

#### Step 3: Install Dependencies

```bash
pip install -r requirements.txt
```

> **Note**: PaddleOCR will download AI models on first run (~200MB). This is a one-time download.

#### Step 4: Create Environment File (Optional)

```bash
# Copy the example environment file
cp .env.example .env

# Edit .env with your preferred settings
# Default settings work out of the box with SQLite
```

#### Step 5: Start the Backend Server

```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

The server will start and create the SQLite database automatically.

**Verify it's running:**
- Health check: http://localhost:8000/
- API docs: http://localhost:8000/docs

---

### 5. Setting Up the Mobile App

#### Step 1: Navigate to Mobile Directory

```bash
cd mobile
```

#### Step 2: Get Flutter Dependencies

```bash
flutter pub get
```

#### Step 3: Configure API URL

Edit `mobile/lib/config/api_config.dart`:

```dart
class ApiConfig {
  // For Android Emulator (default)
  static const String baseUrl = 'http://10.0.2.2:8000';
  
  // For iOS Simulator
  // static const String baseUrl = 'http://localhost:8000';
  
  // For Physical Device (replace with your PC's IP)
  // static const String baseUrl = 'http://192.168.1.100:8000';
}
```

#### Step 4: Run the App

```bash
# Make sure Android emulator is running, then:
flutter run
```

Or open the `mobile/` folder in Android Studio and click the **Run** button.

---

## Running the Application

### Quick Start (Windows)

**Terminal 1 - Start Backend:**
```bash
cd backend
.venv\Scripts\activate
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

**Terminal 2 - Start Mobile App:**
```bash
cd mobile
flutter run
```

### Quick Start (macOS/Linux)

**Terminal 1 - Start Backend:**
```bash
cd backend
source .venv/bin/activate
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

**Terminal 2 - Start Mobile App:**
```bash
cd mobile
flutter run
```

---

## API Documentation

Once the backend is running, visit **http://localhost:8000/docs** for interactive Swagger UI documentation.

### Available Endpoints

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| POST | `/api/auth/register` | Register new user | No |
| POST | `/api/auth/login` | Login (returns JWT) | No |
| GET | `/api/auth/me` | Current user profile | Yes |
| GET | `/api/parking/spots` | List all parking spots | No |
| GET | `/api/parking/spots/available` | Available spots only | No |
| GET | `/api/parking/stats` | Parking statistics | No |
| POST | `/api/parking/lot` | Create parking lot | Yes |
| POST | `/api/parking/spots/seed` | Seed spots for a lot | Yes |
| POST | `/api/ocr/recognize` | Upload image → plate number | No |
| POST | `/api/ocr/entry` | Record vehicle entry | Yes |
| POST | `/api/ocr/exit` | Record vehicle exit | Yes |
| POST | `/api/reservations` | Create reservation | Yes |
| GET | `/api/reservations` | User's reservations | Yes |
| PATCH | `/api/reservations/{id}/cancel` | Cancel reservation | Yes |
| GET | `/api/reservations/history` | Past reservations | Yes |
| WS | `/ws/parking` | Real-time spot updates | No |

### Example: Scan a License Plate

```bash
curl -X POST "http://localhost:8000/api/ocr/recognize" \
  -H "accept: application/json" \
  -F "file=@plate_image.jpg"
```

**Response:**
```json
{
  "success": true,
  "plates": [
    {
      "plate_number": "ABC123",
      "confidence": 0.968,
      "bounding_box": [[0, 22], [133, 19], [135, 85], [0, 88]]
    }
  ],
  "count": 1
}
```

---

## Testing the OCR

The backend includes a test endpoint that works without authentication:

```bash
# Register a user first
curl -X POST "http://localhost:8000/api/auth/register" \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"test123","full_name":"Test User"}'

# Login to get token
curl -X POST "http://localhost:8000/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"test123"}'

# Create a parking lot
curl -X POST "http://localhost:8000/api/parking/lot" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"Main Lot","total_spots":20,"hourly_rate":5.0}'

# Seed spots
curl -X POST "http://localhost:8000/api/parking/spots/seed?lot_id=1&count=10" \
  -H "Authorization: Bearer YOUR_TOKEN"

# Record entry
curl -X POST "http://localhost:8000/api/ocr/entry" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"plate_number":"ABC123","spot_id":1}'
```

---

## Troubleshooting

### Backend Issues

| Problem | Solution |
|---------|----------|
| `ModuleNotFoundError: No module named 'app'` | Run from `backend/` directory |
| `paddleocr` download fails | Check internet connection; models download on first run |
| `bcrypt` version error | Ensure `bcrypt==4.0.1` in requirements.txt |
| Port 8000 in use | Use `--port 8001` or kill the process |

### Flutter Issues

| Problem | Solution |
|---------|----------|
| `flutter` not recognized | Add Flutter to PATH and restart terminal |
| `flutter doctor` shows red X | Follow the specific fix it suggests |
| Android toolchain missing | Run `flutter doctor --android-licenses` |
| Emulator won't start | Enable HAXM/ Hyper-V in BIOS settings |
| Connection refused on emulator | Use `10.0.2.2:8000` not `localhost:8000` |
| `pub get` fails | Run `flutter clean` then `flutter pub get` |

### Common Issues

| Problem | Solution |
|---------|----------|
| CORS error in browser | Backend has `allow_origins=["*"]` by default |
| Camera permission denied | Grant camera permission in app settings |
| OCR returns empty results | Ensure image has clear, well-lit license plate |

---

## License

This project is open source and available under the [MIT License](LICENSE).

---

## Author

**Anirudh M Kumar**

- GitHub: [@AnirudhMKumar](https://github.com/AnirudhMKumar)

---

## Acknowledgments

- [PaddleOCR](https://github.com/PaddlePaddle/PaddleOCR) - OCR engine
- [FastAPI](https://fastapi.tiangolo.com/) - Backend framework
- [Flutter](https://flutter.dev/) - Mobile framework
- [Riverpod](https://riverpod.dev/) - State management
