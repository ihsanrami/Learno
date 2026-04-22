@echo off
title Learno Backend Server

echo =====================================
echo   Learno Educational Backend Server
echo =====================================

REM الانتقال إلى مجلد المشروع (مكان هذا الملف)
cd /d %~dp0

REM تفعيل البيئة الافتراضية
if not exist venv\Scripts\activate (
    echo ERROR: virtual environment not found!
    echo Please make sure "venv" folder exists.
    pause
    exit /b
)

call venv\Scripts\activate

REM تشغيل السيرفر بالطريقة الصحيحة
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

pause
