$promptFile = $args[0]
if (-not $promptFile) {
    Write-Host "Please provide a prompt file."
    exit 1
}

# Add Git's /usr/bin FIRST so "env" resolves to bash's env, not psmux's env.cmd shim.
# Then add psmux to PATH for psmux.exe access.
$env:PATH = "C:\Program Files\Git\usr\bin;$env:LOCALAPPDATA\psmux;" + $env:PATH

# Unset CLAUDECODE env var to prevent "nested session" detection
$env:CLAUDECODE = $null
Remove-Item Env:\CLAUDECODE -ErrorAction SilentlyContinue

# CRITICAL: Set SHELL to Git Bash so psmux spawns teammate panes in bash (not PowerShell).
# Claude Code generates bash-style teammate commands (env KEY=VAL, &&, etc.) that fail in PowerShell.
$env:SHELL = "C:\Program Files\Git\bin\bash.exe"

# Force Git identity for all teammates (inherits to child processes)
$env:GIT_AUTHOR_NAME = "John Nguyen"
$env:GIT_AUTHOR_EMAIL = "your-email@example.com"
$env:GIT_COMMITTER_NAME = "John Nguyen"
$env:GIT_COMMITTER_EMAIL = "your-email@example.com"

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
