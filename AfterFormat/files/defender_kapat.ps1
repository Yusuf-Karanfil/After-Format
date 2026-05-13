# ================================================
#  AFTER FORMAT — DEFENDER KAPAT
#  Windows Defender'i devre disi birak
# ================================================

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "  Windows Defender kapatiliyor..." -ForegroundColor Cyan
Write-Host ""

# Ana Defender politikasi (GPO yolu - Tamper Protection bypass)
$defPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender"
if (!(Test-Path $defPath)) { New-Item -Path $defPath -Force | Out-Null }
Set-ItemProperty $defPath -Name "DisableAntiSpyware" -Value 1 -Type DWord -ErrorAction SilentlyContinue
Set-ItemProperty $defPath -Name "DisableAntiVirus"   -Value 1 -Type DWord -ErrorAction SilentlyContinue
Write-Host "  [OK] GPO politikasi uygulandi." -ForegroundColor Green

# Real-time protection kapat
$rtpPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection"
if (!(Test-Path $rtpPath)) { New-Item -Path $rtpPath -Force | Out-Null }
Set-ItemProperty $rtpPath -Name "DisableRealtimeMonitoring"   -Value 1 -Type DWord -ErrorAction SilentlyContinue
Set-ItemProperty $rtpPath -Name "DisableBehaviorMonitoring"   -Value 1 -Type DWord -ErrorAction SilentlyContinue
Set-ItemProperty $rtpPath -Name "DisableOnAccessProtection"   -Value 1 -Type DWord -ErrorAction SilentlyContinue
Set-ItemProperty $rtpPath -Name "DisableScanOnRealtimeEnable" -Value 1 -Type DWord -ErrorAction SilentlyContinue
Write-Host "  [OK] Real-time protection kapatildi." -ForegroundColor Green

# WinDefend servisi kapat
try {
    Stop-Service -Name "WinDefend" -Force -ErrorAction SilentlyContinue
    Set-Service  -Name "WinDefend" -StartupType Disabled -ErrorAction Stop
    Write-Host "  [OK] WinDefend servisi devre disi." -ForegroundColor Green
} catch {
    Write-Host "  [BILGI] WinDefend servisi ayarlanamadi." -ForegroundColor Yellow
    Write-Host "          Tamper Protection aktif olabilir." -ForegroundColor Yellow
    Write-Host "          Manuel: Windows Security > Virus & threat protection settings > Tamper Protection kapat." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "  Windows Defender kapatildi." -ForegroundColor Green
Write-Host "  Gorev cubugunda sari uyari ikonu gorunecek — bu normaldir." -ForegroundColor Yellow
Write-Host ""
Write-Host "  Yeniden acmak icin: defender_ac.bat" -ForegroundColor DarkGray
Write-Host ""
