# ================================================
#  AFTER FORMAT — 3/3: TEMIZLIK VE OPTIMIZASYON
#  Disk temizligi + Performans ayarlari
# ================================================

$ErrorActionPreference = "Continue"
$rootDir = Split-Path $PSScriptRoot -Parent
$logFile = "$rootDir\log.txt"

$banner = @"

################################################################
#                                                              #
#   SCRIPT 3/3 — TEMIZLIK VE OPTIMIZASYON                      #
#   Baslangic: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')                        #
#                                                              #
################################################################

"@
Add-Content -Path $logFile -Value $banner

function Write-Step {
    param([string]$Message, [string]$Color = "Cyan")
    $line = "[$(Get-Date -Format 'HH:mm:ss')] $Message"
    Write-Host $line -ForegroundColor $Color
    Add-Content -Path $logFile -Value $line
}
function Write-Ok   { Write-Step "  [OK]    $($args[0])" "Green" }
function Write-Fail { Write-Step "  [HATA]  $($args[0])" "Red" }
function Write-Info { Write-Step "  [BILGI] $($args[0])" "Yellow" }

function Section {
    param([string]$Title)
    Write-Host ""
    Write-Host ("=" * 60) -ForegroundColor Magenta
    Write-Host "  $Title" -ForegroundColor Magenta
    Write-Host ("=" * 60) -ForegroundColor Magenta
    Add-Content -Path $logFile -Value "`n=== $Title ==="
}

function Initialize-Path {
    param([string]$Path)
    if (!(Test-Path $Path)) {
        New-Item -Path $Path -Force | Out-Null
    }
}

# Baslangic disk bilgisi
$diskBefore = (Get-PSDrive C).Free / 1GB
Write-Info ("Baslangic bos alan: {0:N2} GB" -f $diskBefore)

# ================================================
Section "ADIM 1/12 — TEMP Klasorleri"
# ================================================

Write-Step "Kullanici TEMP temizleniyor..."
Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
Write-Ok "TEMP temizlendi."

Write-Step "Windows TEMP temizleniyor..."
Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
Write-Ok "Windows\Temp temizlendi."

# ================================================
Section "ADIM 2/12 — Windows Update Cache"
# ================================================

Write-Step "Windows Update servisleri durduruluyor..."
Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
Stop-Service bits -Force -ErrorAction SilentlyContinue

Write-Step "SoftwareDistribution\Download temizleniyor..."
Remove-Item "C:\Windows\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
Write-Ok "Update indirme cache'i temizlendi."

Write-Step "Delivery Optimization cache temizleniyor..."
Remove-Item "C:\Windows\SoftwareDistribution\DeliveryOptimization\Cache\*" -Recurse -Force -ErrorAction SilentlyContinue
Write-Ok "DO cache temizlendi."

Write-Step "Servisler yeniden baslatiliyor..."
Start-Service bits -ErrorAction SilentlyContinue
Start-Service wuauserv -ErrorAction SilentlyContinue
Write-Ok "Servisler aktif."

# ================================================
Section "ADIM 3/12 — DISM Component Cleanup (ResetBase)"
# ================================================

Write-Info "Bu islem 5-15 dakika surebilir."
Write-Info "Update rollback imkani kaldirilacak (ResetBase)."
Write-Info "DISM'in kendi yuzdelik gostergesi asagida cikacak."
Write-Info "CTRL+C BASMA, KAPATMA. Bekle, calisiyor."
Write-Step "WinSxS temizleniyor..."
Write-Host ""

$dismStart = Get-Date
try {
    Dism.exe /Online /Cleanup-Image /StartComponentCleanup /ResetBase
    $dur = [int]((Get-Date) - $dismStart).TotalSeconds
    $min = [int]($dur / 60); $sec = $dur % 60
    Write-Ok ("Component store temizlendi ($min dk $sec sn surdu).")
} catch {
    Write-Fail "DISM hatasi: $_"
}

# ================================================
Section "ADIM 4/12 — Thumbnail + Icon Cache"
# ================================================

Write-Step "Thumbnail cache temizleniyor..."
Remove-Item "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache_*.db" -Force -ErrorAction SilentlyContinue
Write-Ok "Thumbnail cache temizlendi."

Write-Step "Icon cache temizleniyor..."
Remove-Item "$env:LOCALAPPDATA\IconCache.db" -Force -ErrorAction SilentlyContinue
Write-Ok "Icon cache temizlendi."

# ================================================
Section "ADIM 5/12 — Error Reporting ve Log Dosyalari"
# ================================================

Write-Step "WER (Windows Error Reporting) temizleniyor..."
Remove-Item "C:\ProgramData\Microsoft\Windows\WER\*" -Recurse -Force -ErrorAction SilentlyContinue
Write-Ok "WER temizlendi."

Write-Step "CBS loglari temizleniyor..."
Remove-Item "C:\Windows\Logs\CBS\*" -Force -ErrorAction SilentlyContinue
Write-Ok "CBS loglari temizlendi."

Write-Step "DISM loglari temizleniyor..."
Remove-Item "C:\Windows\Logs\DISM\*" -Force -ErrorAction SilentlyContinue
Write-Ok "DISM loglari temizlendi."

Write-Step "Memory dump dosyalari temizleniyor..."
Remove-Item "C:\Windows\Minidump\*" -Force -ErrorAction SilentlyContinue
Remove-Item "C:\Windows\MEMORY.DMP" -Force -ErrorAction SilentlyContinue
Write-Ok "Dump dosyalari temizlendi."

# ================================================
Section "ADIM 6/12 — Geri Donusum Kutusu"
# ================================================

Write-Step "Geri donusum kutusu bosaltiliyor..."
Clear-RecycleBin -Force -ErrorAction SilentlyContinue
Write-Ok "Geri donusum bosaltildi."

# ================================================
Section "ADIM 7/12 — Hibernate Kapatma"
# ================================================

Write-Step "Hibernate dosyasi kapatiliyor..."
Write-Info "hiberfil.sys silinecek (RAM boyutu kadar alan bosalir)."
Write-Info "Fast Startup ozelligi de devre disi kalacak."

try {
    powercfg /h off
    Write-Ok "Hibernate kapatildi."
} catch {
    Write-Fail "Hibernate kapatilamadi: $_"
}

# ================================================
Section "ADIM 8/12 — UI Hiz Ayarlari"
# ================================================

Write-Step "Menu gosterim gecikmesi sifirlaniyor..."
Set-ItemProperty "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -Value "0" -ErrorAction SilentlyContinue
Write-Ok "MenuShowDelay = 0."

# ================================================
Section "ADIM 9/12 — NTFS Optimizasyonu"
# ================================================

Write-Step "Last access time kapatiliyor..."
try {
    fsutil behavior set disablelastaccess 1 | Out-Null
    Write-Ok "Last access time kapatildi."
} catch {
    Write-Fail "Last access ayarlanamadi."
}

Write-Step "8.3 kisa dosya adi uretimi kapatiliyor..."
try {
    fsutil behavior set disable8dot3 1 | Out-Null
    Write-Ok "8.3 filename kapatildi."
} catch {
    Write-Fail "8.3 ayarlanamadi."
}

# ================================================
Section "ADIM 10/12 — Storage Sense ve Servis Temizligi"
# ================================================

# Storage Sense - guvenli versiyon (sadece recycle bin otomatik)
Write-Step "Storage Sense aciliyor (guvenli mod)..."
$ssPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy"
Initialize-Path $ssPath
Set-ItemProperty $ssPath -Name "01"   -Value 1  -Type DWord -ErrorAction SilentlyContinue
Set-ItemProperty $ssPath -Name "2048" -Value 30 -Type DWord -ErrorAction SilentlyContinue
Write-Ok "Storage Sense aktif (recycle bin 30 gun otomatik bosaltma)."

# DiagTrack servisi kapat
Write-Step "DiagTrack (telemetri) servisi kapatiliyor..."
try {
    Stop-Service DiagTrack -Force -ErrorAction SilentlyContinue
    Set-Service DiagTrack -StartupType Disabled -ErrorAction SilentlyContinue
    Write-Ok "DiagTrack kapatildi."
} catch {
    Write-Fail "DiagTrack ayarlanamadi."
}

# Xbox servisleri kapat
Write-Step "Xbox servisleri kapatiliyor..."
$xboxServices = @("XblAuthManager", "XblGameSave", "XboxGipSvc", "XboxNetApiSvc")
foreach ($svc in $xboxServices) {
    try {
        Stop-Service $svc -Force -ErrorAction SilentlyContinue
        Set-Service $svc -StartupType Disabled -ErrorAction SilentlyContinue
        Write-Ok "$svc kapatildi."
    } catch {
        Write-Info "$svc bulunamadi veya zaten kapali."
    }
}

# ================================================
Section "ADIM 11/12 — SSD TRIM"
# ================================================

# TRIM aktif mi kontrol et
Write-Step "TRIM ayari kontrol ediliyor..."
$trimStatus = (fsutil behavior query DisableDeleteNotify) -join " "
if ($trimStatus -match "NTFS\s+DisableDeleteNotify\s*=\s*0") {
    Write-Ok "TRIM aktif (NTFS DisableDeleteNotify = 0)."
} else {
    Write-Fail "TRIM kapali gozukuyor. Aktif ediliyor..."
    fsutil behavior set DisableDeleteNotify NTFS 0 | Out-Null
    Write-Ok "TRIM aktif edildi."
}

Write-Step "Sistem diski tipi kontrol ediliyor..."
try {
    $sysDrive = (Get-Partition -DriveLetter C -ErrorAction Stop).DiskNumber
    $mediaType = (Get-PhysicalDisk | Where-Object DeviceID -eq $sysDrive).MediaType

    if ($mediaType -eq "SSD") {
        Write-Info "SSD tespit edildi. TRIM calistiriliyor..."
        Optimize-Volume -DriveLetter C -ReTrim -Verbose
        Write-Ok "TRIM tamamlandi."
    } elseif ($mediaType -eq "HDD") {
        Write-Info "HDD tespit edildi. TRIM atlanacak."
        Write-Info "HDD icin defrag istersen manuel: Optimize-Volume -DriveLetter C -Defrag"
    } else {
        Write-Info "Disk tipi belirsiz ($mediaType). TRIM yine de deneniyor (zararsiz)..."
        Optimize-Volume -DriveLetter C -ReTrim -Verbose -ErrorAction SilentlyContinue
    }
} catch {
    Write-Fail "Disk tipi algilanamadi: $_"
    Write-Info "ReTrim yine de deneniyor..."
    Optimize-Volume -DriveLetter C -ReTrim -ErrorAction SilentlyContinue
}

# ================================================
Section "ADIM 12/12 — SMART Disk Saglik Kontrolu"
# ================================================

Write-Step "Tum fiziksel diskler taraniyor..."
try {
    $disks = Get-PhysicalDisk -ErrorAction Stop
    foreach ($d in $disks) {
        $line = "  Disk: $($d.FriendlyName.Trim()) | Tip: $($d.MediaType) | Saglik: $($d.HealthStatus) | Durum: $($d.OperationalStatus)"
        Add-Content -Path $logFile -Value "[$(Get-Date -Format 'HH:mm:ss')] $line"

        if ($d.HealthStatus -eq "Healthy") {
            Write-Host $line -ForegroundColor Green
        } elseif ($d.HealthStatus -eq "Warning") {
            Write-Host $line -ForegroundColor Yellow
            Write-Fail "DIKKAT: Diskte uyari var, yedek al!"
        } else {
            Write-Host $line -ForegroundColor Red
            Write-Fail "KRITIK: Disk saglik sorunu! Hemen yedek al ve degistirmeyi dusun."
        }
    }
    Write-Ok "SMART kontrol tamamlandi."
} catch {
    Write-Fail "Disk bilgisi alinamadi: $_"
}

# ================================================
#  TAMAMLANDI
# ================================================

Section "TAMAMLANDI"

$diskAfter = (Get-PSDrive C).Free / 1GB
$saved = $diskAfter - $diskBefore

Write-Host ""
Write-Host "  BITTI." -ForegroundColor Green
Write-Host ""
Write-Host ("  Baslangic bos alan : {0:N2} GB" -f $diskBefore) -ForegroundColor White
Write-Host ("  Bitis bos alan     : {0:N2} GB" -f $diskAfter)  -ForegroundColor White
Write-Host ("  Kazanilan alan     : {0:N2} GB" -f $saved)      -ForegroundColor Green
Write-Host ""
Write-Host "  Log dosyasi: $logFile" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  TAVSIYE: Bilgisayari simdi yeniden baslat." -ForegroundColor Yellow
Write-Host "          fsutil ve registry degisiklikleri tam otursun." -ForegroundColor Yellow
Write-Host ""
