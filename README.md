# Learno — AI-Powered Educational App for Kids

> An interactive bilingual (English/Arabic) tutoring companion that uses AI, voice, and adaptive lessons to make learning fun for children aged 5–12.

---

## Features

- **AI Tutor** — Conversational lessons powered by GPT-4o
- **Voice Interaction** — Children speak; Learno listens and responds via TTS
- **Bilingual** — Full English/Arabic support with RTL layout
- **Adaptive Curriculum** — Dynamic lesson progression per child
- **Parent Dashboard** — Analytics, goal tracking, and achievement badges
- **Image Generation** — AI-generated visuals to reinforce concepts
- **Secure Auth** — JWT-based accounts with parent and child profiles

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Mobile | Flutter 3.x (Dart) |
| Backend | FastAPI (Python 3.11) |
| AI | OpenAI GPT-4o |
| Database | SQLite (dev) / PostgreSQL (prod) |
| Auth | JWT + bcrypt |
| TTS/STT | flutter_tts + speech_to_text |
| CI/CD | GitHub Actions |

---

## Architecture

```
┌─────────────────────────────────────────────┐
│              Flutter App (Mobile)            │
│  ┌──────────┐  ┌──────────┐  ┌───────────┐  │
│  │  Child   │  │  Parent  │  │  Auth     │  │
│  │  Lesson  │  │Dashboard │  │  Screens  │  │
│  └────┬─────┘  └────┬─────┘  └─────┬─────┘  │
└───────┼──────────────┼──────────────┼────────┘
        │  HTTP/REST   │              │
┌───────┼──────────────┼──────────────┼────────┐
│       ▼    FastAPI Backend          ▼        │
│  ┌──────────┐  ┌──────────┐  ┌───────────┐  │
│  │ Lesson   │  │ Children │  │   Auth    │  │
│  │ Routes   │  │  Routes  │  │  Routes   │  │
│  └────┬─────┘  └────┬─────┘  └─────┬─────┘  │
│       └─────────────┼───────────────┘        │
│                ┌────▼─────┐                  │
│                │ SQLAlchemy│                  │
│                │    ORM   │                  │
│                └────┬─────┘                  │
│           ┌─────────┼────────┐               │
│      ┌────▼───┐  ┌──▼───┐ ┌──▼──────┐       │
│      │SQLite  │  │OpenAI│ │ Static  │       │
│      │  DB    │  │ API  │ │ Images  │       │
│      └────────┘  └──────┘ └─────────┘       │
└─────────────────────────────────────────────┘
```

---

## Local Development Setup

### Prerequisites

- Python 3.11+
- Flutter SDK (stable channel)
- Java 17+ (for Android builds)
- OpenAI API key

### Backend Setup

```bash
cd backend_fixed

# Create virtual environment
python -m venv venv
source venv/bin/activate          # Linux/Mac
venv\Scripts\activate             # Windows

# Install dependencies
pip install -r requirements.txt -r requirements-dev.txt

# Configure environment
cp .env.example .env
# Edit .env — set OPENAI_API_KEY and JWT_SECRET_KEY at minimum

# Run development server
uvicorn app.main:app --reload --port 8000
```

The API will be available at `http://localhost:8000`.
Interactive docs: `http://localhost:8000/docs`

### Flutter Setup

```bash
cd flutter_tested

# Install dependencies
flutter pub get

# Generate localizations
flutter gen-l10n

# Run on connected device / emulator
flutter run
```

> By default the app points to `http://10.0.2.2:8000` (Android emulator → host).
> For a physical device, update the base URL in `lib/config/app_config.dart`.

### Required Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `OPENAI_API_KEY` | Yes | OpenAI API key |
| `JWT_SECRET_KEY` | Yes | Random secret (min 32 chars) |
| `DATABASE_URL` | No | SQLite default; set PostgreSQL URL for prod |
| `OPENAI_MODEL` | No | Default: `gpt-4o` |
| `DEBUG` | No | Default: `true` (set `false` in production) |
| `ALLOWED_ORIGINS` | No | CORS origins (default `*`) |

---

## Running Tests

```bash
cd backend_fixed

# Run all tests
pytest tests/ -v

# With coverage report
pytest tests/ --cov=app --cov-report=term-missing

# Quick summary only
pytest tests/ -q
```

Expected: **524+ tests passing**.

---

## Building for Production

### Backend (Docker)

```bash
cd backend_fixed

# Build image
docker build -t learno-backend .

# Run locally with Docker Compose
docker compose up
```

See [DEPLOYMENT.md](DEPLOYMENT.md) for cloud deployment steps.

### Flutter APK

**Windows:**
```batch
cd flutter_tested
build_release.bat
```

**Linux / Mac:**
```bash
cd flutter_tested
bash build_release.sh
```

Output files:
- `build/app/outputs/flutter-apk/app-release.apk` — direct distribution
- `build/app/outputs/bundle/release/app-release.aab` — Google Play upload

---

## Deployment Guide

See [DEPLOYMENT.md](DEPLOYMENT.md) for full deployment instructions including:
- Railway / Render backend deployment
- APK distribution
- Google Play Store submission
- App Store submission

---

## Project Structure

```
Learno/
├── backend_fixed/          # FastAPI backend
│   ├── app/
│   │   ├── config.py       # Settings (pydantic-settings)
│   │   ├── database/       # SQLAlchemy models & session
│   │   ├── models/         # ORM models
│   │   ├── routes/         # API route handlers
│   │   ├── services/       # Business logic (AI, lessons, TTS)
│   │   └── main.py         # FastAPI app entry point
│   ├── tests/              # pytest test suite (524+ tests)
│   ├── Dockerfile
│   ├── docker-compose.yml
│   ├── requirements.txt
│   └── .env.example
├── flutter_tested/         # Flutter mobile app
│   ├── lib/
│   │   ├── l10n/           # Localization (en/ar)
│   │   ├── screens/        # UI screens
│   │   ├── services/       # API + audio services
│   │   └── main.dart
│   ├── android/
│   ├── build_release.bat   # Windows build script
│   ├── build_release.sh    # Linux/Mac build script
│   └── pubspec.yaml
├── .github/
│   └── workflows/
│       ├── tests.yml       # Backend CI (runs on every push)
│       └── build-apk.yml   # Flutter APK build
├── README.md
├── DEPLOYMENT.md
└── PRIVACY_POLICY.md
```

---

## Contributors

| Name | Role |
|------|------|
| Ahmad Aljanaideh | Project Lead / Backend |
| Ihsan | Mobile Development |
| Abdalrahman | AI Integration |
| Mohammad | UI/UX Design |
| Abeer | Testing & QA |

**Supervisor:** Dr. Khaldoon T. Alzoubi

---

## License

This project is submitted as an academic capstone project. All rights reserved by the contributors.
