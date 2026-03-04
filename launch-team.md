---
description: Launch an automated Claude Agent Team in a Psmux split-window session
---

# Agent Team Launcher (`/launch-team`)

This workflow launches a multi-agent Claude Team inside a native `psmux` window on Windows. It bypasses the interactive Windows Terminal blockages and automatically skips tool permission prompts for a fully autonomous parallel team session.

## Prerequisites
1. You must have `psmux` installed (`$env:LOCALAPPDATA\psmux\psmux.exe`).
2. You must have a prompt file detailing the tasks for each agent.
3. Your `~/.claude/settings.json` should have `"teammateMode": "tmux"`.

## Usage
1. Open this repo directory in your terminal.
2. Launch the team in a new terminal window:

```powershell
$promptPath = Read-Host "Enter the absolute path to your prompt file (e.g. C:\tmp\example_team_prompt.txt)"
$scriptPath = Join-Path $PWD "run_in_psmux.ps1"
$psmuxPath = Join-Path $env:LOCALAPPDATA "psmux\psmux.exe"
& $psmuxPath kill-server -a -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1
$wtArgs = @("-d", "$PWD", "$psmuxPath", "new-session", "-s", "default", "pwsh", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "$scriptPath", "$promptPath")
Start-Process wt.exe -ArgumentList $wtArgs
```
