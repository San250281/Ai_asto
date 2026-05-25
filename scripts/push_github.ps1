param(
    [Parameter(Mandatory = $true)]
    [string]$GitHubUsername,

    [string]$RepoName = "Ai_asto",
    [switch]$CreateRepo
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Join-Path $PSScriptRoot ".."
Set-Location $ProjectRoot

$RemoteUrl = "https://github.com/$GitHubUsername/$RepoName.git"

if (-not (git remote get-url origin 2>$null)) {
    git remote add origin $RemoteUrl
    Write-Host "Added remote: $RemoteUrl" -ForegroundColor Green
} else {
    git remote set-url origin $RemoteUrl
    Write-Host "Updated remote: $RemoteUrl" -ForegroundColor Green
}

git branch -M main

if ($CreateRepo) {
    if (Get-Command gh -ErrorAction SilentlyContinue) {
        gh repo create $RepoName --public --source=. --remote=origin --push
        Write-Host "Repository created and pushed!" -ForegroundColor Green
        exit 0
    } else {
        Write-Host "GitHub CLI (gh) not installed." -ForegroundColor Yellow
        Write-Host "Create repo manually: https://github.com/new?name=$RepoName"
        Write-Host "Then run: git push -u origin main"
        exit 1
    }
}

Write-Host "Pushing to $RemoteUrl ..." -ForegroundColor Cyan
git push -u origin main

if ($LASTEXITCODE -eq 0) {
    Write-Host "Success! https://github.com/$GitHubUsername/$RepoName" -ForegroundColor Green
} else {
    Write-Host "Push failed. Ensure the repo exists and you are authenticated." -ForegroundColor Red
    Write-Host "Options:"
    Write-Host "  - GitHub Desktop"
    Write-Host "  - Personal Access Token: git remote set-url origin https://TOKEN@github.com/$GitHubUsername/$RepoName.git"
    Write-Host "  - SSH: git remote set-url origin git@github.com:$GitHubUsername/$RepoName.git"
}
