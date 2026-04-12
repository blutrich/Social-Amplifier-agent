---
name: champion-memory
description: |
  Persistent learning across sessions. Tracks what works for each champion, patterns, and session history.
disable-model-invocation: true
---

# Champion Memory Skill

## Memory Location

`.claude/social-amplifier/`

## Initialization

On first run:
```
Bash(command="mkdir -p .claude/social-amplifier")
```

Create if not exists:

### activeContext.md
```markdown
# Social Amplifier - Active Context

## Current Focus
[What we're working on]

## Recent Sessions
- [date] [champion] [what was generated]

## Patterns
- [What works for which champion]

## Last Updated
[timestamp]
```

### patterns.md
```markdown
# Social Amplifier - Patterns

## What Works
- [Champion]: [Pattern that gets high engagement]

## What Doesn't Work
- [Champion]: [Pattern to avoid]

## Voice Refinements
- [Champion]: [Adjustment to tone-of-voice based on feedback]

## Last Updated
[timestamp]
```

### sessions.md
```markdown
# Social Amplifier - Sessions

| Date | Champion | Platform | Topic | Variations | Chosen | Score |
|------|----------|----------|-------|------------|--------|-------|
```

## Session Logging

After every content generation:
```
Edit(file_path=".claude/social-amplifier/sessions.md",
     old_string="| Date |",
     new_string="| Date |\n| {date} | {champion} | {platform} | {topic} | {count} | {chosen} | {score} |")
```
