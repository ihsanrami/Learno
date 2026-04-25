@echo off
setlocal EnableDelayedExpansion

echo === Learno Release APK Builder ===
echo.

if not exist "pubspec.yaml" (
    echo ERROR: Run this script from the flutter_tested directory.
    echo Usage: cd flutter_tested ^& build_release.bat
    pause
    exit /b 1
)

set /p API_URL="Enter backend URL (e.g. https://your-app.railway.app): "
if "!API_URL!"=="" (
    set API_URL=https://your-backend-url.com
    echo Using placeholder URL. Update with real URL before distributing.
)

echo.
echo Cleaning previous builds...
call flutter clean
if errorlevel 1 goto :error

echo.
echo Getting dependencies...
call flutter pub get
if errorlevel 1 goto :error

echo.
echo Generating localization files...
call flutter gen-l10n
if errorlevel 1 goto :error

echo.
echo [1/2] Building release APK...
call flutter build apk --release --dart-define=API_BASE_URL=!API_URL!
if errorlevel 1 goto :error

echo.
echo [2/2] Building Android App Bundle (Play Store)...
call flutter build appbundle --release --dart-define=API_BASE_URL=!API_URL!
if errorlevel 1 goto :error

echo.
echo === BUILD COMPLETE ===
echo APK:    build\app\outputs\flutter-apk\app-release.apk
echo Bundle: build\app\outputs\bundle\release\app-release.aab
echo.
echo Share the APK for direct distribution / testing.
echo Upload the .aab to Google Play Console.
echo.
pause
exit /b 0

:error
echo.
echo === BUILD FAILED ===
echo Check the errors above and try again.
pause
exit /b 1
