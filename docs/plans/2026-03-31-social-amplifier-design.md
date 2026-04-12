# Social Amplifier Agent - Design

## Purpose
AI agent that helps Base44 employees (champions) create personal social media content on LinkedIn and X. Each champion gets a personalized voice profile - the agent generates ready-to-post content that feels authentically personal, not corporate.

## Users
Base44 employees ("champions") - starting with Dor Blech as pilot, then expanding to champions list from Shai, eventually open to all employees.

## Success Criteria
- [ ] Dor completes onboarding and has a valid champion profile
- [ ] Agent generates 2-3 post variations that Dor would actually post
- [ ] Generated content passes anti-AI-tells check (no emojis flood, no em dashes, no corporate language)
- [ ] Content feels personal, not branded Base44
- [ ] Dor actually publishes a generated post on LinkedIn or X

## Constraints
- Claude Code plugin architecture (fork of base44-marketing-agent)
- Must feel personal, not corporate/branded Base44
- No emojis overuse, must not look AI-generated
- Each champion has their own voice and interests
- Minimal friction after onboarding - bot runs, user just posts
- Remote repo: https://github.com/blutrich/Social-Amplifier-agent

## Out of Scope (v1)
- Visual/image generation (Nano Banana / Imagen - defer to v2)
- Scheduling/autopilot (auto-posting without user trigger - defer to v2)
- Automated daily scanning (manual trigger for v1)
- Multi-language support (English first)

## In Scope (v1)
- Champion onboarding (interactive Q&A → profile files)
- Content generation (topic/Slack → personal post)
- Voice Guardian (anti-AI-tells + personal voice quality gate)
- Slack scanning (on-demand, for feature announcements)
- LinkedIn + X trend scanning (on-demand, via Bright Data)
- Content repurposing (Slack notification → personal angle → post)

## Approach Chosen
Fork of base44-marketing-agent plugin structure. The key mapping: "brand" = "champion" (the person). Reuse router pattern, quality gate, anti-AI-tells, multi-variation, Slack integration, and memory system. Replace brand-focused agents with champion-focused ones.

## Architecture

```
Social-Amplifier-agent/                    (Claude Code Plugin)
├── plugins/social-amplifier/
│   ├── .claude-plugin/
│   │   └── plugin.json                   # Plugin manifest
│   ├── agents/
│   │   ├── champion-router.md            # Entry point - routes intent
│   │   ├── content-specialist.md         # Generates LinkedIn/X posts (Opus)
│   │   ├── voice-guardian.md             # Quality gate - personal voice check (Sonnet)
│   │   └── trend-scout.md               # Scans LinkedIn/X for trending topics (Sonnet)
│   ├── skills/
│   │   ├── champion-router/              # Intent detection + routing
│   │   ├── new-champion/                 # Onboarding flow
│   │   ├── generate-content/             # Content generation pipeline
│   │   ├── scan-trends/                  # Social media trend scanning
│   │   ├── scan-slack/                   # Slack feature discovery
│   │   ├── repurpose-content/            # Slack → personal angle → post
│   │   ├── voice-guardian/               # Anti-AI-tells + personal voice check
│   │   ├── anti-ai-tells/               # Shared banned patterns
│   │   └── shared-instructions/          # Common rules for all agents
│   ├── champions/                        # Per-champion profiles
│   │   └── {champion-id}/
│   │       ├── profile.json              # Name, role, interests, topics
│   │       ├── tone-of-voice.md          # Personal writing style guide
│   │       ├── inspirations.md           # People they follow, content they love
│   │       ├── content-history/          # Generated posts log
│   │       └── rules.md                  # Personal style rules
│   └── shared/
│       ├── anti-ai-tells.md              # Universal banned patterns
│       └── platform-rules.md             # LinkedIn/X format rules
└── .claude/
    ├── commands/
    │   ├── new-champion.md               # /new-champion
    │   ├── generate.md                   # /generate {champion_id}
    │   ├── scan-trends.md                # /scan-trends {champion_id}
    │   └── scan-slack.md                 # /scan-slack {champion_id}
    └── marketing/                        # Memory (persistent)
        ├── activeContext.md
        ├── patterns.md
        └── sessions.md
```

## Components

### 1. Onboarding (/new-champion)
Interactive Q&A that builds the champion's personal "brand":

- Step 1: Name → profile.json
- Step 2: Role at company → profile.json
- Step 3: Interests beyond role (e.g., frontend dev who loves UX) → profile.json topics[]
- Step 4: 3-5 people they follow on LinkedIn/X → inspirations.md
- Step 5: Their own posts (if any) → tone-of-voice.md seed
- Step 6: Content they enjoy reading → inspirations.md
- Step 7: Agent summarizes understanding, user confirms
- Step 8: Agent analyzes inspirations + samples → generates tone-of-voice.md

Output: Complete champion profile directory with all files.

### 2. Content Generation (/generate {champion_id})
1. Load champion profile + tone-of-voice
2. Check Slack for recent features/announcements (optional)
3. User provides topic OR agent suggests from Slack/trends
4. Generate 2-3 variations with different angles:
   - Variation A: Personal experience angle
   - Variation B: Industry insight angle
   - Variation C: Feature/product angle
5. Voice Guardian checks each variation
6. Present ready-to-post options

### 3. Voice Guardian (Quality Gate)
Adapted from Brand Guardian but checks personal voice:

1. No AI vocabulary (shared anti-ai-tells.md)
2. No AI structure (rule-of-three, em dashes, self-narration)
3. Matches champion's tone-of-voice.md
4. Uses champion's preferred topics/angles
5. Feels personal, not corporate
6. Correct platform format (LinkedIn length, X char limit)
7. No Base44 corporate marketing language
8. Would this person actually post this?

Scoring: 9+/10 = ship, 7-8 = auto-rewrite, <7 = regenerate.

### 4. Trend Scout (/scan-trends {champion_id})
1. Load champion interests + topics
2. Scrape LinkedIn/X via Bright Data for trending discussions
3. Filter by champion's interest areas
4. Present trending topics with suggested angles
5. User picks one → pipes into /generate

### 5. Slack Scanner (/scan-slack {champion_id})
1. Read recent Slack messages from feature channels
2. Filter by relevance to champion's interests
3. For each relevant item, suggest 2-3 repurposing angles
4. User picks angle → pipes into /generate with context

## Data Flow

1. Profile data flows into every generation (tone-of-voice always loaded)
2. Slack data is optional input - scanned on demand, filtered by champion interests
3. Trend data is optional input - scraped via Bright Data, filtered by champion topics
4. All content passes through Voice Guardian before reaching the user

## Error Handling

| Scenario | Handling |
|---|---|
| Champion profile missing | /generate stops: "Run /new-champion first" |
| No Slack connection | Skip Slack scanning, generate from topic/trends only |
| Bright Data unavailable | Skip trend scanning, generate from topic/Slack only |
| Voice Guardian scores <7 | Regenerate from scratch with different angle |
| WebFetch fails on inspiration URLs | Log warning, continue with available data |
| No writing samples from champion | Generate tone from inspirations only + ask more questions |
| Empty Slack scan | Fall back to trend-based or topic-based generation |

## Testing Strategy

Primary test: Dor reviews generated content and actually posts it.

| Test | How |
|---|---|
| Onboarding creates valid profile | Run /new-champion for Dor, verify all files exist |
| Tone captures personal style | Generate 3 posts, Dor reviews "would I actually post this?" |
| Anti-AI-tells work | No emojis flood, no em dashes, no "let's dive in" |
| LinkedIn format correct | Posts 150-300 words, proper structure, no hashtags |
| X format correct | Tweets under 280 chars, threads numbered |
| Slack scanning finds content | Run against real Slack, verify features surface |
| Voice Guardian catches bad content | Feed AI-written text, verify rejection |

## Questions Resolved
- Q: Platform? A: Claude Code commands/plugin
- Q: MVP scope? A: Onboarding + content generation (no automated scanning)
- Q: Success criteria? A: Dor actually posts generated content
- Q: Out of scope? A: Visual generation, scheduling/autopilot
- Q: Architecture? A: Fork of marketing plugin, champion = brand
- Q: First pilot? A: Dor Blech (fastest iteration)

## References
- Marketing agent: https://github.com/blutrich/base44-marketing-agent
- PR agent (onboarding inspiration): https://github.com/IsaacZevi/pr-agent
- Remote repo: https://github.com/blutrich/Social-Amplifier-agent
- Transcript: Dor Blech + Ofer Blutrich conversation (March 2026)
