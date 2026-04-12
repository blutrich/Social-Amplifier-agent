# Social Amplifier Agent

> Turn every Base44 employee into a thought leader — without the writing anxiety.

Social Amplifier is a Claude Code plugin that helps Base44 employees create authentic, personal social media content for LinkedIn and X (Twitter). Each person gets their own AI-powered content engine that writes in **their** voice, not the company's.

The idea is simple: the best marketing comes from real people sharing real perspectives. Social Amplifier removes the friction — you just hit post.

---

## How It Works

```
/new-champion          →  Build your personal voice profile (once)
/generate dor-blech    →  Get 3 ready-to-post variations
/scan-trends dor-blech →  See what's trending in your areas of interest
/scan-slack dor-blech  →  Turn Slack feature announcements into posts
```

Every piece of content passes through the **Voice Guardian** — a quality gate that catches AI tells (em dashes, "leverage", rule-of-three patterns) and ensures the post sounds like *you*, not a bot.

---

## Quick Start

### 1. Install the Plugin

**In Claude Code / Claude Cowork:**

1. Go to **Customize > Browse Plugins**
2. Click **+** next to "Personal"
3. Select **Add marketplace from URL**
4. Paste: `https://github.com/blutrich/Social-Amplifier-agent`
5. Click Install

### 2. Connect Slack (Recommended)

1. Go to **Customize > Connect your tools**
2. Find **Slack** and click Connect
3. Authorize the Base44 workspace

This lets the agent scan for feature announcements. Without it, you can still generate content by providing topics manually.

### 3. Create Your Champion Profile

```
/new-champion
```

The agent walks you through 8 questions (~5 minutes):

| Step | What it asks | Why |
|------|-------------|-----|
| 1 | Your name | Creates your champion ID (e.g., `dor-blech`) |
| 2 | Your role at Base44 | Shapes the perspective of your posts |
| 3 | What interests you beyond your role | A frontend dev who loves UX writes differently than one who loves performance |
| 4 | People you follow on LinkedIn/X | Learns the style and topics you gravitate toward |
| 5 | Your own posts (if any) | Seeds your personal tone of voice |
| 6 | Content you enjoy reading | Refines what "good" looks like for you |
| 7 | Agent summarizes, you confirm | "So you want to write about X, Y, Z?" |
| 8 | Tone-of-voice generated | Your personal writing style guide is saved |

**Do this once.** Your profile is reused for every future post.

### 4. Generate Your First Post

```
/generate dor-blech
```

The agent will:
1. Ask which platform (LinkedIn or X)
2. Ask for a topic (or offer to scan Slack/trends for ideas)
3. Generate **3 variations** with different angles:
   - **Personal experience** — your take, your story
   - **Industry insight** — broader context, trends
   - **Feature/product** — what you built and why it matters
4. Run Voice Guardian quality check
5. Present ready-to-post options — just copy and paste

---

## All Commands

| Command | What it does |
|---------|-------------|
| `/new-champion` | Interactive onboarding — builds your voice profile |
| `/generate {champion-id}` | Generate 2-3 post variations for LinkedIn or X |
| `/scan-trends {champion-id}` | Find trending topics matching your interests |
| `/scan-slack {champion-id}` | Find feature announcements worth posting about |

**Pro tips:**
- Paste a Slack message directly into the chat and say "turn this into a LinkedIn post for dor-blech"
- Say "write about the new auth feature" instead of "write a post" — specificity gets better results
- Give feedback ("too formal", "more like my other posts") — the agent learns

---

## Architecture

```
champion-router (ENTRY POINT)
        |
        +-- NEW_CHAMPION → new-champion skill (8-step onboarding Q&A)
        |
        +-- GENERATE → content-specialist (Opus) → voice-guardian (Sonnet)
        |
        +-- SCAN_TRENDS → trend-scout (Sonnet, Bright Data + WebFetch)
        |
        +-- SCAN_SLACK → scan-slack skill (Slack MCP)
        |
        +-- REPURPOSE → content-specialist → voice-guardian
```

### Agents

| Agent | Model | Purpose |
|-------|-------|---------|
| `content-specialist` | Opus | Generates LinkedIn/X posts in champion's personal voice |
| `voice-guardian` | Sonnet | Quality gate — anti-AI-tells + personal voice enforcement |
| `trend-scout` | Sonnet | Scans LinkedIn/X for trending topics via Bright Data |

### Skills

| Skill | Purpose |
|-------|---------|
| `champion-router` | Intent detection and workflow routing |
| `new-champion` | 8-step interactive onboarding |
| `generate-content` | Content generation pipeline (3 variations) |
| `voice-guardian` | 10-point quality checklist with auto-rewrite |
| `scan-trends` | LinkedIn/X trend scanning |
| `scan-slack` | Slack feature announcement discovery |
| `repurpose-content` | Turn raw content into personal-angle posts |
| `champion-memory` | Persistent learning across sessions |
| `shared-instructions` | Common rules injected into all agents |

### Plugin Structure

```
Social-Amplifier-agent/
├── .claude-plugin/
│   └── marketplace.json              # Marketplace manifest
├── plugins/social-amplifier/
│   ├── .claude-plugin/
│   │   └── plugin.json               # Plugin manifest
│   ├── CLAUDE.md                     # Routing table + architecture
│   ├── settings.json                 # Permissions + env vars
│   ├── onboarding.md                 # Setup guide
│   ├── agents/
│   │   ├── champion-router.md        # Router agent
│   │   ├── content-specialist.md     # Content generation (Opus)
│   │   ├── voice-guardian.md         # Quality gate (Sonnet)
│   │   ├── trend-scout.md            # Trend scanning (Sonnet)
│   │   └── shared-instructions.md    # Mandatory rules for all agents
│   ├── skills/
│   │   ├── champion-router/          # Intent detection + routing
│   │   ├── new-champion/             # Onboarding flow
│   │   ├── generate-content/         # Content pipeline
│   │   ├── voice-guardian/           # Quality checklist
│   │   ├── scan-trends/              # Trend scanning
│   │   ├── scan-slack/               # Slack scanning
│   │   ├── repurpose-content/        # Content repurposing
│   │   ├── champion-memory/          # Persistent memory
│   │   └── shared-instructions/      # Shared rules (data-only)
│   ├── shared/
│   │   ├── anti-ai-tells.md          # 80+ banned AI patterns
│   │   └── platform-rules.md         # LinkedIn + X format rules
│   └── champions/                    # Per-champion profiles (created at runtime)
│       └── {champion-id}/
│           ├── profile.json          # Name, role, interests, topics
│           ├── tone-of-voice.md      # Personal writing style guide
│           ├── inspirations.md       # People they follow, content they love
│           ├── rules.md              # Personal style rules
│           └── content-history/      # Generated posts log
├── .claude/
│   └── commands/
│       ├── new-champion.md           # /new-champion command
│       ├── generate.md               # /generate command
│       ├── scan-trends.md            # /scan-trends command
│       └── scan-slack.md             # /scan-slack command
└── docs/
    └── plans/
        ├── *-design.md               # Design document
        └── *-plan.md                 # Implementation plan
```

---

## Voice Guardian — The Quality Gate

Every piece of generated content passes through a **10-point checklist** before you see it:

| # | Check | What it catches |
|---|-------|----------------|
| 1 | No AI vocabulary | "leverage", "utilize", "delve", "tapestry", "landscape" |
| 2 | No AI structure | Rule-of-three, em dashes, self-narration, significance inflation |
| 3 | Matches your tone | Compares against your personal tone-of-voice.md |
| 4 | Your topics | Uses angles that match your declared interests |
| 5 | Feels personal | Not corporate, not branded, not "Base44 is proud to..." |
| 6 | Platform format | LinkedIn: 150-300 words. X: 280 chars or threaded |
| 7 | No corporate language | No "we're excited to announce" or marketing-speak |
| 8 | No engagement bait | No "What would you build?" or "Thoughts?" |
| 9 | No fake vulnerability | No "Honestly wasn't sure..." or "Not gonna lie..." |
| 10 | The Champion Test | Would this person actually post this? |

**Scoring:**
- **9-10/10** — Ship it. Ready to post.
- **7-8/10** — Auto-rewrite. Fixes issues and re-scores.
- **Below 7** — Regenerate from scratch.

---

## Anti-AI-Tells

The plugin maintains an extensive list of patterns that make content sound AI-generated:

**Banned verbs:** leverage, utilize, streamline, optimize, empower, facilitate, harness, navigate, spearhead, revolutionize, transform, elevate, foster, cultivate, synergize, amplify, catalyze, orchestrate, unlock, supercharge, turbocharge, reimagine, democratize, disrupt, pivot, scale, iterate, deep-dive...

**Banned adjectives:** groundbreaking, cutting-edge, game-changing, innovative, robust, seamless, holistic, transformative, dynamic, comprehensive, state-of-the-art, mission-critical, best-in-class, enterprise-grade, next-generation, paradigm-shifting...

**Banned structures:**
- Em dashes (single biggest AI tell in 2026)
- Rule-of-three ("Fast. Simple. Powerful.")
- Self-narration ("Here's why this matters:")
- Significance inflation ("A testament to...")
- Contrast framing ("It's not X, it's Y")
- Thread numbering on LinkedIn (fine on X)

---

## Content Repurposing

One of the most powerful features: turning Slack notifications into personal posts.

**How it works:**
1. A new feature ships and gets announced in Slack
2. Run `/scan-slack dor-blech` or paste the Slack message directly
3. The agent suggests 2-3 angles:
   - "As someone who built the auth system, here's why this matters..."
   - "The AI industry is moving toward X, and this feature is a signal..."
   - "I spent 3 weeks on this. Here's what I learned about Y..."
4. Pick an angle, and `/generate` creates the post

This is the key insight from the product vision: most people can't naturally see how a feature announcement becomes a personal thought-leadership post. The agent does this translation for them.

---

## Memory System

The plugin learns over time through persistent memory:

| File | What it tracks |
|------|---------------|
| `.claude/social-amplifier/activeContext.md` | Current focus, recent content, next steps |
| `.claude/social-amplifier/patterns.md` | What works per champion, phrases to use/avoid |
| `.claude/social-amplifier/sessions.md` | Session log (date, champion, content type, summary) |

Memory persists across sessions. The more you use it, the better it gets at your voice.

---

## Design Philosophy

This plugin was built around a conversation between Dor Blech (Comms) and Ofer Blutrich (Builder) at Base44. The core principles:

1. **Personal, not corporate.** Content should sound like the person, not the brand. It should be clear you're from Base44, but not feel like you're writing AS Base44.

2. **Zero friction after onboarding.** Once your profile is built, the bot runs autonomously. You just post.

3. **No AI tells.** If it looks AI-generated, it fails. Em dashes, "leverage", rule-of-three — all caught by Voice Guardian.

4. **Micro-influencer strategy.** Following the Lovable model: employees post individually, brand amplifies. Each person builds their own audience.

5. **Repurposing is the superpower.** Most people can't see how a Slack notification becomes a thought-leadership post. The agent does this translation.

---

## Roadmap

**v1 (Current):**
- Champion onboarding with tone-of-voice profiling
- Content generation with 3 variations
- Voice Guardian quality gate
- On-demand trend and Slack scanning
- Content repurposing

**v2 (Planned):**
- Visual generation (Nano Banana / Google Imagen 3)
- Automated daily scanning (scheduled, not on-demand)
- Auto-posting / scheduling
- Multi-language support
- Performance analytics per champion

---

## Contributing

This is an internal Base44 tool. To contribute:

1. Clone the repo
2. Test locally: `claude --plugin-dir ./plugins/social-amplifier`
3. Make changes
4. Run `/reload-plugins` to test without restarting
5. Push to main

For questions or issues: DM Ofer on Slack or post in `#claude-code-for-marketing-team`.

---

## License

MIT
