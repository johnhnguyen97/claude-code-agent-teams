$promptFile = $args[0]
if (-not $promptFile) {
    Write-Host "Please provide a prompt file."
    exit 1
}

# Add psmux to PATH (belt-and-suspenders if not in permanent User PATH)
$env:PATH = "$env:LOCALAPPDATA\psmux;" + $env:PATH

# CRITICAL: Unset CLAUDECODE env var to prevent "nested session" detection.
# Without this, Claude refuses to start with "cannot be launched inside another session".
$env:CLAUDECODE = $null
Remove-Item Env:\CLAUDECODE -ErrorAction SilentlyContinue

Write-Host "=== Claude Code Agent Team Launcher ===" -ForegroundColor Cyan
Write-Host "Prompt file: $promptFile" -ForegroundColor DarkGray
Write-Host "Working dir: $(Get-Location)" -ForegroundColor DarkGray
Write-Host ""

$prompt = Get-Content $promptFile -Raw
Write-Host "Prompt loaded: $($prompt.Length) chars" -ForegroundColor DarkGray
Write-Host "Launching claude..." -ForegroundColor Yellow
Write-Host ""

# --dangerously-skip-permissions: shows a one-time terms dialog for the lead.
# Accept it once, then all spawned teammates inherit the setting automatically.
claude --dangerously-skip-permissions $prompt

Write-Host ""
Write-Host "=== Agent team session ended ===" -ForegroundColor Cyan
Read-Host "Press Enter to exit..."
