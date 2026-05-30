param(
    [Parameter(Mandatory = $true)]
    [string]$ApiUrl,

    [string]$MobileDir = (Join-Path $PSScriptRoot "..\mobile")
)

$ErrorActionPreference = "Stop"

Write-Host "AI Jyotish Guru - Play Store Build" -ForegroundColor Cyan

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Host "Flutter not found. Install from https://docs.flutter.dev/get-started/install/windows" -ForegroundColor Red
    exit 1
}

$keyProps = Join-Path $MobileDir "android\key.properties"
if (-not (Test-Path $keyProps)) {
    Write-Host "WARNING: android/key.properties not found." -ForegroundColor Yellow
    Write-Host "Create signing key first. See docs/PLAY_STORE_DEPLOYMENT.md" -ForegroundColor Yellow
    $continue = Read-Host "Continue with debug signing? (y/N)"
    if ($continue -ne "y") { exit 1 }
}

Set-Location $MobileDir

Write-Host "Fetching dependencies..." -ForegroundColor Gray
flutter pub get

Write-Host "Building App Bundle (release)..." -ForegroundColor Gray
Write-Host "API URL: $ApiUrl" -ForegroundColor Gray

flutter build appbundle --release --dart-define=API_BASE_URL=$ApiUrl

$aab = Join-Path $MobileDir "build\app\outputs\bundle\release\app-release.aab"
if (Test-Path $aab) {
    Write-Host ""
    Write-Host "SUCCESS! Upload this file to Google Play Console:" -ForegroundColor Green
    Write-Host $aab -ForegroundColor White
    Write-Host ""
    Write-Host "Next: Play Console -> Release -> Production -> Upload AAB" -ForegroundColor Cyan
} else {
    Write-Host "Build finished but AAB not found at expected path." -ForegroundColor Red
    exit 1
}
