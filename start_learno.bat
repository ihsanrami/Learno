@echo off
title Learno Server
color 0A
echo.
echo ============================================
echo         LEARNO - STARTING SERVER
echo ============================================
echo.

REM Get current IP
for /f "tokens=4 delims= " %%i in ('route print ^| find " 0.0.0.0" ^| find /v "On-link"') do (set ip=%%i & goto :found)
:found
echo Current IP: %ip%
echo.
echo Backend URL: http://%ip%:8000
echo API Base: http://%ip%:8000/api/v1
echo.
echo ============================================
echo  Make sure your phone is on the same WiFi!
echo ============================================
echo.

cd /d "C:\Users\VICTUS\Desktop\Learno\backend"
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000

pause
