@echo off
title SovereignGreen - Final Launch
color 0A

echo ========================================================
echo       SOVEREIGN-GREEN: FINAL FLIGHT LAUNCHER
echo ========================================================
echo.

echo [1/5] Checking Environment...
python --version
flutter --version
echo.

echo [2/5] Compiling Native C Engine...
cd SovereignGreen\native_engine
gcc -shared -o libenergy.dll energy_math.c
if %errorlevel% neq 0 (
    echo [ERROR] C Compilation Failed. Falling back to Python engine...
) else (
    echo [SUCCESS] C Engine compiled.
)
cd ..\..

echo [3/5] Installing Backend Dependencies...
cd SovereignGreen\server
pip install -r requirements.txt
cd ..\..

echo [4/5] Launching Backend Server (New Window)...
start "SovereignGreen Backend" cmd /k "cd SovereignGreen\server && python -m uvicorn app.main:app --host 127.0.0.1 --port 8004 --reload"

echo Waiting for backend to initialize...
timeout /t 5

echo [5/5] Launching Flutter Web App...
cd SovereignGreen\mobile_app
start "SovereignGreen Frontend" cmd /k "flutter run -d chrome --web-renderer canvaskit"

echo.
echo ========================================================
echo        SYSTEM ONLINE. DASHBOARD LAUNCHING...
echo ========================================================
echo.
pause
