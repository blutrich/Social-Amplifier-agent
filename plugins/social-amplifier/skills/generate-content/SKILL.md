---
name: generate-content
description: |
  The 6-phase content waterfall that runs every time you create content for a champion. Searches Slack for fresh feature context, checks what their inspirations are posting this week, loads their voice profile, generates 2-3 variations, scores them through Voice Guardian, and suggests visuals to pair with the post. End-to-end content creation in one sequential flow.

  Use this skill whenever an operator says "generate content for X" or runs /generate. This is the primary content creation entry point — it gathers all context before writing, instead of writing from a single thin prompt.

  Triggers on: generate, write post, create content, linkedin post, tweet, thread, new post, draft post for X.
---

# Generate Content - The Waterfall

The previous version of this skill jumped straight to writing. The operator (or champion) had to provide a topic, the agent generated from a thin prompt, results were mediocre. The waterfall fixes this by gathering context FIRST, then writing.

## The Waterfall (One Continuous Flow)

```
INPUT: champion_id (and optionally a topic seed)
        │
        ▼
┌───────────────────────────────────────────────────────────────┐
│ PHASE 1: GATHER SLACK CONTEXT                                  │
│ Search the champion's Slack for:                               │
│  • Recent feature announcements in #feat-* channels            │
│  • #product-marketing-sync recent posts                        │
│  • #features-intel-changelog-4marketing digests                │
│  • Anything they recently shared a link about                  │
│ Output: 3-10 recent Slack signals relevant to this champion    │
└───────────────────┬───────────────────────────────────────────┘
                    │
                    ▼
┌───────────────────────────────────────────────────────────────┐
│ PHASE 2: CHECK INSPIRATION ACTIVITY                            │
│ Load champions/{id}/inspirations.md                            │
│ For each inspiration (top 3-5):                                │
│  • Bright Data scrape: their last 7 days of LinkedIn posts     │
│  • Or OctoLens query if they're indexed as authors             │
│ Extract: what topics are they writing about THIS WEEK?         │
│ Output: list of topics + sample lines from inspirations        │
└───────────────────┬───────────────────────────────────────────┘
                    │
                    ▼
┌───────────────────────────────────────────────────────────────┐
│ PHASE 3: LOAD CHAMPION VOICE                                   │
│ Read champions/{id}/profile.json (topics, persona, platforms)  │
│ Read champions/{id}/tone-of-voice.md (8-dim writing analysis)  │
│ Read champions/{id}/style-preferences.md (per-champion bans)   │
│ Read champions/{id}/rules.md                                   │
│ Read last 30 days of content-history (avoid duplicate angles)  │
│ Output: complete voice context loaded into working memory      │
└───────────────────┬───────────────────────────────────────────┘
                    │
                    ▼
┌───────────────────────────────────────────────────────────────┐
│ PHASE 4: WRITE CONTENT (3 variations)                          │
│ Synthesize Phase 1 + 2 + 3 into the strongest signal           │
│ Pick the angle: Slack feature? Industry trend? Inspiration     │
│   echo? Personal experience?                                    │
│ Generate 3 variations using DIFFERENT angles                   │
│ Each variation respects the champion's tone-of-voice exactly   │
│ Each variation grounded in a specific detail from Phase 1/2    │
└───────────────────┬───────────────────────────────────────────┘
                    │
                    ▼
┌───────────────────────────────────────────────────────────────┐
│ PHASE 5: VOICE GUARDIAN SCORING                                │
│ For each variation, call voice-guardian skill                  │
│  • 10-point checklist with per-champion overrides              │
│  • Score 9+: ship                                              │
│  • Score 7-8: auto-rewrite (max 2 attempts)                    │
│  • Score <7: drop, regenerate from scratch                     │
│ Require: at least 1 variation passes 9+                        │
└───────────────────┬───────────────────────────────────────────┘
                    │
                    ▼
┌───────────────────────────────────────────────────────────────┐
│ PHASE 6: SUGGEST VISUAL                                        │
│ For the top approved variation, generate an image suggestion: │
│  • Feature post → suggest screenshot of the feature            │
│  • Industry take → suggest a relevant existing image or none  │
│  • Personal story → suggest none (text-only LinkedIn posts)    │
│  • Architecture explainer → suggest a diagram                  │
│ Output: image_suggestion field with type + description         │
└───────────────────┬───────────────────────────────────────────┘
                    │
                    ▼
OUTPUT: champion_id, 2-3 approved drafts, image suggestion,
         ready for deliver-content to send via Slack DM
```

Total time: 15-30 seconds for the gather phases, 10-30 seconds for generation, 10-20 seconds for Voice Guardian. End-to-end: under 60 seconds per champion.

## Process

### Phase 1: Gather Slack Context

**Details:** `references/slack-gathering.md`

The champion's voice is rooted in what they actually work on. Slack is where the work lives. Before writing, scan the champion's Slack to find fresh context:

```
# Channels they're active in (from Slack profile)
slack_search_users(query="{champion_real_name}") → user_id
slack_search_public_and_private(query="from:@{champion_username}", limit=20)
   → see what they recently mentioned

# Feature announcement channels
slack_read_channel(channel_id="C0AKHFFRS1Y", limit=20)  # features-intel-changelog
slack_read_channel(channel_id="{product-marketing-sync_id}", limit=20)

# Feature-specific channels they're in (filter by champion topics)
For each #feat-* channel matching champion topics:
  slack_read_channel(channel_id="{feat_channel_id}", limit=10)
```

Filter to messages from the last 48-72 hours. Extract substantive signals:
- A new feature shipped this week
- A discussion thread the champion was in
- A link the champion shared (article, post, doc)
- A milestone or metric update
- Something the champion said in a thread that could become a post

Discard:
- Bot output
- Pure links with no commentary
- Conversation chatter without substance

Output: a list of 3-10 Slack signals, each with permalink + body excerpt + why it's relevant to this champion.

### Phase 2: Check Inspiration Activity

**Details:** `references/inspiration-activity.md`

Load the champion's inspirations and check what they're posting about RIGHT NOW. This is the highest-signal context — if your inspirations are writing about a topic, that topic is hot in your space.

```
inspirations = read champions/{id}/inspirations.md
for each inspiration in top_5_inspirations:
    # Check OctoLens first (cheap)
    octolens_posts = mcp__octolens__list_mentions(
      filters={author: inspiration.handle, startDate: 7_days_ago}
    )
    
    # If not in OctoLens, scrape via Bright Data (expensive)
    if not octolens_posts:
        scraped = mcp__brightdata__scrape_as_markdown(url=inspiration.linkedin_url)
        parse posts from last 7 days
```

For each inspiration with recent activity, extract:
- The topics they posted about
- The angle they took
- 1 quoted hook line (verbatim, for voice reference)
- Engagement signal if available

Output: a map of `inspiration_name → {topics: [], hooks: [], angles: []}`. This becomes input for Phase 4 — the writer can echo or respond to what inspirations are saying.

If no inspirations are configured for the champion, skip this phase. Log "no inspirations configured, skipping Phase 2" so the operator knows to enrich the profile.

### Phase 3: Load Champion Voice

**Details:** Same as before — load the champion's profile files. This is unchanged from the old skill.

```
Read(file_path="plugins/social-amplifier/champions/{champion_id}/profile.json")
Read(file_path="plugins/social-amplifier/champions/{champion_id}/tone-of-voice.md")
Read(file_path="plugins/social-amplifier/champions/{champion_id}/style-preferences.md")
Read(file_path="plugins/social-amplifier/champions/{champion_id}/rules.md")
Glob(pattern="plugins/social-amplifier/champions/{champion_id}/content-history/*.md")
   # Load last 30 days of delivery logs to avoid angle duplicates
```

This phase is fast (~1 second). It loads the voice context that all generation depends on.

### Phase 4: Write Content

**Details:** `references/synthesis-and-angles.md`

Now synthesize Phases 1-3 into the strongest possible content angle. The writer has THREE potential signal sources to draw from:

| Source | Strongest When | Example |
|--------|---------------|---------|
| Slack feature signal | Champion is involved in or excited about a recent ship | "Just saw the new credits rollover feature in #feat-credits. Champion was active in that channel last week." |
| Inspiration echo | An inspiration is writing about a topic the champion has authority on | "Aakash Gupta posted about vibe coding category 4h ago. Ofer is at one of those startups." |
| Personal reflection | Champion has a recent experience worth sharing | "Champion just shipped X yesterday. Personal story angle." |

The waterfall picks the strongest signal automatically (or the operator overrides). Then it generates 3 variations using DIFFERENT angles built on that signal.

The 3 standard variation angles:
- **Variation A: Personal experience** ("I built X this week. Here's what I learned...")
- **Variation B: Industry insight** ("Everyone is saying X. Here's what they miss...")
- **Variation C: Echo + add** ("[Inspiration] said X. I'd add Y from my work on Z.")

Each variation:
- Grounds in a specific detail from Phase 1 or 2
- Respects the voice loaded in Phase 3
- Avoids angles already used in the last 30 days (per content-history)
- Uses the platform format from style-preferences (LinkedIn vs X)

If no Slack/inspiration signals exist (Phase 1 + 2 returned empty), fall back to generating from a generic topic prompt or the optional topic seed parameter.

### Phase 5: Voice Guardian Scoring

For each variation, call the voice-guardian skill:

```
for variation in variations:
    result = Skill(
      skill="voice-guardian",
      args="champion_id={champion_id} content={variation} platform=linkedin"
    )
    
    if result.verdict == "APPROVED":  # 9+/10
        approved_variations.append(variation)
    elif result.verdict == "REWRITE":  # 7-8/10
        rewritten = apply_rewrite_patterns(variation, result.failed_items)
        rescore = voice_guardian(rewritten)
        if rescore.verdict == "APPROVED":
            approved_variations.append(rewritten)
        # If rewrite still fails, drop the variation (don't re-rewrite endlessly)
    elif result.verdict == "REJECT":  # <7
        # Drop, don't try to fix - it needs fresh generation
        continue
```

Require at least 1 approved variation. If all 3 variations get REJECTED, regenerate from scratch with feedback to the writer ("the previous batch failed Voice Guardian on items X, Y. Try a different angle.").

If after one regeneration cycle the batch still fails, return an error: "no shippable content for {champion_id} today, voice gap too wide for current signal."

### Phase 6: Suggest Visual

**Details:** `references/image-suggestions.md`

For the TOP approved variation (highest Voice Guardian score), generate a visual suggestion. Most LinkedIn posts work better with text only (Maor's brand voice, Ofer's actual posting pattern shows zero images), but sometimes a visual elevates the post:

Decision tree:

```
if variation is about a SPECIFIC SHIPPED FEATURE:
    → suggest: "Screenshot of {feature_name}. Take it from {channel_url} or product."
    
elif variation is about a NUMBER or METRIC:
    → suggest: "Single-stat visual with the number prominent. Use Base44 brand template."
    → tool: nano-banana skill if available

elif variation is an ARCHITECTURE EXPLAINER:
    → suggest: "Simple diagram showing the architecture flow. Use Excalidraw or Pencil."
    → tool: pencil or excalidraw skill if available

elif variation is a PERSONAL STORY (no specific artifact):
    → suggest: "No image. Text-only posts often outperform when the story carries the post."
    → reasoning: Looking at this champion's history, text-only posts perform consistently

elif variation is a NEWS-TRIGGER REACTION:
    → suggest: "Optional: screenshot the original tweet/post being reacted to. Some champions use this."
    → reasoning: Check champion's history - if they typically include screenshots, suggest one
```

Output for the top variation only:

```yaml
image_suggestion:
  needed: true | false
  type: screenshot | metric_visual | diagram | none
  description: "1-sentence description of what the image should show"
  source_hint: "Where to get it - URL, Base44 product page, screenshot of Slack message, etc."
  generator_skill: nano-banana | pencil | excalidraw | none
  generator_prompt: "If using a generator skill, the exact prompt to feed it"
```

Don't auto-generate the image yet — that costs API calls and the operator should approve first. The suggestion gives the operator a one-click path to add a visual if they want.

## Output

The complete waterfall output:

```yaml
champion_id: dor-blech
generated_at: 2026-04-13T11:00:00+03:00
runtime_seconds: 47

phases:
  slack_gathering:
    status: ok
    signals_found: 7
    used_signals: 2
  inspiration_activity:
    status: ok
    inspirations_checked: 5
    inspirations_active_this_week: 3
  voice_loaded:
    status: ok
    has_style_preferences: true
    content_history_entries_30d: 4
  generation:
    variations_attempted: 3
    angles_used: [personal-experience, industry-insight, inspiration-echo]
  voice_guardian:
    variations_approved: 2
    rewrites_applied: 1
    rejections: 1
  image_suggestion:
    type: screenshot
    needed: true

variations:
  - rank: 1
    angle: personal-experience
    voice_guardian_score: 10
    text: |
      [full draft text]
    grounded_in:
      - "Slack signal: #feat-credits-rollover post from Liron Monitz, 18h ago"
      - "Inspiration echo: Aakash Gupta posted about Anthropic ship button 6h ago"
  
  - rank: 2
    angle: industry-insight
    voice_guardian_score: 9
    text: |
      [full draft text]
    grounded_in:
      - "OctoLens trend: Anthropic chat-to-shipped-app feature, 47 mentions in 24h"

image_suggestion:
  needed: true
  type: screenshot
  description: "Screenshot of the credits rollover feature from product UI"
  source_hint: "Take screenshot from app.base44.com → settings → credits page"
  generator_skill: none
  generator_prompt: null

next_step: Pass to deliver-content skill to send via Slack DM
```

This output feeds directly into `deliver-content` which formats and sends via Slack.

## Reference Files

| File | When to Read | Purpose |
|------|-------------|---------|
| `references/slack-gathering.md` | Always — Phase 1 | Which Slack channels to scan, how to filter signals |
| `references/inspiration-activity.md` | Always — Phase 2 | OctoLens vs Bright Data tradeoffs, parsing recent posts |
| `references/synthesis-and-angles.md` | Always — Phase 4 | How to pick the strongest signal and construct 3 variation angles |
| `references/image-suggestions.md` | Always — Phase 6 | Decision tree for when an image helps vs hurts |

The voice-loading phase (3) doesn't need a reference — it's just file reads documented in the SKILL.md body.

## Integration With Other Skills

- **Called by:** Operator via `/generate {champion_id}`, deliver-content (when no content provided), discover-subjects (when chained with auto-pick)
- **Calls in order:**
  1. Slack MCP (`slack_search_public_and_private`, `slack_read_channel`)
  2. OctoLens MCP (for inspiration author lookup)
  3. Bright Data (for inspiration LinkedIn scrapes when OctoLens misses)
  4. Voice Guardian skill (per variation scoring)
  5. Optionally nano-banana / pencil / excalidraw skills for image generation
- **Reads:** Champion profile files, content-history, shared/inspiration-seeds.json
- **Writes:** Nothing directly. The output goes to deliver-content which writes the delivery log.

## Why This Is The Waterfall You Asked For

The old skill was: input topic → write content. Thin and generic.

The new waterfall is: gather Slack context + check what inspirations are saying + load voice + write grounded in actual signal + score against per-champion rules + suggest visual. Six sequential phases that each contribute specific information to the final output.

Every variation generated this way is grounded in real context (from Slack or from an inspiration's post), not pulled from generic LLM knowledge. That's what makes the content feel like it came from someone who actually pays attention to their work and their network — because it did.

## When To Skip Phases

- **Phase 1 (Slack):** Skip if Slack MCP is unavailable or champion's Slack history is sparse (<10 messages in last 7 days). Generation still works from inspiration + voice alone.
- **Phase 2 (Inspirations):** Skip if no inspirations are configured for the champion. Fall back to OctoLens trends via discover-subjects.
- **Phase 4 angle constraints:** Skip variations whose angle conflicts with the last 7 days of delivered content (avoid same-angle repetition).
- **Phase 6 (Image):** Skip entirely if the champion's content history shows zero image attachments (text-only champions).

Each skip is logged in the output's `phases` section so the operator can see what context the writer had vs didn't have.

## The Champion's Experience

**Operator runs:** `/generate dor-blech`

**Behind the scenes (47 seconds):**
1. Phase 1 (12s): Searches Dor's Slack, finds 7 fresh signals including a feature he's involved in
2. Phase 2 (8s): Checks Dor's 5 inspirations, finds Aakash Gupta posted about vibe coding 6h ago
3. Phase 3 (1s): Loads Dor's voice, sees he's a comms persona with 4 recent posts
4. Phase 4 (15s): Generates 3 variations — one personal experience, one industry response to Aakash, one product reaction
5. Phase 5 (8s): Voice Guardian scores them — 10/10, 9/10, 6/10 (third gets dropped)
6. Phase 6 (3s): Suggests a screenshot of the feature for variation 1

**Operator sees:** 2 approved drafts + image suggestion + grounding evidence

**Operator runs:** `/deliver dor-blech` (or auto-chained)

**Dor sees:** Slack DM with 2 ready-to-post drafts, picks one, posts it.

Total operator effort: 2 commands. Total Dor effort: 30 seconds to read + post.
