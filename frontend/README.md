# =============================================================================
# 📱 Learno Flutter App - Installation Guide
# =============================================================================
# ✅ QA TESTED & FIXED VERSION
# =============================================================================

## 📋 What's Fixed

This version includes all QA fixes:

| Issue | Status |
|-------|--------|
| SDK version compatibility | ✅ Fixed |
| Missing assets error | ✅ Fixed |
| Duplicate Grade enum | ✅ Fixed |
| Image.asset crashes | ✅ Fixed (using styled containers) |
| API URL configuration | ✅ Fixed |

---

## 🚀 Quick Start

### 1. Extract and Navigate
```bash
cd learno_flutter_tested
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Start Backend First!
```bash
# In another terminal, start your backend:
cd backend_tested
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### 4. Run the App

**For Chrome (easiest for testing):**
```bash
flutter run -d chrome
```

**For Android Emulator:**
```bash
flutter run
```

**For Real Device:**
1. Edit `lib/api/api_config.dart`
2. Change `baseUrl` to your computer's IP
3. Run: `flutter run`

---

## 📁 Project Structure

```
lib/
├── main.dart                    # App entry point
├── api/
│   ├── api_config.dart         # Backend URL configuration
│   ├── api_service.dart        # API calls
│   └── dto.dart                # Data Transfer Objects
├── core/
│   └── session_state.dart      # Global state management
├── models/
│   ├── enums.dart              # Grade, Subject, etc.
│   └── chat_message.dart       # Message model
├── services/
│   ├── tts_service.dart        # Text-to-Speech
│   ├── stt_service.dart        # Speech-to-Text
│   ├── image_service.dart      # Image handling
│   └── student_storage.dart    # Local persistence
├── providers/
│   └── interaction_mode.dart   # Voice/Text mode
├── controllers/
│   └── conversation_controller.dart  # Chat logic
└── screens/
    ├── grades.dart             # Grade selection
    ├── categories.dart         # Subject selection
    ├── math.dart               # Math topics
    └── chat.dart               # Main learning screen
```

---

## 🔧 Configuration

### Backend URL

Edit `lib/api/api_config.dart`:

```dart
// For Android Emulator:
static const String baseUrl = 'http://10.0.2.2:8000/api/v1';

// For Chrome/Web:
static const String baseUrl = 'http://localhost:8000/api/v1';

// For Real Device (replace with your IP):
static const String baseUrl = 'http://192.168.1.100:8000/api/v1';
```

---

## 🎯 How to Use

1. **Select Grade** → Second Grade (only available grade)
2. **Select Subject** → Math (only available subject)
3. **Select Topic** → Counting (or any topic)
4. **Press Continue** → Start learning!
5. **Voice Mode** → Learno speaks, you speak back
6. **Text Mode** → Type your answers

---

## ⚠️ Troubleshooting

### "No supported devices connected"
```bash
flutter create .
flutter run -d chrome
```

### "Connection refused"
- Make sure backend is running on port 8000
- Check `baseUrl` in `api_config.dart`

### "SDK version error"
- This version uses SDK ^3.5.0 (stable)
- Run: `flutter upgrade`

### Voice not working (Web)
- Chrome may block microphone
- Allow microphone permission in browser

---

## 🔗 Backend Compatibility

This frontend is designed to work with `backend_tested.zip`:

| Endpoint | Method | Purpose |
|----------|--------|---------|
| /session/start | POST | Start lesson |
| /session/end | POST | End lesson |
| /lesson/continue | POST | Continue teaching |
| /lesson/respond | POST | Send answer |
| /lesson/silence | POST | Handle silence |

---

## 📞 Support

If issues persist:
1. Check backend logs
2. Check browser console (F12)
3. Run `flutter doctor` to verify setup

---

Made with ❤️ for young learners! 🎓
