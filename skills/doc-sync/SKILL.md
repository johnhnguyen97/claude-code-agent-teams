---
name: doc-sync
description: Synchronize documentation across Serena memories, local docs/, Gitea Wiki, and Daily Notes. Triggered manually or by /retrospective. Uses Serena symbols as the bridge between code and docs.
---

# /doc-sync

Synchronize documentation across all 4 documentation systems using code as the source of truth.

## When to Use

- After significant code changes (new features, refactors, schema changes)
- At end of sprint/milestone to bring docs up to date
- When `/retrospective` detects architectural changes
- Before team handoffs to ensure docs are current

## Architecture

```
Code (Rust/Python)
      |
      v
Serena Symbol Index ---- live view of code structure
      |
      v
/doc-sync ---- orchestrator
      |
      +---> Local docs/       (Write tool)
      +---> Serena Memories   (mcp__serena__write_memory)
      +---> Gitea Wiki        (scripts/gitea_wiki_push.sh)
      +---> Daily Notes       (mcp__daily-notes__log_project_activity)
```

## Workflow

### Step 1: Detect Changes

Run `git diff --name-only HEAD~5..HEAD` (or `git diff --name-only` for uncommitted changes) to find recently changed source files. Filter for `.rs`, `.py`, `.md` files that map to documentation.

### Step 2: Classify Changes

Map changed files to their documentation targets:

| Changed File Pattern | Local Doc Target | Wiki Page | Serena Memory |
|---|---|---|---|
| `core/src/bin/spacedb_explorer.rs` | `docs/spacedb-s2d.md` | SpaceDB-Reconstruction | - |
| `core/src/bin/gage_audit_parallel.rs` | `docs/gagepack-recovery.md` | GAGEpack-Recovery | gagepack_schema |
| `core/src/bin/apriso_audit_parallel.rs` | `docs/apriso-recovery.md` | APRISO-Recovery | apriso_schema |
| `core/src/data_score.rs` | `docs/algorithm-patterns.md` | Algorithms | - |
| `core/src/mdf_detector.rs` | `docs/algorithm-patterns.md` | Algorithms | - |
| `core/src/textmix.rs` | `docs/algorithm-patterns.md` | Algorithms | - |
| `core/src/database.rs` | `docs/postgresql-backend.md` | Architecture | build_and_tools |
| `finetune/discovery_service.py` | `docs/discovery_service.md` | Discovery-Service | discovery_service |
| `finetune/*.py` (training) | - | AI-ML-Pipeline | - |
| `.claude/agents/*.md` | `docs/agent-teams.md` | Architecture | - |
| `app/src/**` | - | Krok-App | - |

If no changed files match any pattern, report "No documentation-relevant changes detected" and stop.

### Step 3: Analyze Symbols (Serena)

For each changed source file:

1. Use `mcp__serena__get_symbols_overview` to get the file's current structure (functions, structs, traits)
2. Use `mcp__serena__find_symbol` with `include_body=false` to list public API surfaces
3. Compare against existing documentation to identify gaps or outdated sections

Focus on:
- New public functions/structs that aren't documented
- Changed function signatures (parameters, return types)
- Removed symbols that docs still reference
- New modules or binaries

### Step 4: Read Existing Documentation

For each target doc file:
1. Read the local `docs/*.md` file
2. If a Serena memory exists for the domain, read it too (`mcp__serena__read_memory`)
3. Note the document's structure (headings, sections) to preserve formatting

### Step 5: Generate Updates

For each doc target, spawn the **doc-writer** agent (or handle inline for small changes):

**Small changes** (< 3 symbols changed): Update inline using Edit tool
- Add/update function signatures in the appropriate section
- Remove references to deleted symbols
- Update examples if API signatures changed

**Large changes** (new modules, architectural shifts): Spawn doc-writer agent
- Provide: changed symbols, current doc content, Serena memory context
- Agent rewrites affected sections while preserving overall structure
- Agent returns updated markdown

### Step 6: Push to All Systems

Execute in order:

1. **Local docs/** — Write updated markdown via Edit/Write tool
2. **Gitea Wiki** — Push via helper script:
   ```bash
   bash scripts/gitea_wiki_push.sh "<WikiPageName>" "docs/<target>.md" "doc-sync: update <section>"
   ```
3. **Serena Memories** — If patterns changed, update via `mcp__serena__write_memory`:
   - Only update memories for schema/pattern changes, not routine doc updates
   - Memory names: `apriso_schema`, `gagepack_schema`, `build_and_tools`, `discovery_service`, `project_overview`
4. **Daily Notes** — Log the sync operation:
   ```
   mcp__daily-notes__log_project_activity(
     project_name: "krok",
     activity: "doc-sync: updated [list of docs], pushed to wiki [pages], updated memories [names]"
   )
   ```

### Step 7: Report

Output summary to user:
```
## Doc Sync Complete

### Changes Detected
- [file1.rs] -> [doc target] (N symbols changed)

### Updated
- docs/spacedb-s2d.md (3 sections updated)
- Wiki: SpaceDB-Reconstruction (pushed)
- Serena: build_and_tools (updated)
- Daily Notes: logged

### Skipped
- [reason for any skipped targets]
```

## Tools Used

- `Bash` — git diff, scripts/gitea_wiki_push.sh
- `Read` — existing docs, CLAUDE.md
- `Edit/Write` — update doc files
- `Grep/Glob` — find related files
- `Task` — spawn doc-writer agent for large changes
- `mcp__serena__get_symbols_overview` — code structure analysis
- `mcp__serena__find_symbol` — specific symbol lookup
- `mcp__serena__read_memory` / `mcp__serena__write_memory` — pattern storage
- `mcp__daily-notes__log_project_activity` — activity logging

## Gitea Wiki API Reference

```bash
# List all wiki pages
curl -s "http://localhost:3000/api/v1/repos/your-user/your-repo/wiki/pages" -u "$GITEA_AUTH"

# Read a page (returns base64 content)
curl -s "http://localhost:3000/api/v1/repos/your-user/your-repo/wiki/page/<PageName>" -u "$GITEA_AUTH"

# Update a page
curl -s -X PATCH -u "$GITEA_AUTH" \
  -H "Content-Type: application/json" \
  -d '{"title":"<PageName>","content_base64":"<base64>","message":"<commit msg>"}' \
  "http://localhost:3000/api/v1/repos/your-user/your-repo/wiki/page/<PageName>"

# Create a new page
curl -s -X POST -u "$GITEA_AUTH" \
  -H "Content-Type: application/json" \
  -d '{"title":"<PageName>","content_base64":"<base64>","message":"<commit msg>"}' \
  "http://localhost:3000/api/v1/repos/your-user/your-repo/wiki/pages"
```

## Guidelines

- Preserve existing doc structure — update sections, don't rewrite entire files
- Only update Serena memories for schema/pattern changes, not routine doc updates
- Always push to wiki AFTER local docs are committed (local is source of truth)
- Log every sync to daily notes for audit trail
- If wiki push fails (network, auth), save locally and warn user
