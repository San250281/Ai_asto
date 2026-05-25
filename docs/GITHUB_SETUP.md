# Push to GitHub

## Option 1: PowerShell script (recommended)

1. Create an empty repo on GitHub named **Ai_asto** (no README).

2. Run:

```powershell
cd d:\Ai_Kundli\Ai_asto
.\scripts\push_github.ps1 -GitHubUsername YOUR_GITHUB_USERNAME
```

With GitHub CLI installed:

```powershell
.\scripts\push_github.ps1 -GitHubUsername YOUR_GITHUB_USERNAME -CreateRepo
```

## Option 2: Manual

```powershell
cd d:\Ai_Kundli\Ai_asto
git remote add origin https://github.com/YOUR_USERNAME/Ai_asto.git
git branch -M main
git push -u origin main
```

## Authentication

- **HTTPS + PAT**: Use a [Personal Access Token](https://github.com/settings/tokens) as password.
- **SSH**: `git remote set-url origin git@github.com:USER/Ai_asto.git`

## Mobile setup after clone

```powershell
.\scripts\setup_mobile.ps1
```
