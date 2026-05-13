@echo off
title Windows Defender - Kapat
cd /d "%~dp0"

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Yonetici yetkisi gerekli. Yukseltiliyor...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\files\defender_kapat.ps1"
pause
