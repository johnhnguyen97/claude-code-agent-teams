---
name: team-git-workflow
description: Enforces proper git workflow for agent team members in worktrees — commit, push to Gitea, merge back to development, cleanup
---

# Team Git Workflow

When working as a teammate in an agent team (you have a worktree branch), follow this git discipline:

## First Thing: Set Git Identity
Git identity env vars are set by the launcher, but always verify in your worktree:
```bash
git config user.name "John Nguyen"
git config user.email "your-email@example.com"
```

## During Work
- Commit frequently with conventional commit messages: `feat:`, `fix:`, `refactor:`, `docs:`, `chore:`
- Do NOT add "Co-Authored-By" lines
- Stage specific files, never `git add -A` or `git add .`
- Never commit `.env`, `data/*.db`, or files >10MB

## When Your Task Is Complete

### Step 1: Final Commit
```bash
git add <specific-files>
git commit -m "feat: <description of what you did>"
```

### Step 2: Push Your Branch to Gitea
```bash
git push origin <your-branch> 2>&1 || git remote set-url origin http://localhost:3000/ee01287/krok.git && git push origin <your-branch>
```
- Push to **Gitea** (localhost:3000), NEVER GitHub
- Remote URL: `http://localhost:3000/ee01287/krok.git`

### Step 3: Notify Team Lead
Send a message to the team lead with:
- What you completed
- Branch name
- Number of commits
- Any issues found

### Step 4: DO NOT merge or cleanup yourself
The team lead (or `/team-cleanup` command) handles merging and worktree removal.

## Gitea Configuration
- URL: http://localhost:3000
- Username: ee01287
- Email: your-email@example.com
- Git config: `user.name = "John Nguyen"`, `user.email = "your-email@example.com"`
