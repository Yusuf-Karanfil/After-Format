# ================================================
#  AFTER FORMAT — DEFENDER AC
#  Windows Defender'i yeniden etkinlestir
# ================================================

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "  Windows Defender yeniden aktif ediliyor..." -ForegroundColor Cyan
Write-Host ""

# GPO kayitlarini temizle
Remove-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" `
    -Name "DisableAntiSpyware" -ErrorAction SilentlyContinue
Remove-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" `
    -Name "DisableAntiVirus" -ErrorAction SilentlyContinue
Remove-Item "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" `
    -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "  [OK] GPO kayitlari temizlendi." -ForegroundColor Green

# WinDefend servisini geri ac
Set-Service -Name "WinDefend" -StartupType Automatic -ErrorAction SilentlyContinue
Start-Service -Name "WinDefend" -ErrorAction SilentlyContinue
Write-Host "  [OK] WinDefend servisi baslatildi." -ForegroundColor Green

# Real-time protection ac
Set-MpPreference -DisableRealtimeMonitoring $false -ErrorAction SilentlyContinue
Write-Host "  [OK] Real-time protection acildi." -ForegroundColor Green

Write-Host ""
Write-Host "  Windows Defender aktif edildi." -ForegroundColor Green
Write-Host ""
Write-Host "  Tam olarak oturmasi icin bilgisayari yeniden baslat." -ForegroundColor Yellow
Write-Host ""
