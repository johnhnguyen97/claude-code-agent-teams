$promptFile = $args[0]
if (-not $promptFile) {
    Write-Host "Please provide a prompt file."
    exit 1
}

# Add psmux to PATH
$env:PATH = "$env:LOCALAPPDATA\psmux;" + $env:PATH

Write-Host "Initializing Agent Team..."
$prompt = Get-Content $promptFile -Raw

# Launch Claude fully automated
claude --dangerously-skip-permissions $prompt

Write-Host "
Session ended."
Read-Host "Press Enter to exit..."
