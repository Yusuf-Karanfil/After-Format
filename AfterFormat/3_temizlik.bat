@echo off
title After Format - 3/3: Temizlik ve Optimizasyon
cd /d "%~dp0"

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Yonetici yetkisi gerekli. Yukseltiliyor...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b

)

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0files\3_temizlik.ps1"
pause
