# Agent Teams & Psmux Spawning (Windows)

Sub-agents spawned via the `Task` tool run **in-process** and inherit sandboxed permissions — they get `Permission denied` on Read, Bash, Grep, and Edit. This makes them useless for real work.

**Solution**: Use **psmux** to spawn teammates as **separate Claude Code CLI instances** in their own terminal panes with `--dangerously-skip-permissions`. Each gets full tool access.

**NOTE**: The lead instance shows a one-time terms dialog — accept it once. All spawned teammates inherit the setting automatically.

## Psmux Location
- **Binary**: `$env:LOCALAPPDATA\psmux\psmux.exe`
- **Config**: `~/.psmux.conf` — forces Git Bash as default shell, auto-tiles panes, auto-closes finished panes
- **Do NOT** use `-s session-name` flag (internal psmux bug — always use `default` session)

## How to Launch a Team

**Step 1**: Write a prompt file describing the team (see `C:\tmp\claude_team_*.txt` for examples):
```
C:\tmp\claude_team_<mission>.txt
```

**Step 2**: Launch via psmux + Windows Terminal:
```powershell
$promptPath = "C:\tmp\claude_team_<mission>.txt"
$scriptPath = Join-Path $PWD ".agents\scripts\run_in_psmux.ps1"

# Kill stale sessions first
$wtArgs = @("-d", "$PWD", "$env:LOCALAPPDATA\psmux\psmux.exe", "kill-server", "-a")
Start-Process wt.exe -ArgumentList $wtArgs
Start-Sleep -Seconds 1

# Launch team in new psmux session
$wtArgs2 = @(
    "-d", "$PWD",
    "$env:LOCALAPPDATA\psmux\psmux.exe", "new-session", "-s", "default",
    "pwsh", "-NoProfile", "-ExecutionPolicy", "Bypass",
    "-File", "$scriptPath", "$promptPath"
)
Start-Process wt.exe -ArgumentList $wtArgs2
```

**Step 3**: The script (`run_in_psmux.ps1`) passes the prompt as a CLI argument to `claude --dangerously-skip-permissions`. Claude creates the team, spawns teammates into split panes via `tmux split-window`, and orchestrates them.

## Key Files
| File | Purpose |
|------|---------|
| `.agents/scripts/run_in_psmux.ps1` | Launcher script — reads prompt file, pipes to Claude CLI |
| `C:\tmp\claude_team_*.txt` | Team prompt files (teammate definitions, tasks, rules) |
| `~/.claude/settings.json` → `teammateMode: "tmux"` | Tells Claude CLI to use psmux for teammate panes |

## Prompt File Template
```text
Create an agent team with N teammates for <mission>:

  Teammate 1 — <Name>:
    Own files: <path>
    Settings: isolation: worktree
    Tasks:
    1. ...

  Teammate 2 — <Name>:
    ...

Rules for the Team Lead Orchestrator:
- Workspace: C:\Users\ee01287\Documents\Projects\Krok
- isolation: worktree (each agent gets own git branch)
- Build: cd core && PATH="/c/Users/ee61287/.cargo/bin:$PATH" PYO3_PYTHON='C:\Python312\python.exe' cargo build --release
- CRITICAL: Teammates MUST communicate findings to each other via SendMessage.
- CRITICAL: Clean up worktrees when done: git worktree remove <path>
- Push to Gitea (localhost:3000), NOT GitHub.
```

## Why NOT In-Process Sub-Agents
| Feature | In-Process (Task tool) | Psmux (separate CLI) |
|---------|----------------------|---------------------|
| Permissions | Sandboxed — gets denied | Full (`--dangerously-skip-permissions`) |
| Visibility | Hidden background logs | Real terminal panes you can watch |
| Tool access | Limited, no Bash/Read | All tools available |
| Communication | Via mailbox (async) | Via mailbox (async) + visible output |
| Speed | Faster spawn | ~5s spawn per pane |

**Rule**: For any team that needs to run binaries, edit code, or do real work — always use psmux. Only use in-process Task agents for pure research/exploration.
