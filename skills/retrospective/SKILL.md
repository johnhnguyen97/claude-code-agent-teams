---
name: retrospective
description: Session retrospective for continual learning. Reviews conversation, extracts learnings, updates skills and memory files. Use at end of coding sessions to capture insights before context is lost. Triggers include "let's do a retro", "session retro", "retrospective", "what did we learn", "capture learnings", "end of session".
---

# Retrospective

Session retrospective for continual learning. Reviews conversation, extracts learnings, updates skills and memory.

## When to Use

Run at end of coding sessions to capture learnings before context is lost. Invoke via `/retrospective` or when user says "let's do a retro".

## Process

### 1. Session Analysis

Review the entire conversation and identify:

**Successes**
- What worked well
- Effective approaches discovered
- Useful patterns or techniques
- Tools/commands that solved problems

**Failures**
- What didn't work
- Dead ends encountered
- Errors and their root causes
- Approaches to avoid

**Discoveries**
- New insights about the codebase
- Unexpected behaviors
- Configuration quirks
- Edge cases found

### 2. Skill Identification

Determine which skills were used or could benefit:
- Check `~/.claude/skills/` for personal (global) skills
- Check `.claude/skills/` for project skills
- Identify if new skill should be created

### 3. Learning Extraction

For each relevant skill, extract:
```markdown
## Learnings from [DATE]

### What Worked
- [specific technique or approach]

### What Failed
- [approach] -- [why it failed]

### Configuration Notes
- [any settings or params that matter]
```

### 4. Update Targets

Update the appropriate files with extracted learnings:

**Project memory** (for project-specific insights):
- Read `~/.claude/projects/<encoded-project-path>/memory/MEMORY.md`
- Update or create topic-specific memory files in that directory
- Keep MEMORY.md under 200 lines (it gets loaded into system prompt)

**Skill files** (for skill-specific learnings):
- Add to existing `## Learnings` or `## Known Issues` sections
- Create sections if they don't exist
- Keep entries dated and concise
- Preserve existing content

**CLAUDE.md** (for critical project-wide patterns):
- Only update for patterns that affect all future sessions
- Keep changes minimal and high-signal

### 4.5 Documentation Sync (Auto)

After updating memories and skills, check if documentation needs syncing:

1. **Detect architectural changes** — scan session for keywords: "refactor", "new module",
   "new binary", "schema change", "algorithm change", "new API", "new command", "new struct"
2. **If detected** — run the `/doc-sync` workflow:
   - Read changed files via `git diff --name-only HEAD~5..HEAD`
   - Map changed files to doc targets (see `/doc-sync` skill for mapping table)
   - Update relevant `docs/` files
   - Push to Gitea Wiki via `scripts/gitea_wiki_push.sh`
   - Log to daily notes
3. **Update Serena memories** — for any new patterns or corrections:
   - Use `mcp__serena__write_memory` with the memory name
   - Focus on: build commands, schema changes, algorithm patterns
   - Memory names: `apriso_schema`, `gagepack_schema`, `build_and_tools`, `discovery_service`, `project_overview`
4. **Log retrospective to daily notes**:
   - Use `mcp__daily-notes__log_project_activity` with project "krok"
   - Include: learnings count, files updated, memories updated

### 5. Summary Output

Report to user:
- Files updated (with paths)
- Key learnings captured
- Suggested new skills (if patterns emerged)

## Output Format

```
## Session Retrospective

### Key Takeaways
1. [Most important learning]
2. [Second learning]

### Files Updated
- `path/to/file` -- added [X] learnings

### Failures Documented
- [Failure 1]: [brief reason]

### Suggested Actions
- [ ] Create new skill for [pattern]
- [ ] Update CLAUDE.md with [insight]
```

## Guidelines

- **Be specific**: "Use `--no-cache` flag" not "caching can cause issues"
- **Include context**: When/why something works or fails
- **Date entries**: Learnings should have dates for tracking
- **Don't over-document**: Only capture genuinely useful insights
- **Failures are valuable**: Non-deterministic LLM behavior means documenting anti-patterns prevents repeating mistakes
- **No duplicates**: Check existing memory/learnings before adding

## Example Memory Update

Adding to project memory file `~/.claude/projects/.../memory/debugging.md`:

```markdown
### 2026-03-05
- VD154 reconstruction: NTFS metadata lives at offset 0x6000000, not at image start
- S2D thin provisioning means image size != allocated blocks -- gaps are expected
- spacedb_explorer raw drive fallback needs admin elevation even for read-only
```

## Integration

Works well with:
- **conversation-search** skill -- search past retros to avoid repeating mistakes
- **MEMORY.md** auto-memory -- retro findings feed into persistent memory
- Pre-compact hook -- run retro before context gets compacted

## Tools

- Read: Access skill files, memory files, and conversation history
- Edit: Update existing skills and memory
- Write: Create new files if needed
- Glob: Find skill and memory directories
- Bash: Run conversation-search to cross-reference past learnings
