# ================================================
#  AFTER FORMAT — 1/3: SURUCUDEN ONCE.
#  Chrome Kur + Varsayilan Tarayici Ayarla
# ================================================

$ErrorActionPreference = "Continue"
$rootDir = Split-Path $PSScriptRoot -Parent
$logFile = "$rootDir\log.txt"

$banner = @"

#################################################################
#                                                               #
#   SCRIPT 1/3 — SURUCUDEN ONCE                                 #
#   Baslangic: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')        #
#                                                               #
#################################################################

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

# ================================================
Section "ADIM 1/2 — Chrome Kur"
# ================================================

$chromeInstalled = $false

# Once winget ile dene (hazirsa hizli)
Write-Step "Chrome winget ile deneniyor..."
winget install --id Google.Chrome --exact --silent `
    --accept-source-agreements --accept-package-agreements 2>&1 | Out-Null

if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq -1978335189) {
    Write-Ok "Chrome kuruldu (winget)."
    $chromeInstalled = $true
} else {
    # Fallback: Google CDN'den dogrudan indir
    Write-Info "winget basarisiz, Google CDN'den indiriliyor..."
    $chromeUrl = "https://dl.google.com/chrome/install/ChromeSetup.exe"
    $chromeExe = "$env:TEMP\ChromeSetup.exe"
    try {
        Invoke-WebRequest -Uri $chromeUrl -OutFile $chromeExe -UseBasicParsing -TimeoutSec 60
        Write-Step "Chrome kuruluyor (CDN installer)..."
        Start-Process $chromeExe -ArgumentList "/silent /install" -Wait -NoNewWindow
        Remove-Item $chromeExe -Force -ErrorAction SilentlyContinue
        Write-Ok "Chrome kuruldu (CDN)."
        $chromeInstalled = $true
    } catch {
        Write-Fail "Chrome kurulamadi: $_"
        Write-Info "Chrome'u elle kur: https://www.google.com/chrome"
    }
}

# ================================================
Section "ADIM 2/2 — Chrome Varsayilan Tarayici Yap"
# ================================================

if (-not $chromeInstalled) {
    Write-Info "Chrome kurulu degil, varsayilan ayari atlaniyor."
    Write-Info "Chrome'u kurduktan sonra: Ayarlar > Uygulamalar > Varsayilan uygulamalar > Chrome"
} else {
    # PS-SFTA: SetUserFTA'nin acik kaynak PS alternatifi (GitHub)
    Write-Step "PS-SFTA indiriliyor (varsayilan tarayici ayari icin)..."
    $sftaUrl  = "https://raw.githubusercontent.com/DanysysTeam/PS-SFTA/master/SFTA.ps1"
    $sftaPath = "$env:TEMP\SFTA.ps1"
    $sftaOk   = $false

    try {
        Invoke-WebRequest -Uri $sftaUrl -OutFile $sftaPath -UseBasicParsing -TimeoutSec 30
        . $sftaPath
        $sftaOk = $true
        Write-Ok "PS-SFTA hazir."
    } catch {
        Write-Fail "PS-SFTA indirilemedi: $_"
        Write-Info "Varsayilan tarayici ayarini elle yap:"
        Write-Info "Ayarlar > Uygulamalar > Varsayilan uygulamalar > Google Chrome"
    }

    if ($sftaOk) {
        Write-Step "Chrome varsayilan tarayici yapiliyor..."

        $fileAssoc = @{
            ".htm"   = "ChromeHTML"
            ".html"  = "ChromeHTML"
            ".mhtml" = "ChromeHTML"
            ".mht"   = "ChromeHTML"
            ".pdf"   = "ChromeHTML"
            ".svg"   = "ChromeHTML"
            ".webp"  = "ChromeHTML"
        }
        foreach ($ext in $fileAssoc.Keys) {
            try {
                Set-FTA -ProgId $fileAssoc[$ext] -Protocol $ext -ErrorAction Stop
                Write-Ok "$ext -> Chrome"
            } catch {
                Write-Fail "$ext atanamadi"
            }
        }

        $protoAssoc = @("http", "https", "ftp")
        foreach ($proto in $protoAssoc) {
            try {
                Set-PTA -ProgId "ChromeHTML" -Protocol $proto -ErrorAction Stop
                Write-Ok "$proto -> Chrome"
            } catch {
                Write-Fail "$proto atanamadi"
            }
        }

        Remove-Item $sftaPath -Force -ErrorAction SilentlyContinue
        Write-Ok "Varsayilan tarayici ayarlandi."
    }
}

# ------------------------------------------------
Section "TAMAMLANDI"
# ------------------------------------------------

Write-Host ""
Write-Host "  BITTI." -ForegroundColor Green
Write-Host ""
Write-Host "  Log dosyasi: $logFile" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  SIRADAKI ADIMLAR:" -ForegroundColor Cyan
Write-Host "  1. Suruculeri kur (anakart, GPU, ses, ag) ve her birinden" -ForegroundColor White
Write-Host "     sonra res at." -ForegroundColor White
Write-Host "  2. Tum suruculer bitince 2_surucuden_sonra.bat calistir." -ForegroundColor White
Write-Host "  3. En son 3_temizlik.bat calistir." -ForegroundColor White
Write-Host ""
