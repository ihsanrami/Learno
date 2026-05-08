# Learno — Deployment Guide

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Backend Deployment — Railway](#backend-deployment--railway)
3. [Backend Deployment — Render](#backend-deployment--render)
4. [Building the APK](#building-the-apk)
5. [Distributing the APK](#distributing-the-apk)
6. [Google Play Store Submission](#google-play-store-submission)
7. [App Store Submission (iOS)](#app-store-submission-ios)
8. [Post-Launch](#post-launch)
9. [Troubleshooting](#troubleshooting)
10. [Privacy Policy & Terms](#privacy-policy--terms)

---

## Prerequisites

### Accounts You Need

| Service | Purpose | Cost |
|---------|---------|------|
| [OpenAI](https://platform.openai.com) | GPT-4o API | Pay-per-use |
| [Railway](https://railway.app) or [Render](https://render.com) | Backend hosting | Free tier available |
| [Google Play Console](https://play.google.com/console) | Android app distribution | $25 one-time |
| [Apple Developer](https://developer.apple.com) | iOS app distribution | $99/year |
| GitHub | Source control + CI/CD | Free |

### Local Tools

- Docker Desktop (for testing the container locally)
- Flutter SDK (stable channel) + Java 17
- Android Studio or VS Code with Flutter extension

---

## Backend Deployment — Railway

Railway is the recommended platform for quick deployment with SQLite.

### Step 1: Prepare the Repository

Ensure these files exist in `backend/`:
- `Dockerfile` ✅
- `.env.example` ✅
- `requirements.txt` ✅

### Step 2: Create a Railway Project

1. Go to [railway.app](https://railway.app) and sign in with GitHub.
2. Click **New Project** → **Deploy from GitHub repo**.
3. Select your `Learno` repository.
4. Railway will detect the `Dockerfile` automatically.

### Step 3: Set the Root Directory

In Railway project settings:
- **Root Directory**: `backend`

### Step 4: Configure Environment Variables

In Railway → your service → **Variables**, add:

```
OPENAI_API_KEY=sk-your-real-key-here
JWT_SECRET_KEY=generate-with-python-secrets-module
DATABASE_URL=sqlite:////data/learno.db
DEBUG=false
ALLOWED_ORIGINS=*
```

To generate a secure JWT secret:
```bash
python -c "import secrets; print(secrets.token_hex(32))"
```

### Step 5: Add a Persistent Volume (SQLite)

1. In Railway → your service → **Volumes**.
2. Click **Add Volume**.
3. Mount path: `/data`
4. This ensures the database survives redeployments.

### Step 6: Deploy

Railway deploys automatically on every push to `main`. To trigger manually:
- Click **Deploy** in the Railway dashboard.

### Step 7: Get Your Backend URL

After deployment, Railway provides a URL like:
`https://learno-backend-production.up.railway.app`

Note this URL — you'll need it when building the Flutter APK.

### Upgrading to PostgreSQL (Optional, Production-Grade)

1. In Railway, add a **PostgreSQL** plugin to your project.
2. Railway will inject a `DATABASE_URL` env var automatically.
3. Update your `DATABASE_URL` variable to use this PostgreSQL URL.
4. Restart the backend service.

---

## Backend Deployment — Render

Alternative to Railway. Uses `render.yaml` for infrastructure-as-code.

### Step 1: Create a `render.yaml`

Add this file to `backend/render.yaml`:

```yaml
services:
  - type: web
    name: learno-backend
    env: docker
    dockerfilePath: ./Dockerfile
    plan: free
    envVars:
      - key: OPENAI_API_KEY
        sync: false
      - key: JWT_SECRET_KEY
        sync: false
      - key: DEBUG
        value: false
      - key: DATABASE_URL
        value: sqlite:////data/learno.db
    disk:
      name: learno-data
      mountPath: /data
      sizeGB: 1
```

### Step 2: Deploy on Render

1. Go to [render.com](https://render.com) → **New** → **Web Service**.
2. Connect your GitHub repo.
3. Set **Root Directory** to `backend`.
4. Render will use the `Dockerfile`.
5. Set environment variables in the Render dashboard.

---

## Building the APK

### Option A: Local Build (Windows)

```batch
cd frontend
build_release.bat
```

Enter your Railway/Render backend URL when prompted.

### Option B: Local Build (Linux/Mac)

```bash
cd frontend
bash build_release.sh
```

### Option C: GitHub Actions (Automated)

Every push to `main` that touches `frontend/` automatically triggers a build.

1. Go to your GitHub repo → **Actions** → **Build APK**.
2. Click **Run workflow** to trigger manually.
3. After completion, download the APK from **Artifacts**.

To set the production API URL in CI:
- Go to repo **Settings** → **Secrets and variables** → **Actions**.
- Add secret `API_BASE_URL` with your backend URL.
- Update `.github/workflows/build-apk.yml` to use `${{ secrets.API_BASE_URL }}`.

### APK Output Location

```
frontend/build/app/outputs/flutter-apk/app-release.apk     ← Share this
frontend/build/app/outputs/bundle/release/app-release.aab  ← Upload to Play Store
```

---

## Distributing the APK

### Direct Distribution (Quick Testing)

1. Upload `app-release.apk` to Google Drive, Dropbox, or a web server.
2. Share the download link with testers.
3. Testers must enable **Install from unknown sources** on their Android device.

### Firebase App Distribution (Recommended for Beta Testing)

1. Create a project at [console.firebase.google.com](https://console.firebase.google.com).
2. Go to **App Distribution** → **Get started**.
3. Upload `app-release.apk`.
4. Add tester email addresses.
5. Testers receive an email with a one-click install link.

---

## Google Play Store Submission

### Step 1: Create a Play Console Account

1. Go to [play.google.com/console](https://play.google.com/console).
2. Pay the one-time $25 registration fee.
3. Complete identity verification.

### Step 2: Create Keystore for Signing

**Do this once and keep the keystore file safe.**

```bash
keytool -genkey -v -keystore learno-release.jks \
  -alias learno -keyalg RSA -keysize 2048 -validity 10000
```

Store `learno-release.jks` securely — you need it for every future release.

### Step 3: Configure Signing in Flutter

Create `frontend/android/key.properties`:
```
storePassword=your-store-password
keyPassword=your-key-password
keyAlias=learno
storeFile=../learno-release.jks
```

Update `frontend/android/app/build.gradle.kts` to use the keystore.

> **Never commit `key.properties` or `learno-release.jks` to git.**

### Step 4: Create a New App in Play Console

1. Click **Create app**.
2. App name: **Learno**
3. Default language: **English**
4. App or game: **App**
5. Free or paid: **Free** (or paid)
6. Accept policies.

### Step 5: App Store Listing Requirements

Prepare these assets:

| Asset | Size | Notes |
|-------|------|-------|
| App icon | 512×512 PNG | No alpha channel |
| Feature graphic | 1024×500 PNG/JPG | Banner shown in store |
| Screenshots | Min 2, phone | 16:9 or 9:16 |
| Short description | Max 80 chars | Shown in search |
| Full description | Max 4000 chars | App store listing |

### Step 6: Content Rating

1. Go to **Policy** → **App content** → **Content rating**.
2. Complete the questionnaire.
3. For a children's educational app, expect a **PEGI 3** / **Everyone** rating.

### Step 7: Privacy Policy

Required for apps that collect any user data. Use the template in [PRIVACY_POLICY.md](PRIVACY_POLICY.md) and host it at a public URL (e.g., GitHub Pages or your backend's `/privacy` endpoint).

### Step 8: Build & Upload the AAB

```bash
cd frontend
flutter build appbundle --release --dart-define=API_BASE_URL=https://your-backend.railway.app
```

In Play Console → **Production** → **Create new release** → upload the `.aab` file.

### Step 9: Submit for Review

Google typically reviews within 1–3 business days for new apps.

---

## App Store Submission (iOS)

### Requirements

- macOS computer with Xcode 15+
- Apple Developer account ($99/year)
- iPhone/iPad for testing (or Simulator)

### Steps

1. Open `frontend/ios/Runner.xcworkspace` in Xcode.
2. Set **Bundle Identifier** to `com.learno.app`.
3. Select your Apple Developer team.
4. **Product** → **Archive** to create an `.xcarchive`.
5. In **Organizer**, click **Distribute App** → **App Store Connect**.
6. In [App Store Connect](https://appstoreconnect.apple.com), create a new app.
7. Upload the build and fill in the listing.
8. Submit for review (typically 1–2 business days).

### TestFlight (Beta Testing)

Before App Store submission, use TestFlight:
1. Upload a build to App Store Connect.
2. Go to **TestFlight** → add internal/external testers.
3. External TestFlight review takes ~1 day.

---

## Post-Launch

### Monitoring

- Check Railway/Render dashboard for logs and errors.
- Set up [Sentry](https://sentry.io) for error tracking (optional).
- Monitor OpenAI API usage at [platform.openai.com/usage](https://platform.openai.com/usage).

### User Feedback

- Monitor Play Store / App Store reviews.
- Set up a feedback email (e.g., `feedback@learno.app`).

### Updates Strategy

1. Increment `versionCode` and `versionName` in `pubspec.yaml`.
2. Push to `main` → GitHub Actions builds the APK automatically.
3. Download from Actions artifacts → upload to Play Console.

---

## Troubleshooting

### Backend won't start in Docker

```bash
docker compose logs backend
```

Common causes:
- Missing `OPENAI_API_KEY` → add it to `.env`
- Port 8000 already in use → change host port in `docker-compose.yml`

### Flutter build fails with "SDK not found"

```bash
flutter doctor
```

Ensure Java 17 and Android SDK are installed and on PATH.

### APK installs but can't reach backend

- Confirm the backend URL in the build command is correct and reachable.
- For physical device + local backend: use your machine's LAN IP, not `localhost`.

### "Cleartext HTTP traffic not permitted" on Android

Add `android:usesCleartextTraffic="true"` to `<application>` in `AndroidManifest.xml` for development only. **Remove before production** — always use HTTPS.

### Play Store rejects the app

- Ensure the privacy policy URL is live and accessible.
- Ensure all permissions declared in `AndroidManifest.xml` are actually used.

---

## Privacy Policy & Terms

See [PRIVACY_POLICY.md](PRIVACY_POLICY.md) for the COPPA-compliant privacy policy template.

Host it at a public URL before Play Store submission. Options:
- Add a `/privacy` route to the FastAPI backend that returns the HTML.
- Host as a GitHub Pages page (`https://yourusername.github.io/learno/privacy`).
