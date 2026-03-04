# Claude Code Agent Teams Workflow (Windows Psmux)

This repository contains the necessary resources to run **Claude Code Agent Teams** asynchronously and autonomously on Windows using `psmux`.

By default, Claude's experimental agent teams run synchronously in-process on Windows, or use `tmux` on Unix systems. This repository provides a drop-in polyfill to force Windows Agent Teams to spawn beautifully isolated, parallel split-panes in Windows Terminal using a native Windows terminal multiplexer (`psmux`).

## How It Works (Triple-Layer Identity Trick)

Claude Code on Windows doesn't natively support visual teammate panes. We outsmart the default sandboxing with three layers:

1. **`teammateMode: "tmux"`** in `~/.claude/settings.json` — Forces Claude CLI to emit standard `tmux split-window -v "claude ..."` commands when spawning teammates, instead of using in-process sub-agents (which get Permission Denied on all tools).

2. **Psmux as the Tmux Impersonator** — `psmux.exe` ships with a `tmux.exe` shim that intercepts those commands and translates them into Windows Terminal's native pane-splitting API. The result: visible, interactive split panes.

3. **Permission Injection via `--dangerously-skip-permissions`** — The launcher starts the Team Lead with this flag. The lead accepts the one-time terms dialog. Teammates spawned via `tmux split-window` are independent CLI processes that inherit the permission bypass — giving them full tool access (Grep, Read, Bash, Edit) that in-process sub-agents lack.

## Why In-Process Sub-Agents Fail

| Feature | In-Process (Task tool) | Psmux (separate CLI) |
|---------|----------------------|---------------------|
| Permissions | Sandboxed — gets denied | Full (`--dangerously-skip-permissions`) |
| Visibility | Hidden background logs | Real terminal panes you can watch |
| Tool access | Limited, no Bash/Read | All tools available |
| Communication | Via mailbox (async) | Via mailbox (async) + visible output |

## The Permissions Loop Problem

Agent Teams use an intricate internal lifecycle:
- Teammates send permission requests to the Team Lead rather than the User.
- If the Team Lead doesn't know how to approve them, the team hangs indefinitely.
- `--permission-mode dontAsk` only affects the current terminal, not spawned agents.

## Setup Instructions

### 1. Install Psmux
Download and place `psmux.exe` at `$env:LOCALAPPDATA\psmux\psmux.exe`.

### 2. Create the tmux.exe Shim (CRITICAL)
Claude CLI looks for a binary named `tmux` when `teammateMode` is `"tmux"`. Psmux doesn't register itself as `tmux` by default, so you must create a shim:

```powershell
# Copy psmux.exe as tmux.exe in the same directory
Copy-Item "$env:LOCALAPPDATA\psmux\psmux.exe" "$env:LOCALAPPDATA\psmux\tmux.exe"
```

### 3. Add Psmux to PATH (Permanent)
Add the psmux directory to your **User** PATH so tmux.exe is always discoverable:

```powershell
$psmuxDir = "$env:LOCALAPPDATA\psmux"
$currentPath = [System.Environment]::GetEnvironmentVariable('PATH', 'User')
if ($currentPath -notmatch 'psmux') {
    [System.Environment]::SetEnvironmentVariable('PATH', "$psmuxDir;$currentPath", 'User')
    Write-Host "Added $psmuxDir to User PATH permanently."
}
```

Verify: open a **new** terminal and run `Get-Command tmux`.

### 4. Copy Env Shims
Copy `env.cmd` and `env.py` to `$env:LOCALAPPDATA\psmux\` (or `C:\tmp\`) so Claude can resolve Linux-style `env VAR=val command` strings natively on Windows.

### 5. Install Agent Templates
Copy the `agents/team-lead.md` and `agents/windows-teammate.md` files into your global `~/.claude/agents/` directory. These enforce the explicit state machine and permission bypass rules required for autonomous operation.

### 6. Configure Claude Settings
Add to your `~/.claude/settings.json`:
```json
{
  "teammateMode": "tmux",
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

### 7. Launch a Team
See `launch-team.md` for the one-liner, or run manually:

```powershell
$promptPath = "C:\tmp\example_team_prompt.txt"
$scriptPath = ".\run_in_psmux.ps1"
$psmuxPath = "$env:LOCALAPPDATA\psmux\psmux.exe"

# Kill stale sessions
& $psmuxPath kill-server -a 2>$null
Start-Sleep -Seconds 1

# Launch in new Windows Terminal
Start-Process wt.exe -ArgumentList @(
    "-d", "$PWD",
    "$psmuxPath", "new-session", "-s", "default",
    "pwsh", "-NoProfile", "-ExecutionPolicy", "Bypass",
    "-File", "$scriptPath", "$promptPath"
)
```

## Known Gotchas

- **CLAUDECODE env var**: If launching from within an existing Claude session, the `CLAUDECODE` environment variable must be unset or Claude refuses to start ("cannot be launched inside another session"). The launcher script handles this automatically.
- **Session name**: Do NOT use `-s custom-name` with psmux — only the `default` session name works reliably with Claude's internal `tmux split-window` commands.
- **First-run terms dialog**: The lead instance shows a one-time `--dangerously-skip-permissions` terms acceptance dialog. Accept it once; all spawned teammates inherit the setting.
- **PATH not visible in current session**: After adding psmux to permanent PATH, existing terminals won't see the change. Open a new terminal or use the launcher script (which force-adds psmux to PATH).

## Files

| File | Purpose |
|------|---------|
| `run_in_psmux.ps1` | Launcher script — clears CLAUDECODE env, adds psmux to PATH, passes prompt to Claude CLI |
| `launch-team.md` | One-liner launch commands |
| `example_team_prompt.txt` | Sample team prompt with 3 teammates |
| `env.cmd` / `env.py` | Shims for Linux-style `env VAR=val` commands on Windows |
| `agents/team-lead.md` | Custom agent template for the Team Lead orchestrator |
| `agents/windows-teammate.md` | Custom agent template for spawned teammates |
