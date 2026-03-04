---
description: Launch an automated Claude Agent Team in a Psmux split-window session
---

# Agent Team Launcher

This workflow launches a multi-agent Claude Team inside native `psmux` panes on Windows. It bypasses the interactive Windows Terminal blockages and propagates the permission bypass to all spawned teammates.

## Prerequisites
1. `psmux` installed at `$env:LOCALAPPDATA\psmux\psmux.exe`
2. `tmux.exe` shim exists (copy of `psmux.exe`) in the same directory
3. Psmux directory in your User PATH (or the launcher script force-adds it)
4. `~/.claude/settings.json` has `"teammateMode": "tmux"`
5. A prompt file detailing the tasks for each agent

## Quick Launch

```powershell
# One-liner: prompts for file path, kills stale sessions, launches team
$promptPath = Read-Host "Prompt file path"
$scriptPath = ".\run_in_psmux.ps1"
$psmux = "$env:LOCALAPPDATA\psmux\psmux.exe"
& $psmux kill-server -a 2>$null; Start-Sleep 1
Start-Process wt.exe -ArgumentList @("-d","$PWD","$psmux","new-session","-s","default","pwsh","-NoProfile","-ExecutionPolicy","Bypass","-File","$scriptPath","$promptPath")
```

## Step-by-Step Launch

```powershell
# 1. Set paths
$promptPath = "C:\tmp\your_team_prompt.txt"
$scriptPath = Join-Path $PWD "run_in_psmux.ps1"
$psmuxPath = Join-Path $env:LOCALAPPDATA "psmux\psmux.exe"

# 2. Kill stale psmux sessions
& $psmuxPath kill-server -a 2>$null
Start-Sleep -Seconds 1

# 3. Launch in new Windows Terminal via psmux
Start-Process wt.exe -ArgumentList @(
    "-d", "$PWD",
    "$psmuxPath", "new-session", "-s", "default",
    "pwsh", "-NoProfile", "-ExecutionPolicy", "Bypass",
    "-File", "$scriptPath", "$promptPath"
)
```

## What Happens
1. Windows Terminal opens with a psmux session
2. The launcher script clears the `CLAUDECODE` env var (prevents nested session detection)
3. Claude Code starts with `--dangerously-skip-permissions` and reads the prompt
4. The Team Lead creates the team and spawns teammates
5. Each teammate appears as a **visible split pane** in Windows Terminal (via psmux intercepting `tmux split-window`)
6. Teammates work in parallel with full tool access
