# Run after installing Flutter SDK
# Generates any missing platform files and fetches dependencies

$ErrorActionPreference = "Stop"
$MobileDir = Join-Path $PSScriptRoot "..\mobile"

Write-Host "Setting up AI Jyotish Guru mobile app..." -ForegroundColor Cyan

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Host "Flutter not found in PATH." -ForegroundColor Red
    Write-Host "Install Flutter: https://docs.flutter.dev/get-started/install/windows"
    Write-Host "Then re-run: .\scripts\setup_mobile.ps1"
    exit 1
}

Set-Location $MobileDir

# Merge platform files if needed
flutter create . --project-name ai_jyotish_guru --org com.aijyotish

flutter pub get

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Green
Write-Host "1. Copy android/local.properties.example to android/local.properties"
Write-Host "2. Add google-services.json to android/app/"
Write-Host "3. Add GoogleService-Info.plist to ios/Runner/"
Write-Host "4. flutter run"
