# Claude Code Agent Teams Workflow (Windows Psmux)

This repository contains the necessary resources to run **Claude Code Agent Teams** asynchronously and autonomously on Windows using `psmux`.

By default, Claude's experimental agent teams run synchronously in-process on Windows, or use `tmux` on Unix systems. This repository provides a drop-in polyfill to force Windows Agent Teams to spawn beautifully isolated, parallel split-panes in Windows Terminal using a native Windows terminal multiplexer (`psmux`).

## The Permissions Loop Problem
Agent Teams use a new, intricate internal lifecycle:
- Teammates send permission requests to the Team Lead rather than the User.
- If the Team Lead doesn't know how to approve them, the team hangs indefinitely.
- `--permission-mode dontAsk` only affects the current terminal, not spawned agents.

## The Solution
1. **`--dangerously-skip-permissions`**: This repo provides an automated launch script (`run_in_psmux.ps1`) that correctly forces Claude to propagate the bypass flag down to all spawned subagents.
2. **Bash Env Shims**: Windows does not natively support the `env VAR=val command` syntax that Claude uses to boot its Node.js teammates. The `env.cmd` and `env.py` shims seamlessly intercept and execute these Linux-style strings locally.
3. **Explicit Orchestrator Lifecycle Rules**: See `example_team_prompt.txt` to learn how to explicitly command the Team Lead to monitor its inbox and instantly approve teammate permissions via the `sendMessage` tool to avoid the hanging approval loop.

## Setup Instructions

1. Install `psmux` on your Windows system (`$env:LOCALAPPDATA\psmux\psmux.exe`).
2. Copy `env.cmd` and `env.py` to `C:\tmp\` (or adapt paths) so Claude can resolve them.
3. Add `"teammateMode": "tmux"` to your `~/.claude/settings.json`.
4. Run the launch workflow provided in `launch-team.md`, supplying the path to `example_team_prompt.txt`.
