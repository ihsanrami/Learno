# Learno

AI-powered educational app for children (K–Grade 4). A fox mascot named Learno teaches Math, Science, English, and Arabic through voice-first conversational lessons. Backend is FastAPI + GPT-4o; frontend is Flutter (Android).

## Tech Stack

- **Backend:** Python 3.11, FastAPI, SQLAlchemy, OpenAI GPT-4o / DALL-E 3
- **Frontend:** Flutter 3.x, Dart — Android target
- **Auth:** JWT (parent accounts) + local child profiles
- **Localization:** English + Arabic (flutter_localizations)

## Prerequisites

- Python 3.11+
- Flutter 3.x (`flutter doctor` should pass)
- OpenAI API key
- Android SDK (for APK builds)

## Backend Setup

```bash
cd backend
python -m venv venv
source venv/bin/activate        # Windows: venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env            # fill in OPENAI_API_KEY and JWT_SECRET_KEY
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

API docs available at `http://localhost:8000/docs`.

## Frontend Setup

```bash
cd frontend
flutter pub get
flutter gen-l10n
flutter run                     # hot reload on connected device/emulator
```

To build a release APK:

```bash
flutter build apk --release \
  --dart-define=API_BASE_URL=http://<your-backend-ip>:8000/api/v1
```

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `OPENAI_API_KEY` | Yes | GPT-4o + DALL-E 3 key |
| `JWT_SECRET_KEY` | Yes | Secret for signing JWT tokens |
| `DEBUG` | No | Set `true` for dev logging (default: `false`) |
| `ALLOWED_ORIGINS` | No | CORS origins, comma-separated (default: `*`) |

## App Icon

Icon source is `frontend/assets/images/app_icon.png`. To regenerate Android icons after changing the source:

```bash
cd frontend
flutter pub run flutter_launcher_icons:main
```

## Project Structure

```
Learno/
├── .github/workflows/build-apk.yml
├── backend/
│   ├── app/
│   │   ├── ai/          # GPT-4o prompts + chapter generator
│   │   ├── auth/        # JWT auth, parent accounts
│   │   ├── database/    # SQLAlchemy session + base
│   │   ├── models/      # curriculum data + lesson content
│   │   ├── routes/      # API endpoints
│   │   ├── services/    # lesson, image, message-splitting logic
│   │   ├── utils/       # exceptions
│   │   └── main.py
│   ├── .env.example
│   └── requirements.txt
└── frontend/
    ├── assets/
    │   ├── fonts/       # Recoleta + ThmanyahSans
    │   └── images/      # fox mascot, backgrounds, grade cards
    ├── lib/
    │   ├── api/         # HTTP client + DTOs
    │   ├── controllers/ # auth + locale state
    │   ├── l10n/        # EN + AR strings
    │   ├── models/      # message queue
    │   ├── screens/     # chat, grades, topics, auth, parent dashboard
    │   └── services/    # TTS, STT, auth, storage
    ├── android/
    ├── flutter_launcher_icons.yaml
    ├── l10n.yaml
    └── pubspec.yaml
```

## Notes

- Backend uses SQLite by default (`learno.db`, gitignored). Set `DATABASE_URL` env var for production.
- AI-generated images are proxied to `/static/generated_images/` — not committed to git.
- TTS uses `flutter_tts`; STT uses `speech_to_text`. Both require microphone permission on Android.
- Arabic lessons use RTL layout and ThmanyahSans font automatically.
- Parent dashboard tracks child progress per `child_id`.
- `API_BASE_URL` dart-define must point to the running backend for the app to function.
