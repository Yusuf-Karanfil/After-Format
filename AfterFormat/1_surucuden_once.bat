@echo off
title After Format - 1/3: Surucuden Once
cd /d "%~dp0"

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Yonetici yetkisi gerekli. Yukseltiliyor...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0files\1_surucuden_once.ps1"
pause
