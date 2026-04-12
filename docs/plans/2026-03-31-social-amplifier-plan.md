# Social Amplifier Agent - Implementation Plan

> **For Claude:** REQUIRED: Follow this plan phase-by-phase. Each phase has explicit file lists, steps, and exit criteria.
> **Design:** See `docs/plans/2026-03-31-social-amplifier-design.md` for full specification.

---

## Human Layer

### Executive Summary
- Build a Claude Code plugin (forked from base44-marketing-agent) that enables Base44 employees to create personal LinkedIn and X content with AI assistance
- The approach reuses proven patterns from the marketing agent (router > agent chains > quality gate) but replaces brand-centric agents with champion-centric ones where each person's voice is the "brand"
- 7 phases: scaffold, onboarding, content generation, voice guardian, scanning, memory/docs, integration test with Dor Blech as pilot

### What I Verified vs What Still Needs Confirmation
- **Confident because:** Inspected the full base44-marketing-agent plugin structure (.claude-plugin/plugin.json, settings.json, CLAUDE.md, agents/, skills/, brands/), confirmed the router > specialist > guardian chain pattern, verified the brand profile directory structure (profile.json, tone-of-voice.md, RULES.md), confirmed the skill frontmatter format (name, description, model, tools, skills, memory), and confirmed plugin.json manifest format (name, version, description, author, homepage, repository, license, keywords)
- **Still needs confirmation:** Whether the champion profile directory should live inside the plugin folder (`plugins/social-amplifier/champions/`) or at repo root (`champions/`). Plan uses plugin-relative paths to match marketing-agent convention.
- **Key risks:** Generated content may still sound AI-written despite Voice Guardian (mitigated by iterative anti-AI-tells refinement with Dor's feedback)

### Request Summary
Build the Social Amplifier Agent as a Claude Code plugin that onboards Base44 employees with personalized voice profiles and generates ready-to-post LinkedIn/X content.

### Requirements Snapshot
- Fork marketing plugin architecture (champion = brand)
- Interactive onboarding flow (8 steps) building champion profile
- Content generation with 2-3 variations per request (personal, insight, product angles)
- Voice Guardian quality gate (10-point checklist, anti-AI-tells + personal voice check)
- Slack scanning for feature announcements (on-demand via Slack MCP)
- LinkedIn/X trend scanning (on-demand via Bright Data MCP with WebFetch fallback)
- Content repurposing (Slack notification to personal angle to post)

### Constraints Snapshot
- Must be a Claude Code plugin (not standalone app)
- Content must feel personal, not corporate
- No automated scanning in v1 (all on-demand)
- No visual generation, scheduling, or autopilot in v1
- English only in v1
- Remote repo: https://github.com/blutrich/Social-Amplifier-agent

### In Scope
- Plugin scaffold with manifest, settings, CLAUDE.md
- Champion router (intent detection + workflow routing)
- New-champion onboarding skill (8-step Q&A to profile)
- Content-specialist agent (3-variation generation)
- Voice Guardian agent (10-point quality gate)
- Trend-scout agent (Bright Data + WebFetch fallback)
- Scan-slack skill (Slack MCP feature discovery)
- Repurpose-content skill (Slack to personal post)
- Memory system (session tracking, pattern learning)
- Onboarding documentation
- Slash commands (/new-champion, /generate, /scan-trends, /scan-slack)
- Integration test with Dor Blech

### Out Of Scope
- Visual/image generation (v2)
- Scheduling/autopilot (v2)
- Automated daily scanning (v2)
- Multi-language support (v2)
- Analytics dashboard
- Multi-team management

### Planning Mode
- Plan mode: `execution_plan`
- Verification rigor: `standard`

### Open Decisions
- None (all decisions resolved in design file)

### Differences From Agreement
- None

---

**Goal:** Build a Claude Code plugin that helps Base44 employees ("champions") create personal social content on LinkedIn and X, with personalized onboarding, tone-of-voice profiling, and quality-gated content generation.

**Architecture:** Fork of base44-marketing-agent plugin structure. Key mapping: "brand" becomes "champion" (the person). Reuse router pattern, quality gate (voice guardian), anti-AI-tells, multi-variation output, Slack integration, and memory system. Replace brand-focused agents with champion-focused ones. Each champion gets a profile directory with tone-of-voice, interests, and style rules.

**Tech Stack:** Claude Code Plugin (agents + skills markdown files), Slack MCP (feature scanning), Bright Data MCP (trend scanning), WebFetch (inspiration URL analysis)

**Prerequisites:**
- Remote repo cloned: `https://github.com/blutrich/Social-Amplifier-agent`
- Reference repo available at `/tmp/base44-marketing-agent` for pattern reference
- Slack MCP connected in Claude Code
- Bright Data MCP available for trend scanning

**Durable Decisions:**
- Plugin lives at `plugins/social-amplifier/` within the repo root
- Champion profiles stored at `plugins/social-amplifier/champions/{champion-id}/` (kebab-case ID derived from name)
- Memory stored at `.claude/social-amplifier/` (activeContext.md, patterns.md, sessions.md)
- Commands registered at `.claude/commands/` (new-champion.md, generate.md, scan-trends.md, scan-slack.md)
- All content passes Voice Guardian before delivery (score 9+/10 = ship, 7-8 = auto-rewrite, <7 = regenerate)
- 2-3 variations always generated per content request
- Anti-AI-tells list forked from marketing agent's banned-words.md + adapted for personal voice
- Agent model assignments: content-specialist = Opus, voice-guardian = Sonnet, trend-scout = Sonnet, champion-router = default (no model override)

---

## Relevant Codebase Files

### Reference Architecture (Fork Source)
- `/tmp/base44-marketing-agent/plugins/base44-marketing/.claude-plugin/plugin.json` - Plugin manifest (name, version, description, author, homepage, repository, license, keywords)
- `/tmp/base44-marketing-agent/plugins/base44-marketing/CLAUDE.md` - Plugin entry point pattern (router > agent chains > quality gate)
- `/tmp/base44-marketing-agent/plugins/base44-marketing/settings.json` - Plugin permissions and env vars pattern (includes CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS)
- `/tmp/base44-marketing-agent/plugins/base44-marketing/agents/brand-guardian.md` - Quality gate pattern (12-point checklist, score + rewrite loop)
- `/tmp/base44-marketing-agent/plugins/base44-marketing/agents/shared-instructions.md` - Shared rules injection pattern
- `/tmp/base44-marketing-agent/plugins/base44-marketing/agents/linkedin-specialist.md` - Agent frontmatter pattern (model, tools, skills)
- `/tmp/base44-marketing-agent/plugins/base44-marketing/skills/marketing-router/SKILL.md` - Router skill pattern (intent detection, workflow chains)
- `/tmp/base44-marketing-agent/plugins/base44-marketing/skills/shared-instructions/SKILL.md` - Skill with `disable-model-invocation: true` pattern
- `/tmp/base44-marketing-agent/plugins/base44-marketing/skills/linkedin-viral/SKILL.md` - Platform optimization skill pattern
- `/tmp/base44-marketing-agent/plugins/base44-marketing/brands/base44/` - Brand profile directory structure (profile.json, tone-of-voice.md, RULES.md, templates/)
- `/tmp/base44-marketing-agent/plugins/base44-marketing/brands/base44/banned-words.md` - Anti-AI vocabulary (fork directly)

### Target Project (Currently Empty)
- `/Users/oferbl/Desktop/Dev/DorChampions/` - Project root (only `docs/` exists)

---

## Execution Contract Layer

### Codebase Reality Check
- **Verified files / surfaces:** Inspected the full base44-marketing-agent plugin at `/tmp/base44-marketing-agent/plugins/base44-marketing/` including CLAUDE.md (routing table), settings.json (permissions), agents/ (9 agents with frontmatter format: name, description, model, tools, skills, memory), skills/ (26 skills with SKILL.md format), brands/base44/ (profile directory with brand.json, tone-of-voice.md, RULES.md, banned-words.md, templates/)
- **Existing patterns / constraints:** Claude Code plugin format uses: `plugins/{name}/CLAUDE.md` as entry point, `settings.json` for permissions, agent frontmatter with `model:` field for model selection, skills with `disable-model-invocation: true` for data-only skills, `.claude/commands/` for slash commands. Router pattern: detect intent > load context > chain agents > quality gate.
- **Pressure points / contradictions:** Target project is greenfield (no existing code to conflict with). The marketing agent uses `brands/{brand}/` for profile directories; we map this to `champions/{champion-id}/`. Marketing agent has `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` env var in settings.json, which is included in this plan since the core workflow chains agents (router > content-specialist > voice-guardian). All permission paths in settings.json resolve relative to the plugin root directory (`plugins/social-amplifier/`).

### Plan-vs-Code Gaps

| Current code / behavior | Planned change | Gap / risk | Plan response |
|-------------------------|----------------|------------|---------------|
| Marketing agent uses `brands/base44/` with fixed brand | Champions are dynamic (created at runtime via onboarding) | Plugin permissions must allow Write to `champions/` | settings.json includes `Write(champions/**)` permission |
| Marketing agent brand-guardian has 12-point checklist (brand-specific) | Voice Guardian has 10-point checklist (person-specific) | Checklist items differ; cannot copy-paste | Phase 4 defines new checklist from scratch, adapted for personal voice |
| Marketing agent uses `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` env | Social Amplifier needs agent chaining (router > content-specialist > voice-guardian) | Agent chaining may fail without it | settings.json includes `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS: "1"` in env block |
| Marketing agent has hooks (hooks.json, session-end.sh) | Plan has no hooks | May miss session logging on exit | Acceptable for v1; hooks are additive and can be added later |
| No git repo initialized in target project | Plan creates git repo in Phase 1 | Must init before first commit | Task 1.1 handles this explicitly |

### Assumption Ledger
- **Proven by code:** Plugin structure format (.claude-plugin/plugin.json, CLAUDE.md, settings.json, agents/, skills/) verified from marketing agent. Plugin manifest format (name, version, description, author, homepage, repository, license, keywords) verified from reference plugin.json. Agent frontmatter format (name, description, model, tools, skills, memory) verified. Skill frontmatter format verified. Permission syntax in settings.json verified. `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` env var confirmed in reference settings.json.
- **Inferred:** Claude Code will discover the plugin at `plugins/social-amplifier/` when repo is opened (inferred from marketing agent convention). Champion directory write permissions will work with `Write(champions/**)` glob pattern. Permission paths in settings.json resolve relative to the plugin root directory (inferred from marketing agent convention).
- **Needs user confirmation:** Whether champion profiles should live at `plugins/social-amplifier/champions/` (plugin-relative, plan default) or at repo root `champions/`. Whether Dor Blech has existing LinkedIn/X posts to seed the tone-of-voice analysis.

### Fresh Review Resolution

- **Accepted findings:**
  - **Finding 1 (BLOCKING): Missing plugin.json** -- Added creation of `plugins/social-amplifier/.claude-plugin/plugin.json` to Task 1.2 with name, version, description, author, homepage, repository, license, and keywords fields matching the reference format. Updated Phase 1 Checkpoint and Acceptance Checks. Note: The reviewer also mentioned `marketplace.json` but the reference repo does NOT have this file (only `plugin.json` exists in `.claude-plugin/`), so it is not added.
  - **Finding 2 (ADVISORY): CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS** -- Added `"CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"` to settings.json env block. Updated Plan-vs-Code Gaps table and Assumption Ledger to reflect this is now included rather than omitted.
  - **Finding 4 (ADVISORY): Path resolution ambiguity** -- Added path resolution clarification note to Task 1.2 settings.json step, explaining that all permission paths resolve relative to the plugin root directory. Updated Assumption Ledger to list this as inferred.
- **Rejected findings:**
  - **Finding 3 (ADVISORY): Phase 5 Checkpoint lists champion-memory/** -- Reviewed Phase 5 Checkpoint (line 1481 of original plan). It lists exactly 8 skill directories: champion-router/, new-champion/, generate-content/, scan-trends/, scan-slack/, repurpose-content/, voice-guardian/, shared-instructions/. It does NOT include champion-memory/ (which is correctly created in Phase 6). Finding appears to be a false positive. However, updated Acceptance Checks to correctly count 9 skill directories (including champion-memory/ from Phase 6) for the final acceptance check.

---

## Phase 1: Plugin Scaffold + Champion Router (Tracer Bullet)

> **Objective:** Installable plugin with working router that detects intent and routes to stubs.
> **Exit Criteria:** Plugin installs in Claude Code. Running any prompt triggers champion-router which identifies intent and responds with "routing to [workflow]" message. `/new-champion` command exists and triggers onboarding stub.

### Task 1.1: Initialize Git + Remote

**Files:**
- Create: `.gitignore`
- Create: `README.md`

**Steps:**
1. Initialize git repo in `/Users/oferbl/Desktop/Dev/DorChampions/`
2. Add remote: `git remote add origin https://github.com/blutrich/Social-Amplifier-agent`
3. Create `.gitignore`:
```
.DS_Store
node_modules/
.env
*.log
```
4. Create minimal `README.md`:
```markdown
# Social Amplifier Agent

Claude Code plugin that helps Base44 employees create personal social content on LinkedIn and X.

## Install

In Claude Code: Customize > Browse Plugins > Add marketplace from URL > paste this repo URL.

## Commands

- `/new-champion` - Create your champion profile
- `/generate {champion_id}` - Generate content
- `/scan-trends {champion_id}` - Find trending topics
- `/scan-slack {champion_id}` - Find feature announcements
```
5. Commit: `git add .gitignore README.md && git commit -m "init: project scaffold"`

### Task 1.2: Plugin Manifest + CLAUDE.md

**Files:**
- Create: `plugins/social-amplifier/.claude-plugin/plugin.json`
- Create: `plugins/social-amplifier/CLAUDE.md`
- Create: `plugins/social-amplifier/PLUGIN-DESCRIPTION.md`
- Create: `plugins/social-amplifier/settings.json`

**Steps:**

1. Create `plugins/social-amplifier/.claude-plugin/plugin.json` (required plugin manifest -- Claude Code uses this to recognize the directory as a valid plugin):
```json
{
  "name": "social-amplifier",
  "version": "0.1.0",
  "description": "Personal social content creation for Base44 employees. Onboards champions with tone-of-voice profiling, generates LinkedIn and X posts with 2-3 variations, and runs Voice Guardian quality gate.",
  "author": {
    "name": "Base44 Team",
    "url": "https://github.com/blutrich"
  },
  "homepage": "https://github.com/blutrich/Social-Amplifier-agent",
  "repository": "https://github.com/blutrich/Social-Amplifier-agent",
  "license": "MIT",
  "keywords": [
    "social-media",
    "content-creation",
    "personal-voice",
    "linkedin",
    "twitter",
    "x",
    "champions",
    "base44"
  ]
}
```

2. Create `plugins/social-amplifier/PLUGIN-DESCRIPTION.md`:
```
Personal social content creation for Base44 employees. Onboards champions with tone-of-voice profiling, generates LinkedIn and X posts with 2-3 variations, and runs Voice Guardian quality gate.
```

3. Create `plugins/social-amplifier/settings.json` (adapted from marketing agent):

**Path resolution note:** All paths in settings.json `permissions.allow` are resolved relative to the plugin root (`plugins/social-amplifier/`). When skills or agents use `Read(file_path="champions/...")`, Claude Code resolves this relative to the plugin directory, matching these permission globs. Keep all Read/Write paths in skills consistent with this plugin-relative resolution.

```json
{
  "permissions": {
    "allow": [
      "Read(champions/**)",
      "Read(skills/**)",
      "Read(agents/**)",
      "Read(shared/**)",
      "Read(CLAUDE.md)",
      "Read(.claude/social-amplifier/**)",
      "Edit(.claude/social-amplifier/**)",
      "Write(.claude/social-amplifier/**)",
      "Write(champions/**)",
      "Bash(mkdir -p .claude/social-amplifier)",
      "Bash(mkdir -p champions/*)",
      "Bash(git status)",
      "Bash(git diff:*)",
      "Bash(git log:*)"
    ],
    "deny": [
      "Bash(rm -rf *)",
      "Bash(git push --force*)",
      "Bash(git reset --hard*)"
    ]
  },
  "env": {
    "SOCIAL_AMPLIFIER_VERSION": "0.1.0",
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

4. Create `plugins/social-amplifier/CLAUDE.md`:
```markdown
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
```

5. Commit: `git add plugins/ && git commit -m "feat: plugin manifest, plugin.json, CLAUDE.md, settings.json"`

### Task 1.3: Champion Router Agent + Skill

**Files:**
- Create: `plugins/social-amplifier/agents/champion-router.md`
- Create: `plugins/social-amplifier/skills/champion-router/SKILL.md`

**Steps:**

1. Create `plugins/social-amplifier/agents/champion-router.md`:
```markdown
---
name: champion-router
description: Routes champion content requests to specialized agents
tools:
  - Read
  - Skill
  - TaskUpdate
skills:
  - champion-router
  - shared-instructions
memory: project
---

# Champion Router

You are the entry point for the Social Amplifier plugin. Route requests to the right workflow.

## Setup

Read shared instructions and memory on startup:
```
Read(file_path="agents/shared-instructions.md")
```

## Intent Detection

Detect the user's intent from their message:

| Pattern | Intent | Route to |
|---------|--------|----------|
| "new champion", "onboard", "set up profile" | NEW_CHAMPION | `new-champion` skill |
| "generate", "write post", "create content", "linkedin", "tweet" | GENERATE | `content-specialist` agent |
| "trends", "trending", "what's hot" | SCAN_TRENDS | `trend-scout` agent |
| "slack", "features", "announcements" | SCAN_SLACK | `scan-slack` skill |
| "repurpose", "turn this into", "from slack" | REPURPOSE | `content-specialist` agent (with Slack context) |

## Champion ID Resolution

If the user mentions a champion name or ID, resolve it:
1. Check `champions/` directory for matching folder
2. If no match and intent is GENERATE: ask "Which champion? Run /new-champion first if not set up."
3. If no match and intent is NEW_CHAMPION: proceed with onboarding

## Routing

After detecting intent and resolving champion:
- Load the champion's profile: `Read(file_path="champions/{id}/profile.json")`
- Load their voice: `Read(file_path="champions/{id}/tone-of-voice.md")`
- Execute the matched workflow chain
```

2. Create `plugins/social-amplifier/skills/champion-router/SKILL.md`:
```markdown
---
name: champion-router
description: |
  Entry point for Social Amplifier. Routes requests to champion onboarding, content generation, trend scanning, or Slack scanning.

  Triggers on: champion, generate, post, content, write, linkedin, tweet, x post, trends, slack, onboard, new champion, repurpose.

  Executes workflows immediately. Never lists capabilities.
---

# Champion Router

**EXECUTION ENGINE.** When loaded: Initialize memory > Load champion > Detect intent > Execute workflow > Update memory.

**NEVER** list capabilities. **ALWAYS** execute.

## Memory Initialization

On every invocation:
```
Bash(command="mkdir -p .claude/social-amplifier")
Read(file_path=".claude/social-amplifier/activeContext.md")
Read(file_path=".claude/social-amplifier/patterns.md")
```

If files don't exist, create them with minimal headers.

## Intent Detection

Ask the user what they need if the request is ambiguous:

1. "What would you like to do?" with options:
   - Set up a new champion profile
   - Generate a post (LinkedIn or X)
   - Find trending topics
   - Scan Slack for features to write about
   - Repurpose a Slack announcement into a post

2. If generating: "Which champion?" (list available from `champions/` directory)
3. If generating: "What platform?" (LinkedIn or X)
4. If generating: "What topic or paste Slack message?"

## Workflow Chains

After intent is clear, execute the matching chain:

- **NEW_CHAMPION**: Load `skills/new-champion/SKILL.md`, run interactive onboarding
- **GENERATE**: Load champion profile + tone-of-voice > invoke `content-specialist` agent > invoke `voice-guardian` agent
- **SCAN_TRENDS**: Load champion interests > invoke `trend-scout` agent
- **SCAN_SLACK**: Load champion interests > invoke `scan-slack` skill
- **REPURPOSE**: Load champion profile + Slack context > invoke `content-specialist` agent > invoke `voice-guardian` agent
```

3. Commit: `git add plugins/social-amplifier/agents/ plugins/social-amplifier/skills/champion-router/ && git commit -m "feat: champion-router agent and skill"`

### Task 1.4: Shared Instructions + Anti-AI-Tells

**Files:**
- Create: `plugins/social-amplifier/agents/shared-instructions.md`
- Create: `plugins/social-amplifier/skills/shared-instructions/SKILL.md`
- Create: `plugins/social-amplifier/shared/anti-ai-tells.md`
- Create: `plugins/social-amplifier/shared/platform-rules.md`

**Steps:**

1. Create `plugins/social-amplifier/agents/shared-instructions.md`:
```markdown
# Shared Agent Instructions

> Injected into all content-producing agents at startup. Single source of truth for voice rules.

## Before Writing (MANDATORY - IN THIS ORDER)

```
Read(file_path="shared/anti-ai-tells.md")                    # Banned patterns
Read(file_path="shared/platform-rules.md")                    # LinkedIn/X format rules
Read(file_path="champions/{champion_id}/tone-of-voice.md")    # Champion's personal voice
Read(file_path="champions/{champion_id}/rules.md")            # Champion's personal rules
```

## Core Principle

This is PERSONAL content. Not corporate. Not branded. The champion is speaking as themselves.

## Anti-AI Structure Patterns (BANNED)

- No rule-of-three (trios of adjectives/bullets/phrases)
- No contrast framing ("It's not X, it's Y")
- No self-narration ("Here's why this matters")
- No significance inflation ("marking a pivotal moment")
- No transition openers (However, Moreover, Furthermore, Additionally, Indeed)
- No em dashes (zero tolerance - biggest AI tell)
- No synonym cycling (using different fancy words for the same thing)
- No false ranges ("from X to Y")
- No fake naming ("The Growth Paradox")
- No "-ing phrase" padding
- No copula avoidance ("serves as" instead of "is")
- No stacked short declaratives ("One tool. Endless possibilities. No limits.")
- No question CTAs ("What would you build?")
- No "let's dive in" openers
- No "happy shipping" sign-offs
- No emoji as bullet points

## Voice Rules

- Content must sound like the CHAMPION wrote it, not an AI
- Use the champion's actual vocabulary and sentence patterns from their tone-of-voice.md
- Match their energy level, humor style, and topic preferences
- If the champion writes casually, write casually. If formally, formally.
- Personal pronouns: always "I" (this is a person, not a brand)
```

2. Create `plugins/social-amplifier/skills/shared-instructions/SKILL.md`:
```markdown
---
name: shared-instructions
description: Core voice rules, anti-AI patterns, and mandatory pre-writing steps for all Social Amplifier content agents. Injected at startup via skills field.
disable-model-invocation: true
---

# Shared Agent Instructions

> Injected into all content-producing agents at startup.

## Before Writing (MANDATORY)

```
Read(file_path="shared/anti-ai-tells.md")
Read(file_path="shared/platform-rules.md")
```

Then load the champion's voice:
```
Read(file_path="champions/{champion_id}/tone-of-voice.md")
Read(file_path="champions/{champion_id}/rules.md")
```
```

3. Create `plugins/social-amplifier/shared/anti-ai-tells.md` (forked from marketing agent's banned-words.md, adapted for personal content):
```markdown
# Anti-AI-Tells - Banned Patterns

> If any of these appear in generated content, the Voice Guardian MUST reject it.

## Banned Verbs
leverage, utilize, craft, empower, streamline, curate, facilitate, harness, spearhead, pioneer, navigate (metaphorical), elevate, foster, cultivate, optimize, revolutionize, transform, drive (metaphorical), unlock, supercharge, catalyze, amplify (metaphorical), orchestrate, synergize, reimagine, democratize

**Use instead:** use, help, write, let, simplify, pick, make easier, lead, find, improve, grow, build

## Banned Adjectives
groundbreaking, seamless, robust, transformative, unprecedented, innovative, cutting-edge, game-changing, best-in-class, world-class, state-of-the-art, next-generation, disruptive, holistic, synergistic, bespoke, turnkey, scalable (unless literally about infrastructure), actionable, impactful

**Use instead:** say what you actually mean specifically

## Banned Adverbs
significantly, dramatically, fundamentally, incredibly, remarkably, ultimately, essentially, literally (when not literal), absolutely, undoubtedly

## Banned Phrases
- "In today's [fast-paced/rapidly-evolving/digital] world"
- "It's not just X, it's Y"
- "Here's the thing"
- "Let me tell you"
- "The future of X is Y"
- "This changes everything"
- "I'm excited to announce"
- "Thrilled to share"
- "Proud to announce"
- "Game changer"
- "Deep dive"
- "At the end of the day"
- "Moving the needle"
- "Low-hanging fruit"
- "Think about it"
- "Let that sink in"
- "Read that again"
- "Full stop."
- "Period."

## Banned Structures
- Em dashes (use commas or periods instead)
- Rule-of-three lists in hooks
- Numbered lists as the entire post body
- Emoji as bullet points
- More than 2 emojis per post
- Hashtag collections (max 2 hashtags, at end only)
- "1/ 2/ 3/" thread numbering on LinkedIn (fine on X)
```

4. Create `plugins/social-amplifier/shared/platform-rules.md`:
```markdown
# Platform Rules

## LinkedIn

### Format
- Length: 150-300 words (sweet spot for engagement)
- No external links in main post (put in first comment)
- Short paragraphs (1-3 sentences each)
- Line breaks between paragraphs (LinkedIn collapses without them)
- Hook must land in first 2 lines (before "see more" fold)

### What Works
- Personal stories with a professional insight
- Behind-the-scenes of building something
- Lessons from specific experiences (not generic advice)
- Contrarian takes backed by personal experience
- "I did X. Here's what happened." format

### What Fails
- Generic motivational content
- Engagement bait ("Like if you agree")
- Pure self-promotion without value
- Wall of text with no line breaks
- External links in main post body

### Emoji Rules
- Max 2 per post
- Never as bullet points
- Only at natural emphasis points

## X (Twitter)

### Format
- Single tweet: max 280 characters
- Thread: number tweets (1/ 2/ 3/), max 7 tweets
- No external links in first tweet (kills reach)

### What Works
- Sharp observations in 1-2 sentences
- Hot takes with evidence
- "I just [did thing]. [Surprising result]." format
- Threads that tell a story with a payoff
- Replies to trending conversations in your space

### What Fails
- Threads longer than 7 tweets
- Generic advice without specifics
- Pure promotion
- Too many hashtags (max 1-2)
- Engagement bait
```

5. Commit: `git add plugins/social-amplifier/agents/shared-instructions.md plugins/social-amplifier/skills/shared-instructions/ plugins/social-amplifier/shared/ && git commit -m "feat: shared instructions, anti-AI-tells, platform rules"`

### Task 1.5: Slash Commands

**Files:**
- Create: `.claude/commands/new-champion.md`
- Create: `.claude/commands/generate.md`
- Create: `.claude/commands/scan-trends.md`
- Create: `.claude/commands/scan-slack.md`

**Steps:**

1. Create `.claude/commands/new-champion.md`:
```markdown
Load the Social Amplifier plugin and run the new-champion onboarding flow.

Start by reading:
- `plugins/social-amplifier/agents/shared-instructions.md`
- `plugins/social-amplifier/skills/new-champion/SKILL.md`

Then run the interactive onboarding to create a champion profile.
```

2. Create `.claude/commands/generate.md`:
```markdown
Load the Social Amplifier plugin and generate content for champion: $ARGUMENTS

Start by reading:
- `plugins/social-amplifier/agents/shared-instructions.md`
- `plugins/social-amplifier/skills/generate-content/SKILL.md`

Load the champion's profile and tone-of-voice, then generate 2-3 post variations.
```

3. Create `.claude/commands/scan-trends.md`:
```markdown
Load the Social Amplifier plugin and scan trends for champion: $ARGUMENTS

Start by reading:
- `plugins/social-amplifier/skills/scan-trends/SKILL.md`

Load the champion's interests and find trending topics on LinkedIn/X.
```

4. Create `.claude/commands/scan-slack.md`:
```markdown
Load the Social Amplifier plugin and scan Slack for champion: $ARGUMENTS

Start by reading:
- `plugins/social-amplifier/skills/scan-slack/SKILL.md`

Find recent feature announcements relevant to the champion's interests.
```

5. Commit: `git add .claude/commands/ && git commit -m "feat: slash commands for all workflows"`

### Phase 1 Checkpoint

**Verify:** Plugin directory structure exists with all files. `cat plugins/social-amplifier/CLAUDE.md` returns the full routing table. All four `.claude/commands/*.md` files exist.

**Run:** `ls -R plugins/social-amplifier/` should show: .claude-plugin/ (plugin.json), CLAUDE.md, PLUGIN-DESCRIPTION.md, settings.json, agents/ (champion-router.md, shared-instructions.md), skills/ (champion-router/, shared-instructions/), shared/ (anti-ai-tells.md, platform-rules.md).

---

## Phase 2: Champion Onboarding Flow

> **Objective:** Interactive Q&A that builds a complete champion profile directory.
> **Exit Criteria:** Running `/new-champion` walks through all 8 onboarding steps and creates a valid champion directory with profile.json, tone-of-voice.md, inspirations.md, and rules.md.
> **Depends on:** Phase 1 (plugin scaffold exists)

### Task 2.1: New-Champion Skill

**Files:**
- Create: `plugins/social-amplifier/skills/new-champion/SKILL.md`

**Steps:**

1. Create `plugins/social-amplifier/skills/new-champion/SKILL.md`:
```markdown
---
name: new-champion
description: |
  Interactive onboarding flow that builds a champion's personal profile.
  Walks through 8 steps: name, role, interests, inspirations, writing samples, content preferences, confirmation, tone generation.

  Triggers on: new champion, onboard, set up, create profile, /new-champion.
---

# New Champion Onboarding

## Process (8 Steps)

Run each step sequentially. Wait for user input before proceeding.

### Step 1: Name

Ask: "What's your full name?"

Store as `name` in profile.json. Derive `champion_id` as kebab-case (e.g., "Dor Blech" -> "dor-blech").

### Step 2: Role

Ask: "What's your role at Base44? (e.g., Frontend Developer, Product Manager, CEO)"

Store as `role` in profile.json.

### Step 3: Interests Beyond Role

Ask: "What topics interest you beyond your job title? These become your content themes. Examples: UX design, developer tools, AI in production, startup culture, remote work, open source."

Store as `topics[]` array in profile.json. Accept 3-7 topics.

### Step 4: Inspirations - People

Ask: "Name 3-5 people you follow on LinkedIn or X whose content you enjoy. Share their profile URLs if possible."

For each URL provided:
- Use WebFetch to analyze their recent posts
- Extract: posting frequency, typical topics, tone (formal/casual/humorous), post length, use of stories vs data

Store in `inspirations.md` with analysis.

### Step 5: Writing Samples

Ask: "Share 2-3 posts you've written before (LinkedIn, X, blog, anything). If you haven't posted before, share messages from Slack or emails where you explained something you're proud of."

Analyze the samples for:
- Sentence length patterns (short/medium/long)
- Vocabulary level (simple/technical/mixed)
- Humor usage (none/light/frequent)
- Structure preference (story/list/insight)
- Energy level (measured/enthusiastic/intense)
- Use of personal anecdotes (rare/occasional/frequent)

### Step 6: Content Preferences

Ask: "What kind of posts do you want to create? Pick your top 3:"
- Behind-the-scenes of building at Base44
- Industry insights and hot takes
- Personal lessons from your work
- Feature announcements with a personal angle
- Technical deep-dives made accessible
- Career/growth reflections

Store as `content_preferences[]` in profile.json.

### Step 7: Confirmation

Present a summary of everything collected:

```
Here's what I understand about you:

Name: {name}
Role: {role}
Topics: {topics}
Inspirations: {inspirations list}
Writing style: {analysis summary}
Content types: {preferences}

Does this look right? Any corrections?
```

Wait for confirmation. Apply any corrections.

### Step 8: Tone-of-Voice Generation

Using all collected data, generate `tone-of-voice.md`:

```
Read the inspiration analysis + writing samples analysis.
Synthesize into a voice guide that captures THIS person's style.
```

The tone-of-voice.md must include:
- **Voice in one sentence** - e.g., "A frontend dev who gets excited about clean UX and explains complex things simply"
- **Sentence patterns** - typical lengths, structures
- **Vocabulary** - words they actually use, words they avoid
- **Energy** - their natural energy level
- **Humor** - how and when they use humor
- **Topics** - what they write about and their angle on it
- **The {Name} Test** - "Would {Name} copy-paste this and hit post without editing?"

## Output Files

After all steps, create the champion directory:

```
Bash(command="mkdir -p champions/{champion_id}/content-history")
```

Write these files:

1. `champions/{champion_id}/profile.json`:
```json
{
  "name": "Full Name",
  "champion_id": "kebab-case-id",
  "role": "Role at Base44",
  "topics": ["topic1", "topic2", "topic3"],
  "content_preferences": ["pref1", "pref2", "pref3"],
  "platforms": ["linkedin", "x"],
  "created": "YYYY-MM-DD",
  "version": 1
}
```

2. `champions/{champion_id}/tone-of-voice.md` - Generated voice guide

3. `champions/{champion_id}/inspirations.md` - People they follow + analysis

4. `champions/{champion_id}/rules.md`:
```markdown
# {Name}'s Content Rules

## Always
- Sound like {Name}, not an AI
- Use first person ("I")
- Reference personal experience when possible
- Match energy level: {level}

## Never
- Corporate marketing language
- Base44 press release tone
- Generic motivational content
- Emojis as bullet points

## Platform-Specific
- LinkedIn: {their preferred LinkedIn style}
- X: {their preferred X style}
```

## Verification

After creating all files, verify:
```
Read(file_path="champions/{champion_id}/profile.json")
Read(file_path="champions/{champion_id}/tone-of-voice.md")
Read(file_path="champions/{champion_id}/inspirations.md")
Read(file_path="champions/{champion_id}/rules.md")
```

Confirm all files exist and contain valid data. Report to user: "Champion profile created for {name}! You can now run /generate {champion_id} to create content."
```

2. Commit: `git add plugins/social-amplifier/skills/new-champion/ && git commit -m "feat: new-champion onboarding skill (8-step flow)"`

### Phase 2 Checkpoint

**Verify:** Run `/new-champion`, complete all 8 steps with test data for "Dor Blech". Check that `champions/dor-blech/` directory contains all 4 files (profile.json, tone-of-voice.md, inspirations.md, rules.md).

**Run:** `ls champions/dor-blech/` should list all expected files. `cat champions/dor-blech/profile.json` should be valid JSON with all fields populated.

---

## Phase 3: Content Generation Pipeline

> **Objective:** Generate 2-3 post variations in the champion's voice for LinkedIn or X.
> **Exit Criteria:** Running `/generate dor-blech` produces 2-3 post variations that match the champion's tone-of-voice, with different angles (personal, insight, product). Posts are correctly formatted for the target platform.
> **Depends on:** Phase 1 (router), Phase 2 (champion profile exists)

### Task 3.1: Content Specialist Agent

**Files:**
- Create: `plugins/social-amplifier/agents/content-specialist.md`

**Steps:**

1. Create `plugins/social-amplifier/agents/content-specialist.md`:
```markdown
---
name: content-specialist
description: Generates personal social content in the champion's voice
model: opus
tools:
  - Read
  - Write
  - Skill
  - TaskUpdate
skills:
  - shared-instructions
  - generate-content
memory: project
---

# Content Specialist

You generate personal social content for Base44 champions. Every post must sound like the champion wrote it themselves.

## Setup

Shared instructions (voice rules, anti-AI patterns) are pre-loaded via skills. Then load:

```
Read(file_path="champions/{champion_id}/profile.json")
Read(file_path="champions/{champion_id}/tone-of-voice.md")
Read(file_path="champions/{champion_id}/inspirations.md")
Read(file_path="champions/{champion_id}/rules.md")
Read(file_path="shared/platform-rules.md")
```

## Generation Process

1. **Understand the brief**: Topic + platform + any source material (Slack message, trend, user input)
2. **Find the personal angle**: How does THIS champion personally connect to this topic? What's their unique take based on their role, interests, and experience?
3. **Generate 3 variations** with different angles:
   - **Variation A: Personal experience** - "I" perspective, story-driven, what they saw/did/learned
   - **Variation B: Industry insight** - Their expert take on why this matters broadly
   - **Variation C: Feature/product angle** - What they helped build or use at Base44, from their personal view (NOT corporate marketing)
4. **Apply platform format**: LinkedIn (150-300 words, paragraphs) or X (280 chars or thread)
5. **Self-check against anti-ai-tells.md** before passing to Voice Guardian

## Output Format

Present variations clearly:

```
## Variation A: [Angle Name]
Platform: [LinkedIn/X]

[Full post text]

---

## Variation B: [Angle Name]
Platform: [LinkedIn/X]

[Full post text]

---

## Variation C: [Angle Name]
Platform: [LinkedIn/X]

[Full post text]
```

After Voice Guardian approval, log to `champions/{champion_id}/content-history/`:
```
Write(file_path="champions/{champion_id}/content-history/YYYY-MM-DD-{slug}.md",
      content="[approved post content + metadata]")
```

## Critical Rules

- ALWAYS "I" voice (never "we" - this is personal content)
- ALWAYS check tone-of-voice.md before writing
- NEVER use words from anti-ai-tells.md
- ALWAYS generate exactly 3 variations (unless user requests fewer)
- NEVER include more than 2 emojis per post
- NEVER include external links in main post body (LinkedIn/X both penalize this)
```

2. Commit: `git add plugins/social-amplifier/agents/content-specialist.md && git commit -m "feat: content-specialist agent"`

### Task 3.2: Generate-Content Skill

**Files:**
- Create: `plugins/social-amplifier/skills/generate-content/SKILL.md`

**Steps:**

1. Create `plugins/social-amplifier/skills/generate-content/SKILL.md`:
```markdown
---
name: generate-content
description: |
  Content generation pipeline for champions. Loads profile, generates 2-3 variations with different angles, passes through Voice Guardian.

  Triggers on: generate, write post, create content, linkedin post, tweet, thread, new post.
---

# Content Generation Pipeline

## Inputs Required

1. **champion_id** - Which champion (resolved by router)
2. **platform** - "linkedin" or "x" (ask if not specified)
3. **topic** - What to write about. Can come from:
   - User-provided topic
   - Slack message (from scan-slack)
   - Trending topic (from scan-trends)
   - Freeform brief

## Pipeline

### Step 1: Load Champion Context

```
Read(file_path="champions/{champion_id}/profile.json")
Read(file_path="champions/{champion_id}/tone-of-voice.md")
Read(file_path="champions/{champion_id}/rules.md")
Read(file_path="shared/anti-ai-tells.md")
Read(file_path="shared/platform-rules.md")
```

### Step 2: Determine Topic

If topic not provided, ask:

"What do you want to post about? Options:
- Paste a Slack message or announcement
- Describe a topic or experience
- I can scan Slack for recent features (/scan-slack {champion_id})
- I can find trending topics (/scan-trends {champion_id})"

### Step 3: Generate Variations

Generate 3 variations with different angles:

**Variation A: Personal Experience**
- Frame as "I did/saw/learned X"
- Include a specific detail or anecdote
- End with an insight, not a CTA

**Variation B: Industry Insight**
- Frame as "Here's what I think about X in the industry"
- Reference the champion's expertise area
- Take a stance (not fence-sitting)

**Variation C: Product/Feature Angle**
- Frame as "I helped build/use X at work"
- Personal pride or surprise about the outcome
- Not corporate marketing - personal reaction

Apply platform-specific formatting from platform-rules.md.

### Step 4: Voice Guardian

Pass all 3 variations to the voice-guardian agent for quality check.

If any variation scores <7: regenerate that variation from scratch.
If any variation scores 7-8: auto-rewrite with Voice Guardian feedback.
If variation scores 9+: approved, present to user.

### Step 5: Present Results

Show all approved variations to the user. Ask which one they want to use (or if they want edits).

### Step 6: Log

Save the chosen variation (or all if user wants them) to content history:
```
Write(file_path="champions/{champion_id}/content-history/YYYY-MM-DD-{topic-slug}.md",
      content="---\ndate: YYYY-MM-DD\nplatform: {platform}\ntopic: {topic}\nchosen: {A/B/C}\nscore: {guardian_score}\n---\n\n{post content}")
```
```

2. Commit: `git add plugins/social-amplifier/skills/generate-content/ && git commit -m "feat: generate-content skill with 3-variation pipeline"`

### Phase 3 Checkpoint

**Verify:** Assuming a champion profile exists at `champions/dor-blech/`, running `/generate dor-blech` should:
1. Load Dor's profile and tone-of-voice
2. Ask for platform (LinkedIn/X) and topic
3. Generate 3 variations
4. (Voice Guardian not yet built - Phase 4 adds this)

**Run:** `cat plugins/social-amplifier/agents/content-specialist.md` should show the full agent with all required sections.

---

## Phase 4: Voice Guardian Quality Gate

> **Objective:** Quality gate that checks personal voice fidelity and rejects AI-sounding content.
> **Exit Criteria:** Voice Guardian agent scores content 1-10 on a structured checklist. Content scoring <7 is regenerated. Content scoring 7-8 is auto-rewritten. Content scoring 9+ is approved. The guardian correctly rejects obviously AI-written content.
> **Depends on:** Phase 1 (shared anti-AI-tells), Phase 2 (champion profile for voice comparison)

### Task 4.1: Voice Guardian Agent

**Files:**
- Create: `plugins/social-amplifier/agents/voice-guardian.md`
- Create: `plugins/social-amplifier/skills/voice-guardian/SKILL.md`

**Steps:**

1. Create `plugins/social-amplifier/agents/voice-guardian.md`:
```markdown
---
name: voice-guardian
description: Quality gate for all champion content - checks personal voice fidelity and anti-AI-tells
model: sonnet
tools:
  - Read
  - Edit
  - Skill
  - TaskUpdate
skills:
  - shared-instructions
  - voice-guardian
memory: project
---

# Voice Guardian

You are the quality gate for all Social Amplifier content. Every piece of content passes through you before reaching the champion. Your job: score content against a structured checklist, then either approve or rewrite until it passes.

## Setup

Load shared instructions (pre-loaded via skills), then read:
```
Read(file_path="shared/anti-ai-tells.md")
Read(file_path="champions/{champion_id}/tone-of-voice.md")
Read(file_path="champions/{champion_id}/rules.md")
```

## 10-Point Checklist

Score each item PASS (1) or FAIL (0). Total = score out of 10.

### Anti-AI Tells (3 items)

1. **No AI vocabulary** - No words from anti-ai-tells.md banned lists (verbs, adjectives, adverbs). Check every word.
2. **No AI structure** - No rule-of-three, no contrast framing, no self-narration, no significance inflation, no transition openers, no em dashes, no synonym cycling. Read the full banned structures list.
3. **No AI phrases** - No "I'm excited to announce", no "thrilled to share", no "game changer", no "deep dive", no "let that sink in". Check the full banned phrases list.

### Personal Voice (4 items)

4. **Matches champion's tone** - Compare against tone-of-voice.md. Does the vocabulary, sentence length, energy, and humor match THIS person?
5. **Uses champion's topics** - Is the content within the champion's declared interest areas from profile.json?
6. **Feels personal** - Does it include a specific detail, anecdote, or personal perspective? Generic content fails.
7. **The {Name} Test** - Would this champion copy-paste this and hit post without editing? If they'd need to "fix it up", it fails.

### Platform Format (2 items)

8. **Correct format** - LinkedIn: 150-300 words, short paragraphs, hook in first 2 lines. X: under 280 chars (single tweet) or properly numbered thread.
9. **No link/emoji violations** - No external links in main post body. Max 2 emojis. No emoji bullets.

### Independence (1 item)

10. **Not corporate** - Does NOT sound like a Base44 press release, marketing campaign, or brand account post. "I" voice, personal angle, no corporate jargon.

## Scoring

- **9-10**: APPROVED. Ship it.
- **7-8**: AUTO-REWRITE. Identify failing items. Rewrite the content fixing ONLY those items while preserving everything that passed. Re-score after rewrite.
- **<7**: REJECT. Tell the content-specialist to regenerate from scratch with specific feedback on what failed.

## Rewrite Rules

When rewriting (score 7-8):
- Keep the overall structure and angle
- Fix ONLY the failing items
- Do NOT over-polish (over-polishing is itself an AI tell)
- Re-read the champion's tone-of-voice.md before rewriting
- After rewrite, re-score. If still <9, try once more. If still fails after 2 rewrites, flag to user.

## Output Format

```
## Voice Guardian Review

**Champion:** {name}
**Platform:** {platform}
**Score:** {X}/10

### Checklist
1. No AI vocabulary: PASS/FAIL - {notes}
2. No AI structure: PASS/FAIL - {notes}
3. No AI phrases: PASS/FAIL - {notes}
4. Matches tone: PASS/FAIL - {notes}
5. Champion topics: PASS/FAIL - {notes}
6. Feels personal: PASS/FAIL - {notes}
7. The {Name} Test: PASS/FAIL - {notes}
8. Correct format: PASS/FAIL - {notes}
9. No link/emoji violations: PASS/FAIL - {notes}
10. Not corporate: PASS/FAIL - {notes}

### Verdict: APPROVED / REWRITE / REJECT
{If REWRITE: specific items to fix}
{If REJECT: what went wrong and guidance for regeneration}
```
```

2. Create `plugins/social-amplifier/skills/voice-guardian/SKILL.md`:
```markdown
---
name: voice-guardian
description: |
  Quality gate skill. Loads anti-AI-tells and champion voice profile for comparison.
  Used by the voice-guardian agent to score and approve/rewrite content.
disable-model-invocation: true
---

# Voice Guardian Skill

## Reference Files

Load these before scoring:
```
Read(file_path="shared/anti-ai-tells.md")
Read(file_path="champions/{champion_id}/tone-of-voice.md")
Read(file_path="champions/{champion_id}/rules.md")
```

## Scoring Thresholds

- 9-10/10: APPROVED (ship)
- 7-8/10: AUTO-REWRITE (fix failing items, re-score)
- <7/10: REJECT (regenerate from scratch)

## Max Rewrite Attempts: 2

After 2 failed rewrites, escalate to the user with the best version + specific feedback.
```

3. Commit: `git add plugins/social-amplifier/agents/voice-guardian.md plugins/social-amplifier/skills/voice-guardian/ && git commit -m "feat: voice-guardian agent with 10-point checklist"`

### Phase 4 Checkpoint

**Verify:** Voice Guardian agent file exists with complete 10-point checklist. Skill file exists with correct `disable-model-invocation: true` setting.

**Test (manual):** Feed the Voice Guardian an obviously AI-written LinkedIn post (full of em dashes, "I'm thrilled to share", "groundbreaking", rule-of-three). It should score <7 and REJECT. Feed it a natural-sounding personal post. It should score 9+.

---

## Phase 5: Trend Scout + Slack Scanner

> **Objective:** On-demand scanning for content inspiration from LinkedIn/X trends and Slack feature channels.
> **Exit Criteria:** `/scan-trends dor-blech` returns 3-5 trending topics relevant to Dor's interests. `/scan-slack dor-blech` returns recent feature announcements from Slack with suggested angles.
> **Depends on:** Phase 2 (champion profile for interest filtering)

### Task 5.1: Trend Scout Agent + Skill

**Files:**
- Create: `plugins/social-amplifier/agents/trend-scout.md`
- Create: `plugins/social-amplifier/skills/scan-trends/SKILL.md`

**Steps:**

1. Create `plugins/social-amplifier/agents/trend-scout.md`:
```markdown
---
name: trend-scout
description: Scans LinkedIn and X for trending topics relevant to champion's interests
model: sonnet
tools:
  - Read
  - WebFetch
  - Skill
  - TaskUpdate
skills:
  - scan-trends
memory: project
---

# Trend Scout

You scan LinkedIn and X for trending discussions relevant to a champion's interests.

## Setup

```
Read(file_path="champions/{champion_id}/profile.json")
Read(file_path="champions/{champion_id}/inspirations.md")
```

## Scanning Process

1. Load champion's `topics[]` from profile.json
2. For each topic, search for trending content:
   - Use Bright Data MCP (if available) to scrape LinkedIn/X for recent popular posts
   - Fallback: Use WebFetch on known industry sources, Twitter trending, LinkedIn pulse
3. Filter results by relevance to champion's specific interests
4. For each trending topic found, suggest 2-3 content angles personalized to the champion

## Output Format

```
## Trending Topics for {Name}

### 1. {Topic Title}
**Source:** LinkedIn / X
**Why it's relevant:** Connects to your interest in {topic from profile}
**Suggested angles:**
- A: {personal experience angle}
- B: {industry insight angle}
- C: {Base44 connection angle}

### 2. {Topic Title}
...

Want me to generate a post on any of these? Just say which one.
```

## Fallback

If Bright Data MCP is not connected:
- Use WebFetch on tech news sources (TechCrunch, Hacker News, etc.)
- Check if champion's inspirations have recent posts (WebFetch their profiles)
- Report: "Bright Data not connected. Using web search fallback. For better trend data, connect Bright Data MCP."
```

2. Create `plugins/social-amplifier/skills/scan-trends/SKILL.md`:
```markdown
---
name: scan-trends
description: |
  Scans LinkedIn and X for trending topics filtered by champion interests.
  Uses Bright Data MCP for social scraping, falls back to WebFetch.

  Triggers on: trends, trending, what's hot, popular topics, scan trends.
---

# Trend Scanning Skill

## Dependencies

- **Bright Data MCP** (preferred): Social media scraping for LinkedIn/X trends
- **WebFetch** (fallback): General web scraping for tech news and trends

## Process

1. Load champion profile to get topics and inspirations
2. Query trending content matching those topics
3. Filter by recency (last 7 days) and engagement
4. Return top 5 trending topics with personalized angles

## Bright Data Queries

For LinkedIn:
- Search posts by keywords from champion's topics[]
- Filter by engagement (likes + comments > threshold)
- Prioritize posts from champion's inspirations list

For X:
- Search tweets by keywords from champion's topics[]
- Filter by retweets + likes
- Check trending hashtags in tech/startup space

## Fallback (No Bright Data)

Use WebFetch on:
- `https://news.ycombinator.com/` - Hacker News front page
- `https://techcrunch.com/` - Recent tech news
- Champion inspiration URLs from inspirations.md
```

3. Commit: `git add plugins/social-amplifier/agents/trend-scout.md plugins/social-amplifier/skills/scan-trends/ && git commit -m "feat: trend-scout agent and scan-trends skill"`

### Task 5.2: Slack Scanner Skill

**Files:**
- Create: `plugins/social-amplifier/skills/scan-slack/SKILL.md`

**Steps:**

1. Create `plugins/social-amplifier/skills/scan-slack/SKILL.md`:
```markdown
---
name: scan-slack
description: |
  Scans Slack feature channels for announcements worth turning into personal social content.
  Uses Slack MCP to read channels, filters by champion interests.

  Triggers on: scan slack, check slack, feature announcements, what's new, slack features.
---

# Slack Scanner Skill

## Dependencies

- **Slack MCP**: Required for reading Slack channels

## Process

### Step 1: Load Champion Context

```
Read(file_path="champions/{champion_id}/profile.json")
```

Extract `topics[]` and `role` for relevance filtering.

### Step 2: Scan Relevant Channels

Read recent messages from feature/product channels:
- #product-marketing-sync
- #general (for major announcements)
- #feat-* channels (feature-specific)
- Any channel the champion specifies

Use Slack MCP `list_channels` to discover available channels, then `read_messages` on relevant ones.

### Step 3: Filter by Relevance

For each message/announcement found:
- Score relevance to champion's topics (0-10)
- Only keep items scoring 7+
- Prioritize: shipped features > upcoming features > discussions

### Step 4: Generate Angles

For each relevant item, suggest 2-3 repurposing angles:

```
## Slack Finds for {Name}

### 1. {Feature/Announcement}
**Channel:** #{channel}
**Posted by:** {author}
**Summary:** {1-2 sentences}

**Content angles for you:**
- A: Personal reaction - "I just saw {feature} ship and {your take based on role}"
- B: Behind-the-scenes - "Our team built {feature} because {reason}"
- C: User value - "If you're a {persona}, {feature} means {benefit}"

### 2. {Feature/Announcement}
...

Want me to generate a post from any of these? Just pick one.
```

## Fallback (No Slack MCP)

If Slack MCP is not connected:
- Report: "Slack MCP not connected. Please connect it via Customize > Connect your tools > Slack."
- Offer alternative: "You can paste a Slack message or feature announcement directly and I'll help you write a post about it."
```

2. Commit: `git add plugins/social-amplifier/skills/scan-slack/ && git commit -m "feat: scan-slack skill for Slack feature discovery"`

### Task 5.3: Repurpose-Content Skill

**Files:**
- Create: `plugins/social-amplifier/skills/repurpose-content/SKILL.md`

**Steps:**

1. Create `plugins/social-amplifier/skills/repurpose-content/SKILL.md`:
```markdown
---
name: repurpose-content
description: |
  Transforms a Slack announcement, feature description, or existing content into a personal social post.
  Takes source material + champion context, finds the personal angle, generates variations.

  Triggers on: repurpose, turn this into, from slack, make a post from, rewrite as.
---

# Content Repurposing Skill

## Process

### Step 1: Load Champion + Source

```
Read(file_path="champions/{champion_id}/profile.json")
Read(file_path="champions/{champion_id}/tone-of-voice.md")
```

Source material comes from:
- Pasted Slack message
- Output from scan-slack skill
- Any text the user provides

### Step 2: Find the Personal Angle

The source material is usually corporate or technical. The job is to find THIS champion's personal angle:

1. What's the champion's connection to this feature/topic? (based on role and interests)
2. What would they personally find interesting about it?
3. How would they explain it to their network?

**Critical:** The output must NOT sound like a rewritten press release. It must sound like the champion spontaneously decided to share their take.

### Step 3: Generate Variations

Route to content-specialist agent with the source material and personal angle as context. The content-specialist generates 3 variations as usual.

### Step 4: Voice Guardian

All variations pass through Voice Guardian. Extra scrutiny on "not corporate" check since source material is corporate.
```

2. Commit: `git add plugins/social-amplifier/skills/repurpose-content/ && git commit -m "feat: repurpose-content skill for Slack-to-post pipeline"`

### Phase 5 Checkpoint

**Verify:** All scanning skills exist. `/scan-trends dor-blech` loads champion interests and attempts Bright Data (or falls back to WebFetch). `/scan-slack dor-blech` attempts Slack MCP (or reports not connected).

**Run:** `ls plugins/social-amplifier/skills/` should show: champion-router/, new-champion/, generate-content/, scan-trends/, scan-slack/, repurpose-content/, voice-guardian/, shared-instructions/.

---

## Phase 6: Memory System + Onboarding Docs

> **Objective:** Persistent memory across sessions and user-facing documentation.
> **Exit Criteria:** Memory initializes on first run. Onboarding doc explains how to install and use the plugin. Session patterns are logged.
> **Depends on:** Phase 1 (plugin structure)

### Task 6.1: Memory Templates

**Files:**
- Create: `plugins/social-amplifier/skills/champion-memory/SKILL.md`

**Steps:**

1. Create `plugins/social-amplifier/skills/champion-memory/SKILL.md`:
```markdown
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
```

2. Commit: `git add plugins/social-amplifier/skills/champion-memory/ && git commit -m "feat: champion-memory skill for persistent learning"`

### Task 6.2: Onboarding Documentation

**Files:**
- Create: `plugins/social-amplifier/onboarding.md`

**Steps:**

1. Create `plugins/social-amplifier/onboarding.md`:
```markdown
# Social Amplifier - Getting Started

> Set up in 5 minutes. Works in Claude Code or Claude Cowork.

## Step 1: Install the Plugin

**Claude Cowork:**
1. Go to Customize > Browse Plugins
2. Click + next to "Personal"
3. Select "Add marketplace from URL"
4. Paste: `https://github.com/blutrich/Social-Amplifier-agent`
5. Click Install

**Claude Code (terminal):**
The plugin is auto-detected when you open this repo in Claude Code.

## Step 2: Connect Slack (Recommended)

1. Go to Customize > Connect your tools
2. Find Slack and click Connect
3. Authorize the Base44 workspace

Slack connection lets the agent scan for feature announcements. Without it, you can still generate content by providing topics manually.

## Step 3: Create Your Champion Profile

Run: `/new-champion`

The agent will walk you through 8 questions to build your personal content profile:
1. Your name
2. Your role at Base44
3. Topics that interest you
4. People you follow on LinkedIn/X
5. Your own writing samples (posts, Slack messages, anything)
6. What kind of content you want to create
7. Review and confirm
8. Agent generates your tone-of-voice guide

This takes about 5-10 minutes. Do it once, use it forever.

## Step 4: Generate Your First Post

Run: `/generate {your-id}` (e.g., `/generate dor-blech`)

The agent will:
1. Ask what platform (LinkedIn or X)
2. Ask what topic (or offer to scan Slack/trends)
3. Generate 3 variations with different angles
4. Run quality check (Voice Guardian)
5. Present ready-to-post options

## Other Commands

| Command | What it does |
|---------|-------------|
| `/scan-trends {id}` | Find trending topics matching your interests |
| `/scan-slack {id}` | Find feature announcements worth posting about |

## Tips

- **Paste Slack messages** directly into the chat for instant repurposing
- **Give feedback** on generated content - the agent learns your preferences
- **Update your profile** anytime by running `/new-champion` again
- **Be specific** about topics - "write about the new auth feature I built" beats "write a post"

## Getting Help

- Slack: #claude-code-for-marketing-team
- Ofer: DM for plugin issues
```

2. Commit: `git add plugins/social-amplifier/onboarding.md && git commit -m "docs: onboarding guide for new champions"`

### Phase 6 Checkpoint

**Verify:** Memory templates and onboarding doc exist.

**Run:** `cat plugins/social-amplifier/onboarding.md` should show complete getting-started guide.

---

## Phase 7: Integration Test + First Pilot (Dor Blech)

> **Objective:** End-to-end test with Dor Blech as the first champion.
> **Exit Criteria:** Dor completes onboarding. Agent generates 3 post variations. Voice Guardian scores all 9+. Dor says "I would actually post this." At least one post gets published on LinkedIn or X.
> **Depends on:** All previous phases

### Task 7.1: Full Pipeline Test

**Steps:**

1. Run `/new-champion` with Dor Blech's real data:
   - Name: Dor Blech
   - Role: [Dor's actual role]
   - Topics: [Dor's actual interests]
   - Inspirations: [Dor's actual LinkedIn/X follows]
   - Writing samples: [Dor's actual past posts or Slack messages]

2. Verify champion profile created: `ls champions/dor-blech/`

3. Run `/generate dor-blech` for LinkedIn with a real topic

4. Verify Voice Guardian checks all 3 variations

5. [CHECKPOINT] Have Dor review the output: "Would you post any of these?"

6. If Dor approves: Dor publishes the post

7. Log the result in `.claude/social-amplifier/sessions.md`

### Task 7.2: Push to Remote

**Steps:**

1. Verify all files are committed: `git status`
2. Push to remote: `git push -u origin main`
3. Verify plugin is installable: Install from `https://github.com/blutrich/Social-Amplifier-agent` in a fresh Claude Code session

### Phase 7 Checkpoint

**Verify:**
- Dor's champion profile exists with all files
- At least one post was generated that Dor would actually publish
- Voice Guardian scored the approved post 9+/10
- Plugin is installable from the GitHub URL
- All files committed and pushed

---

## Risks

| Risk | Dimension | P | I | Score | Mitigation |
|------|-----------|---|---|-------|------------|
| Generated content sounds AI-written despite Voice Guardian | Quality | 3 | 5 | 15 | Iterate on anti-ai-tells.md based on Dor's feedback. Add failing patterns as they're discovered. |
| Tone-of-voice generation doesn't capture champion's real voice | Quality | 3 | 4 | 12 | Require 2+ writing samples during onboarding. Allow iterative refinement of tone-of-voice.md. |
| Bright Data MCP not available for trend scanning | Technical | 3 | 2 | 6 | WebFetch fallback built into trend-scout. Trend scanning is optional. |
| Slack MCP not connected | Technical | 2 | 3 | 6 | Graceful fallback: user can paste Slack messages directly. Clear error message with setup instructions. |
| Plugin manifest format wrong / plugin won't install | Technical | 2 | 4 | 8 | Test installation early (Phase 1 checkpoint). Reference working marketing-agent settings.json. |
| Champion has no writing samples to seed tone-of-voice | Quality | 2 | 3 | 6 | Fall back to analyzing inspirations only + ask more targeted questions about writing style. |

---

## Acceptance Checks

1. `ls -R plugins/social-amplifier/` - Should list: .claude-plugin/ (plugin.json), CLAUDE.md, PLUGIN-DESCRIPTION.md, settings.json, agents/ (champion-router.md, content-specialist.md, voice-guardian.md, trend-scout.md, shared-instructions.md), skills/ (9 skill directories including champion-memory/), shared/ (anti-ai-tells.md, platform-rules.md), champions/, onboarding.md
2. `ls .claude/commands/` - Should list: new-champion.md, generate.md, scan-trends.md, scan-slack.md
3. `cat plugins/social-amplifier/settings.json | python3 -c "import sys,json; json.load(sys.stdin); print('valid JSON')"` - Should print "valid JSON"
4. `ls champions/dor-blech/` (after Phase 7) - Should list: profile.json, tone-of-voice.md, inspirations.md, rules.md, content-history/
5. `cat champions/dor-blech/profile.json | python3 -c "import sys,json; d=json.load(sys.stdin); assert 'name' in d and 'topics' in d; print('valid profile')"` - Should print "valid profile"
6. Scenario: Feed Voice Guardian an AI-heavy post with em dashes, "thrilled to share", "groundbreaking" - Should score <7 and REJECT
7. Scenario: Feed Voice Guardian a natural personal post matching Dor's tone - Should score 9+ and APPROVE
8. `git remote -v` - Should show origin pointing to https://github.com/blutrich/Social-Amplifier-agent

## Success Criteria

- [ ] Plugin installs in Claude Code from GitHub URL
- [ ] `/new-champion` creates a complete champion profile directory (profile.json, tone-of-voice.md, inspirations.md, rules.md)
- [ ] `/generate {id}` produces 3 post variations in the champion's voice
- [ ] Voice Guardian correctly rejects AI-sounding content (score <7)
- [ ] Voice Guardian approves natural-sounding content (score 9+)
- [ ] Generated posts pass anti-AI-tells check (no em dashes, no banned vocabulary, no AI structures)
- [ ] Content feels personal, not corporate Base44 marketing
- [ ] Dor Blech actually posts generated content on LinkedIn or X

---

## Phase Dependency Map

- **Phase 1** (Scaffold): depends on nothing, creates plugin structure + router + shared rules, enables all subsequent phases
- **Phase 2** (Onboarding): depends on Phase 1 scaffold, creates champion profiles, enables Phase 3/4/5
- **Phase 3** (Content Gen): depends on Phase 1 (router) + Phase 2 (profiles), creates content pipeline, enables Phase 4
- **Phase 4** (Voice Guardian): depends on Phase 1 (anti-AI-tells) + Phase 2 (profiles for voice comparison), creates quality gate, enables Phase 7
- **Phase 5** (Scanning): depends on Phase 2 (profiles for interest filtering), creates trend/Slack scanning, optional for Phase 7
- **Phase 6** (Memory + Docs): depends on Phase 1 (plugin structure), creates persistence + documentation
- **Phase 7** (Integration): depends on ALL previous phases, validates end-to-end pipeline

## Phase Autonomy Classification

| Phase | Checkpoint Type | Classification | Reason |
|-------|----------------|----------------|--------|
| Phase 1: Scaffold | none | AFK | Pure file creation, no decisions needed |
| Phase 2: Onboarding | none | AFK | Skill file creation from design spec |
| Phase 3: Content Gen | none | AFK | Agent + skill creation from design spec |
| Phase 4: Voice Guardian | none | AFK | Agent + skill creation from design spec |
| Phase 5: Scanning | none | AFK | Agent + skill creation from design spec |
| Phase 6: Memory + Docs | none | AFK | Templates and documentation |
| Phase 7: Integration | human_verify | HITL | Requires Dor's real data and approval of generated content |
