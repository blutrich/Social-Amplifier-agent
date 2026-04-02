# Social Amplifier Plugin

> Personal social content creation for Base44 champions.

## How Workflows Execute

The `champion-router` skill is the entry point. When loaded:

1. Initializes memory > loads champion profile > detects intent > executes workflow
2. Chains to the right agent + skill based on intent
3. Finishes every content workflow through `agents/voice-guardian.md` (quality gate)
4. Logs to `.claude/social-amplifier/sessions.md`

**Workflow chains by intent:**

| Intent | Chain |
|--------|-------|
| New champion | `champion-router` > `new-champion` skill (interactive onboarding) |
| Generate LinkedIn | `champion-router` > `content-specialist` > `voice-guardian` |
| Generate X/Twitter | `champion-router` > `content-specialist` > `voice-guardian` |
| Scan trends | `champion-router` > `trend-scout` |
| Scan Slack | `champion-router` > `scan-slack` skill |
| Repurpose content | `champion-router` > `content-specialist` > `voice-guardian` |

**Every content workflow** must read `agents/shared-instructions.md` and the champion's `tone-of-voice.md` before generating.

## Architecture

```
champion-router (ENTRY POINT)
        |
        +-- NEW_CHAMPION > new-champion skill (onboarding Q&A)
        +-- GENERATE > content-specialist > voice-guardian
        +-- SCAN_TRENDS > trend-scout (Bright Data)
        +-- SCAN_SLACK > scan-slack skill (Slack MCP)
        +-- REPURPOSE > content-specialist > voice-guardian
```

## Agents

| Agent | Model | Purpose |
|-------|-------|---------|
| `content-specialist` | Opus | Generates LinkedIn/X posts in champion's voice |
| `voice-guardian` | Sonnet | Quality gate - personal voice + anti-AI-tells check |
| `trend-scout` | Sonnet | Scans LinkedIn/X for trending topics via Bright Data |

## Commands

| Command | Action |
|---------|--------|
| `/new-champion` | Interactive onboarding - builds champion profile |
| `/generate {id}` | Generate content for a champion |
| `/scan-trends {id}` | Find trending topics matching champion interests |
| `/scan-slack {id}` | Find feature announcements in Slack |

## Memory System

Persistent learning in `.claude/social-amplifier/`:
- `activeContext.md` - Current focus
- `patterns.md` - What works/doesn't per champion
- `sessions.md` - Session log
