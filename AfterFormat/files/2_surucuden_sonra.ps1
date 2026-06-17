# ================================================
#  AFTER FORMAT — 2/3: SURUCUDEN SONRA.
#  Programlar + Sistem Ayarlari + Bloatware
# ================================================

$ErrorActionPreference = "Continue"
$rootDir = Split-Path $PSScriptRoot -Parent
$logFile = "$rootDir\log.txt"

$banner = @"

################################################################
#                                                              #
#   SCRIPT 2/3 — SURUCUDEN SONRA                               #
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

# ================================================
Section "ADIM 1/9 — Sistem Geri Yukleme Noktasi"
# ================================================

Write-Step "System Restore aktif ediliyor..."
try {
    Enable-ComputerRestore -Drive "C:\" -ErrorAction Stop
    Write-Ok "System Restore aktif."
} catch {
    Write-Info "System Restore zaten aktif veya degisiklik gerekmiyor."
}

# Default'ta 24 saatte bir restore point sinirlamasi var, kaldir
$srpPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore"
Initialize-Path $srpPath
Set-ItemProperty $srpPath -Name "SystemRestorePointCreationFrequency" -Value 0 -Type DWord -ErrorAction SilentlyContinue

Write-Step "Geri yukleme noktasi olusturuluyor..."
try {
    Checkpoint-Computer -Description "Pre-AfterFormat-Tweaks" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
    Write-Ok "Restore point olusturuldu: 'Pre-AfterFormat-Tweaks'"
} catch {
    Write-Fail "Restore point olusturulamadi: $_"
    Write-Info "Devam ediliyor (kritik degil)."
}

# ================================================
Section "ADIM 2/9 — Diger Programlar"
# ================================================

$jsonPath = "$PSScriptRoot\programs.json"
if (!(Test-Path $jsonPath)) {
    Write-Fail "programs.json bulunamadi: $jsonPath"
} else {
    $programs = Get-Content $jsonPath -Raw | ConvertFrom-Json

    # Toplam program sayisi (Chrome haric)
    $totalPrograms = 0
    foreach ($category in $programs.PSObject.Properties) {
        foreach ($prog in $category.Value) {
            if ($prog.id -ne "Google.Chrome") { $totalPrograms++ }
        }
    }
    Write-Info "Toplam $totalPrograms program kurulacak."
    $current = 0

    foreach ($category in $programs.PSObject.Properties) {
        Write-Step "--- $($category.Name.ToUpper()) ---"
        foreach ($prog in $category.Value) {
            if ($prog.id -eq "Google.Chrome") { continue }
            $current++
            Write-Step "[$current/$totalPrograms] Kuruluyor: $($prog.name)"

            # winget'in indirme yuzdesi canli gorunsun diye Out-String yok
            winget install --id $prog.id --exact --silent `
                --accept-source-agreements --accept-package-agreements
            $exitCode = $LASTEXITCODE

            if ($exitCode -eq 0) {
                Write-Ok "$($prog.name) kuruldu."
            } elseif ($exitCode -eq -1978335189) {
                # winget'in "already installed" exit kodu
                Write-Info "$($prog.name) zaten yuklu."
            } else {
                Write-Fail "$($prog.name) kurulamadi (exit kodu: $exitCode)."
            }
        }
    }
}

# ================================================
Section "ADIM 3/9 — Bloatware ve OneDrive Kaldir"
# ================================================

# --- OneDrive ozel kaldirma ---
Write-Step "OneDrive kaldiriliyor..."
taskkill /f /im OneDrive.exe 2>$null | Out-Null

$onedriveSetup = if ([Environment]::Is64BitOperatingSystem) {
    "$env:SystemRoot\SysWOW64\OneDriveSetup.exe"
} else {
    "$env:SystemRoot\System32\OneDriveSetup.exe"
}

if (Test-Path $onedriveSetup) {
    Start-Process $onedriveSetup -ArgumentList "/uninstall" -Wait -NoNewWindow -ErrorAction SilentlyContinue
    Write-Ok "OneDrive uninstaller calisti."
} else {
    # Fallback: winget
    winget uninstall Microsoft.OneDrive --silent 2>&1 | Out-Null
}

# Artik klasorler
Remove-Item "$env:USERPROFILE\OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "$env:LOCALAPPDATA\Microsoft\OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "$env:PROGRAMDATA\Microsoft OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "C:\OneDriveTemp" -Recurse -Force -ErrorAction SilentlyContinue
Write-Ok "OneDrive klasorleri temizlendi."

# Explorer'da OneDrive girisini kaldir
Remove-Item "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" -Recurse -Force -ErrorAction SilentlyContinue
Write-Ok "OneDrive Explorer girisi kaldirildi."

# --- Diger Bloatware ---
Write-Step "--- Diger bloatware paketleri ---"

$bloatware = @(
    "Microsoft.XboxApp",
    "Microsoft.XboxGameOverlay",
    "Microsoft.XboxGamingOverlay",
    "Microsoft.XboxIdentityProvider",
    "Microsoft.XboxSpeechToTextOverlay",
    "Microsoft.GamingApp",
    "Microsoft.YourPhone",
    "Microsoft.549981C3F5F10",
    "Microsoft.WindowsFeedbackHub",
    "Microsoft.GetHelp",
    "Microsoft.Getstarted",
    "Microsoft.BingNews",
    "Microsoft.BingWeather",
    "Microsoft.MicrosoftSolitaireCollection",
    "Clipchamp.Clipchamp",
    "MicrosoftTeams",
    "MicrosoftCorporationII.QuickAssist",
    "Microsoft.ZuneMusic",
    "Microsoft.ZuneVideo",
    "Microsoft.People"
)

foreach ($app in $bloatware) {
    $pkg = Get-AppxPackage -Name $app -AllUsers -ErrorAction SilentlyContinue
    if ($pkg) {
        Remove-AppxPackage -Package $pkg.PackageFullName -AllUsers -ErrorAction SilentlyContinue
        Write-Ok "$app kaldirildi."
    } else {
        Write-Info "$app zaten yok."
    }
}

# ================================================
Section "ADIM 4/9 — Gorev Cubugu Ayarlari"
# ================================================

$advPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
Initialize-Path $advPath

# Widgets kapat
Set-ItemProperty $advPath -Name "TaskbarDa"           -Value 0
Write-Ok "Widgets kapatildi."

# Task View butonu kaldır
Set-ItemProperty $advPath -Name "ShowTaskViewButton"  -Value 0
Write-Ok "Task View butonu kaldirildi."

# Sağ tık görev sonlandır
Set-ItemProperty $advPath -Name "TaskbarEndTask"      -Value 1
Write-Ok "Gorev sonlandir acildi."

# Search kutusunu gizle (0=gizle, 1=ikon, 2=kutu)
$searchPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"
Initialize-Path $searchPath
Set-ItemProperty $searchPath -Name "SearchboxTaskbarMode" -Value 0
Write-Ok "Search kutusu gizlendi."

# Chat/Teams butonu kaldır
Set-ItemProperty $advPath -Name "TaskbarMn"           -Value 0
Write-Ok "Chat/Teams butonu kaldirildi."

# Pano geçmişi
$clipPath = "HKCU:\Software\Microsoft\Clipboard"
Initialize-Path $clipPath
Set-ItemProperty $clipPath -Name "EnableClipboardHistory" -Value 1
Write-Ok "Pano gecmisi acildi (Win+V)."

# ================================================
Section "ADIM 5/9 — Explorer Ayarlari"
# ================================================

# Dosya uzantılarını göster
Set-ItemProperty $advPath -Name "HideFileExt"         -Value 0
Write-Ok "Dosya uzantilari gorunur."

# Gizli dosyaları göster
Set-ItemProperty $advPath -Name "Hidden"              -Value 1
Write-Ok "Gizli dosyalar gorunur."

# Ayrı process
Set-ItemProperty $advPath -Name "SeparateProcess"     -Value 1
Write-Ok "Ayri process aktif."

# Full path in title bar
$cabinetPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\CabinetState"
Initialize-Path $cabinetPath
Set-ItemProperty $cabinetPath -Name "FullPath"        -Value 1
Write-Ok "Baslik cubugunda tam yol gorunuyor."

# Explorer varsayılan This PC (1=This PC, 2=Quick Access)
$explorerPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer"
Set-ItemProperty $explorerPath -Name "LaunchTo"       -Value 1
Write-Ok "Explorer This PC ile aciliyor."

# Start menüde web araması kapat
Set-ItemProperty $searchPath -Name "BingSearchEnabled"  -Value 0
Set-ItemProperty $searchPath -Name "CortanaConsent"     -Value 0
Write-Ok "Start menusunde web aramasi kapatildi."

# Masaüstü ikonları
$desktopPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel"
Initialize-Path $desktopPath
Set-ItemProperty $desktopPath -Name "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" -Value 0  # This PC
Set-ItemProperty $desktopPath -Name "{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}" -Value 0  # Network
Set-ItemProperty $desktopPath -Name "{5399E694-6CE5-4D6C-8FCE-1D8870FDCBA0}" -Value 0  # Control Panel
Set-ItemProperty $desktopPath -Name "{645FF040-5081-101B-9F08-00AA002F954E}" -Value 0  # Recycle Bin
Write-Ok "Masaustu ikonlari ayarlandi."

# Klasik sağ tık menüsü
try {
    $clsidPath = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32"
    Initialize-Path $clsidPath
    Set-ItemProperty $clsidPath -Name "(Default)" -Value ""
    Write-Ok "Klasik sag tik menusu aktif."
} catch {
    Write-Fail "Sag tik menusu ayarlanamadi."
}

# Navigation pane: Home ve Gallery gizle
try {
    $homeCLSID    = "{f874310e-b6b7-47dc-bc84-b9e6b38f5903}"
    $galleryCLSID = "{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}"
    $nsPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\$homeCLSID",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\$galleryCLSID",
        "HKCU:\Software\Classes\CLSID\$homeCLSID",
        "HKCU:\Software\Classes\CLSID\$galleryCLSID"
    )
    foreach ($p in $nsPaths) {
        if (Test-Path $p) {
            Remove-Item $p -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    Write-Ok "Navigation pane: Home ve Gallery gizlendi."
} catch {
    Write-Fail "Navigation pane ayarlanamadi."
}

# ================================================
Section "ADIM 6/9 — Gizlilik, Telemetri ve Lock Screen Reklamlari"
# ================================================

$cdmPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
Initialize-Path $cdmPath

# Suggestions / öneriler / reklamlar
$cdmKeys = @(
    "ContentDeliveryAllowed", "OemPreInstalledAppsEnabled", "PreInstalledAppsEnabled",
    "PreInstalledAppsEverEnabled", "SilentInstalledAppsEnabled", "SystemPaneSuggestionsEnabled",
    "SubscribedContent-310093Enabled", "SubscribedContent-314559Enabled",
    "SubscribedContent-338387Enabled", "SubscribedContent-338388Enabled",
    "SubscribedContent-338389Enabled", "SubscribedContent-338393Enabled",
    "SubscribedContent-353698Enabled", "SubscribedContent-353696Enabled"
)
foreach ($key in $cdmKeys) {
    Set-ItemProperty $cdmPath -Name $key -Value 0 -ErrorAction SilentlyContinue
}
Write-Ok "Onerimler / reklamlar kapatildi."

# Advertising ID
$advIdPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo"
Initialize-Path $advIdPath
Set-ItemProperty $advIdPath -Name "Enabled" -Value 0
Write-Ok "Reklam ID kapatildi."

# Activity history
$actPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
Initialize-Path $actPath
Set-ItemProperty $actPath -Name "EnableActivityFeed"        -Value 0 -ErrorAction SilentlyContinue
Set-ItemProperty $actPath -Name "PublishUserActivities"     -Value 0 -ErrorAction SilentlyContinue
Set-ItemProperty $actPath -Name "UploadUserActivities"      -Value 0 -ErrorAction SilentlyContinue
Write-Ok "Activity history kapatildi."

# Feedback frequency
$siufPath = "HKCU:\Software\Microsoft\Siuf\Rules"
Initialize-Path $siufPath
Set-ItemProperty $siufPath -Name "NumberOfSIUFInPeriod" -Value 0
Write-Ok "Feedback kapatildi."

# Telemetry
$telPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection"
Initialize-Path $telPath
Set-ItemProperty $telPath -Name "AllowTelemetry"           -Value 1
Set-ItemProperty $telPath -Name "MaxTelemetryAllowed"      -Value 1
Write-Ok "Telemetry minimum seviyede."

# Inking & typing
$inkPath = "HKCU:\Software\Microsoft\InputPersonalization"
Initialize-Path $inkPath
Set-ItemProperty $inkPath -Name "RestrictImplicitInkCollection"  -Value 1
Set-ItemProperty $inkPath -Name "RestrictImplicitTextCollection" -Value 1
$inkStorePath = "HKCU:\Software\Microsoft\InputPersonalization\TrainedDataStore"
Initialize-Path $inkStorePath
Set-ItemProperty $inkStorePath -Name "HarvestContacts" -Value 0 -ErrorAction SilentlyContinue
Write-Ok "Inking & typing personalization kapatildi."

# Background apps
$bgPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications"
Initialize-Path $bgPath
Set-ItemProperty $bgPath -Name "GlobalUserDisabled" -Value 1 -ErrorAction SilentlyContinue
Write-Ok "Background apps kapatildi."

# "Get even more out of Windows" ekranı
$engagePath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement"
Initialize-Path $engagePath
Set-ItemProperty $engagePath -Name "ScoobeSystemSettingEnabled" -Value 0 -ErrorAction SilentlyContinue
Write-Ok "Get even more out of Windows ekrani kapatildi."

# Lock Screen reklamlari ve "fun facts"
Set-ItemProperty $cdmPath -Name "RotatingLockScreenEnabled"        -Value 0 -ErrorAction SilentlyContinue
Set-ItemProperty $cdmPath -Name "RotatingLockScreenOverlayEnabled" -Value 0 -ErrorAction SilentlyContinue
Write-Ok "Lock screen reklamlari ve fun facts kapatildi."

# Spotlight (kilit ekraninda Bing resimleri uzerine reklam)
$ccPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
Initialize-Path $ccPath
Set-ItemProperty $ccPath -Name "DisableWindowsConsumerFeatures" -Value 1 -Type DWord -ErrorAction SilentlyContinue
Set-ItemProperty $ccPath -Name "DisableSoftLanding"             -Value 1 -Type DWord -ErrorAction SilentlyContinue
Write-Ok "Windows Consumer Features (Spotlight, App Suggestions) kapatildi."

# Settings sayfasinda "Suggested content" reklamlari
Set-ItemProperty $cdmPath -Name "SubscribedContent-338393Enabled" -Value 0 -ErrorAction SilentlyContinue
Set-ItemProperty $cdmPath -Name "SubscribedContent-353694Enabled" -Value 0 -ErrorAction SilentlyContinue
Set-ItemProperty $cdmPath -Name "SubscribedContent-353696Enabled" -Value 0 -ErrorAction SilentlyContinue
Write-Ok "Settings sayfasi reklamlari kapatildi."

# ================================================
Section "ADIM 7/9 — Edge Daraltma"
# ================================================

$edgePath = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"
Initialize-Path $edgePath

# Edge'in sidebar / hub / Copilot / shopping bloatware'i
Set-ItemProperty $edgePath -Name "HubsSidebarEnabled"           -Value 0 -Type DWord -ErrorAction SilentlyContinue
Set-ItemProperty $edgePath -Name "ShowRecommendationsEnabled"   -Value 0 -Type DWord -ErrorAction SilentlyContinue
Set-ItemProperty $edgePath -Name "EdgeShoppingAssistantEnabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue
Set-ItemProperty $edgePath -Name "PersonalizationReportingEnabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue
Set-ItemProperty $edgePath -Name "SearchSuggestEnabled"         -Value 0 -Type DWord -ErrorAction SilentlyContinue
Set-ItemProperty $edgePath -Name "MetricsReportingEnabled"      -Value 0 -Type DWord -ErrorAction SilentlyContinue
Set-ItemProperty $edgePath -Name "DiagnosticData"               -Value 0 -Type DWord -ErrorAction SilentlyContinue
Set-ItemProperty $edgePath -Name "WalletDonationEnabled"        -Value 0 -Type DWord -ErrorAction SilentlyContinue
Write-Ok "Edge sidebar, hubs, shopping, telemetri kapatildi."

# Edge first-run experience kapat (yeni acan kullaniciya reklam)
Set-ItemProperty $edgePath -Name "HideFirstRunExperience" -Value 1 -Type DWord -ErrorAction SilentlyContinue
Write-Ok "Edge first-run ekrani kapatildi."

# Edge'in startup boost'u (oturum acinca arkaplanda baslamasi)
Set-ItemProperty $edgePath -Name "StartupBoostEnabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue
Set-ItemProperty $edgePath -Name "BackgroundModeEnabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue
Write-Ok "Edge startup boost ve background mode kapatildi."

# NOT: Edge'in update'i acik biraktik (guvenlik). Sadece bloatware kapali.

# ================================================
Section "ADIM 8/8 — Gelistirici + Ag + Windows Terminal Default"
# ================================================

# Developer Mode
$devPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock"
Initialize-Path $devPath
Set-ItemProperty $devPath -Name "AllowDevelopmentWithoutDevLicense" -Value 1
Write-Ok "Developer Mode acildi."

# Long path support
Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" `
    -Name "LongPathsEnabled" -Value 1
Write-Ok "Long path support acildi (260 karakter siniri kaldirildi)."

# PowerShell execution policy
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
Write-Ok "PowerShell execution policy: RemoteSigned"

# NetBIOS kapat
try {
    $adapters = Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration -ErrorAction Stop |
                Where-Object { $_.TcpipNetbiosOptions -ne $null }
    foreach ($adapter in $adapters) {
        Invoke-CimMethod -InputObject $adapter -MethodName SetTcpipNetbios -Arguments @{ TcpipNetbiosOptions = [uint32]2 } | Out-Null
    }
    Write-Ok "NetBIOS over TCP/IP kapatildi."
} catch {
    Write-Fail "NetBIOS ayarlanamadi: $_"
}

# Ağ keşfi Public'te kapat
try {
    netsh advfirewall firewall set rule group="Network Discovery" new enable=No 2>&1 | Out-Null
    Write-Ok "Ag kesfi (public) kapatildi."
} catch {
    Write-Fail "Ag kesfi ayarlanamadi."
}

# Windows Terminal varsayilan terminal yap
Write-Step "Windows Terminal varsayilan terminal yapiliyor..."
$consolePath = "HKCU:\Console\%%Startup"
Initialize-Path $consolePath
# Windows Terminal'in resmi CLSID'leri
Set-ItemProperty $consolePath -Name "DelegationConsole"  -Value "{2EACA947-7F5F-4CFA-BA87-8F7FBEEFBE69}" -ErrorAction SilentlyContinue
Set-ItemProperty $consolePath -Name "DelegationTerminal" -Value "{E12CFF52-A866-4C77-9A90-F570A7AA2C6B}" -ErrorAction SilentlyContinue
Write-Ok "Windows Terminal varsayilan (PS7 / cmd / wsl artik onunla acilacak)."

# ================================================
#  TAMAMLANDI
# ================================================

Section "TAMAMLANDI"

# Registry degisikliklerinin gorunmesi icin Explorer'i yenile
Write-Step "Explorer yenileniyor (registry degisikliklerinin gorunmesi icin)..."
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1
Start-Process explorer
Write-Ok "Explorer yenilendi."

Write-Host ""
Write-Host "  BITTI." -ForegroundColor Green
Write-Host ""
Write-Host "  Log dosyasi: $logFile" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  SIRADAKI ADIM:" -ForegroundColor Cyan
Write-Host "  3_temizlik.bat calistir (disk temizligi + performans)." -ForegroundColor White
Write-Host ""
