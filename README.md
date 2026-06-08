# CashewCare — AI-Powered Cashew Leaf Disease Detection

A full-stack system for detecting cashew leaf diseases using deep learning.  
Upload a photo of a cashew leaf and get an instant diagnosis with pesticide recommendations.

## Architecture

```
tunu/
├── backend/        Django REST API  (Python 3.13 + TensorFlow)
├── dashboard/      Admin web panel  (React + Vite)
└── frontend/       Mobile app       (Flutter)
```

---

## AI Models

Two models are bundled in `backend/models/`. TFLite is the default.

| Model | File | Classes | Notes |
|-------|------|---------|-------|
| **TFLite** *(default)* | `cashew_model.tflite` | 5 | Fast inference, low memory, edge-optimised |
| **Keras** | `cashew_nut_disease_model.keras` | 6 | Higher accuracy, requires more RAM |

### TFLite classes
`Anthracnose` · `Gummosis` · `Healthy` · `Leaf Blight` · `Die Back`

### Keras classes
`Anthracnose` · `Die Back` · `Gummosis` · `Healthy` · `Leaf Blight` · `Powdery Mildew`

The active model can be switched at runtime from the web dashboard (**AI Model** page) or the mobile admin panel (**AI Model** drawer item) — no server restart needed.

---

## Backend (Django)

### Requirements
- Python 3.10+
- PostgreSQL

### Setup

```bash
cd backend

# Create and activate virtual environment
python -m venv .venv
source .venv/bin/activate          # Windows: .venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Copy and edit environment variables
cp .env.example .env
```

Edit `.env`:

```env
SECRET_KEY=your-secret-key-here
DEBUG=True
ALLOWED_HOSTS=*

DB_NAME=cashew
DB_USER=postgres
DB_PASSWORD=your_db_password
DB_HOST=localhost
DB_PORT=5432

# Starting model: tflite | keras
ACTIVE_AI_MODEL=tflite
```

### Database & migrations

```bash
# Create the PostgreSQL database first
createdb cashew   # or use psql / pgAdmin

# Run migrations
python manage.py migrate
```

### Place model files

Copy the AI model files into `backend/models/`:

```
backend/models/
├── cashew_model.tflite
└── cashew_nut_disease_model.keras
```

### Create an admin user

```bash
python manage.py createsuperuser
```

### Run the server

```bash
# Localhost only (web dashboard same machine)
python manage.py runserver

# All network interfaces (required for physical Android device)
python manage.py runserver 0.0.0.0:8000
```

API is available at `http://localhost:8000/api/`

---

## Web Dashboard (React)

### Requirements
- Node.js 18+

### Setup

```bash
cd dashboard
npm install
```

### Development

```bash
npm run dev
```

Open `http://localhost:5173` in your browser.  
Log in with the superuser account created in the backend step.

### Production build

```bash
npm run build
# Serve the dist/ folder with any static file server
```

### Features
- Overview with scan statistics and disease distribution chart
- **Diagnose** — upload a leaf photo and run AI diagnosis directly from the browser
- User management, disease & pesticide CRUD, activity log
- AI Model switch (TFLite ↔ Keras) with live class list

---

## Mobile App (Flutter)

### Requirements
- Flutter 3.19+ (`flutter --version`)
- Android SDK (for Android) / Xcode (for iOS)

### Setup

```bash
cd frontend
flutter pub get
```

### Configure the backend URL

Edit `lib/core/constants/app_constants.dart`:

```dart
// Android emulator
static const String baseUrl = 'http://10.0.2.2:8000/api';

// Physical Android device — use your machine's LAN IP
static const String baseUrl = 'http://192.168.x.x:8000/api';
```

> Find your LAN IP with `hostname -I` (Linux/macOS) or `ipconfig` (Windows).  
> The backend must be started with `0.0.0.0:8000` when using a physical device.

### Run

```bash
# List connected devices
flutter devices

# Run on a specific device
flutter run -d <device-id>

# Release APK
flutter build apk --release
```

### Features (regular user)
- Register / login
- **Scan Leaf** — take a photo with the camera
- **Upload Image** — pick from gallery
- Detection history with search and filter
- Full result detail: disease name, confidence, pesticide, prevention

### Features (admin)
- Admin login (staff account required)
- Dashboard with stats, disease distribution chart
- User, disease, pesticide, and activity management
- **AI Model** — switch between TFLite and Keras at runtime

---

## API Reference (key endpoints)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/api/register` | Public | Create user account |
| POST | `/api/login` | Public | User login → JWT |
| POST | `/api/admin/login` | Public | Admin login → JWT (staff only) |
| POST | `/api/predict` | User JWT | Upload leaf image → diagnosis |
| GET | `/api/history` | User JWT | Detection history |
| GET | `/api/dashboard-stats` | User JWT | User scan statistics |
| GET | `/api/admin/statistics` | Admin JWT | Platform-wide stats |
| GET | `/api/admin/model` | Admin JWT | Active model info |
| POST | `/api/admin/model/switch` | Admin JWT | Switch active model |
| GET | `/api/admin/diseases` | Admin JWT | List diseases |
| GET | `/api/admin/pesticides` | Admin JWT | List pesticides |
| GET | `/api/admin/activities` | Admin JWT | Activity log |

---

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `SECRET_KEY` | *(required)* | Django secret key |
| `DEBUG` | `True` | Debug mode |
| `ALLOWED_HOSTS` | `*` | Comma-separated allowed hosts |
| `DB_NAME` | `cashew` | PostgreSQL database name |
| `DB_USER` | `postgres` | Database user |
| `DB_PASSWORD` | — | Database password |
| `DB_HOST` | `localhost` | Database host |
| `DB_PORT` | `5432` | Database port |
| `ACTIVE_AI_MODEL` | `tflite` | Default model (`tflite` or `keras`) |

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Backend API | Django 4.2 · Django REST Framework · SimpleJWT |
| Database | PostgreSQL |
| AI inference | TensorFlow 2.20 · TFLite runtime |
| Web dashboard | React 18 · Vite · Recharts |
| Mobile app | Flutter 3 · Dio · image_picker · tflite_flutter |
