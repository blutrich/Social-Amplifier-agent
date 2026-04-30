---
name: discover-subjects
description: |
  Discovers interesting subjects for a specific champion before content generation. Queries OctoLens (brand monitoring, industry insights, competitor intelligence), filters by the champion's topics and persona, dedupes against their content history, and returns the top 5 scored subjects with evidence and suggested angles.

  Use this skill before calling generate-content — it answers "what should this champion post about today?" without the operator having to pick a topic manually. Also use when a champion asks "what should I write about this week?".
---

# Discover Subjects Skill

The content pipeline needed a missing upstream step: **what should this champion write about?** Previously the flow assumed the operator (or the champion) picked a topic. Real usage needs automation — scan the signal sources, filter to this person's interests, score the candidates, present top 5. The champion never has to ask "what's worth posting about today?".

## When This Skill Runs

- **Before generate-content:** The scheduled pipeline calls this skill first to pick subjects, then passes the top result to generate-content
- **Manual discovery:** Operator runs `/discover {champion_id}` to see what's worth posting about right now
- **Champion request:** When a champion asks "what should I post this week?" via Slack DM, the feedback skill routes to this skill
- **Weekly digest:** The Monday morning pipeline uses this to generate a "5 subjects for your week" preview

## Core Algorithm (5 phases)

### Phase 1: Load Champion Context

```
Read(file_path="plugins/social-amplifier/champions/{champion_id}/profile.json")
Read(file_path="plugins/social-amplifier/champions/{champion_id}/style-preferences.md")
Read(file_path="plugins/social-amplifier/champions/{champion_id}/inspirations.md")
```

Extract:
- `topics[]` — what they care about
- `persona` — which OctoLens views to query
- `platforms` — constrains output format later
- `secondary_personas` — fallback signal sources
- Inspiration list — for the "are their people talking about this?" signal

Also list recent deliveries to avoid duplicate subjects:

```
Glob(pattern="plugins/social-amplifier/champions/{champion_id}/content-history/*.md")
```

Read the last 30 days of files to extract topics already covered. Never suggest a subject this champion already posted about in the last 30 days unless the angle is materially different.

### Phase 2: Query Signal Sources

**Details:** `references/octolens-query-patterns.md`

Pull fresh OctoLens mentions mapped to the champion's persona:

| Persona | Primary OctoLens View | Secondary filters |
|---------|----------------------|-------------------|
| comms | 20496 (Brand monitoring) + 20500 (Crisis management) | !promotional_post, !ai_generated |
| marketing | 20498 (Competitor intelligence) + 20497 (Buy intent) | min_engagement |
| dev | 20499 (Industry insights) + product_question tag | !promotional_post |
| product | 20499 (Industry insights) + user_feedback | last 48h |
| founder | 20511 (Positive) + high-reach | engagement top 10% |
| builder_indie | 20499 (Industry insights) + own_brand_mention | last 72h |
| ops | industry_insights + bug_report tag | last 7d |
| sales | 20498 (Competitor intelligence) + 20497 (Buy intent) | customer_win, roi_story, use_case tags |

Pull 20-40 recent mentions per view. Filter to last 24-72 hours. Apply persona-specific tag filters.

Optional secondary sources:
- Slack `#product-marketing-sync` and `#feat-*` channels for internal feature announcements (for builder/marketing personas)
- Bright Data LinkedIn activity feeds for the champion's inspirations (what are they writing about this week?)

### Phase 3: Filter and Dedupe

**Details:** `references/freshness-and-dedup.md`

Apply filters in order:

1. **Topic match:** Keep only mentions that plausibly match the champion's `topics[]`. Use substring/keyword matching against mention title + body.
2. **Recency:** Drop anything older than 72 hours (or 7 days for ops persona)
3. **Already covered:** Drop any subject whose topic matches a delivery from the last 30 days
4. **Sentiment fit:** For comms persona, prefer negative + brand-monitoring mentions (crisis response). For marketing, prefer competitor mentions. For dev/product, prefer user feedback and technical discussions. For sales, prefer customer wins, ROI proof points, and competitive differentiators.
5. **Language match:** Drop non-English mentions unless the champion's profile.json.platforms includes Hebrew/other languages

After filtering, you should have 10-30 candidate subjects. If you have fewer than 3, widen the time window and retry. If you have zero, return an honest "no strong subjects today" result.

### Phase 4: Score Candidates

**Details:** `references/scoring-rubric.md`

Score each candidate on 5 factors (each 0-10, total 50 max):

1. **Topic match** — How strongly does this subject align with the champion's declared topics? Exact match = 10, adjacent = 6, tangential = 3, unrelated = 0
2. **Recency** — 24h = 10, 48h = 7, 72h = 4, 7d = 1
3. **Engagement signal** — High engagement on the source mention signals audience interest. Use X follower count, LinkedIn reactions if available, Reddit upvotes, OctoLens relevance field.
4. **Inspiration resonance** — Is the champion's inspiration list talking about this? If an inspiration posted about the same topic in the last 7 days → +10 bonus. Partial match → +5.
5. **Originality** — Has the champion already posted something about this exact subject? 0 if duplicate, 10 if fresh angle. The 30-day dedup filter from Phase 3 should catch exact duplicates, this factor handles nuance (similar topic, different angle).

Sort descending by total score. Keep top 10 for presentation.

### Phase 5: Present Top 5

Return 5 subjects (top scorers) with structured metadata for each:

```markdown
## Subject 1: {headline}
**Score:** {total}/50 (topic:X, recency:X, engagement:X, inspiration:X, originality:X)
**Source:** {OctoLens URL or Slack permalink}
**Sentiment:** {positive | neutral | negative}
**Why this champion:** {1-sentence match explanation}
**Suggested angle:** {1-2 sentence angle that plays to their voice}
**Freshness:** {N hours/days ago}
**Inspiration signal:** {inspiration_name is also posting about this | none}
```

Five subjects per call — that gives operators/champions choice without overwhelming them. If the top 3 all score above 40/50, mark them as high-confidence picks. If the top scorer is below 25/50, mark the whole batch as "weak signal, consider skipping today".

## Reference Files

| File | When to Read | Purpose |
|------|-------------|---------|
| `references/octolens-query-patterns.md` | Always — phase 2 | Persona-to-view mapping, filter syntax, pagination |
| `references/freshness-and-dedup.md` | Always — phase 3 | Recency windows, duplicate detection, content-history matching |
| `references/scoring-rubric.md` | Always — phase 4 | The 5-factor scoring system with examples |
| `references/subject-output-schema.md` | Always — phase 5 | Output format for downstream skills to consume |

## Integration With Other Skills

- **Called by:** `scheduled-pipeline` (future), `generate-content` (when no topic provided), operator via `/discover {champion_id}`
- **Calls:** OctoLens MCP (`list_mentions`, `analytics`), Slack MCP (for internal feature signals), Bright Data (for inspiration activity — expensive, use sparingly)
- **Reads:** Champion profile, style-preferences, inspirations, content-history
- **Writes:** Nothing directly — returns subjects as structured output. The caller (generate-content or operator) decides what to do with them.

## Edge Cases

### No subjects found
If after all filtering the candidate list is empty, return an honest result:

```
No strong subjects for {champion_name} today.

Options:
1. Wait for tomorrow's scan (new mentions accumulate overnight)
2. Widen the time window: /discover {champion_id} --days=7
3. Pick a topic manually: /generate {champion_id} "your topic"
```

Don't fabricate subjects to fill the list. Silence is better than noise.

### Controversial/negative mentions for non-comms champions
If the top scorer is a negative brand mention and the champion isn't comms/PR, flag it as "recommended for Dor, not you" and skip. Dev champions shouldn't respond to pricing complaints — that's a comms job.

### Inspiration activity unavailable
If Bright Data quota is exhausted or inspiration profiles aren't scraped, Phase 4's inspiration signal becomes 0 for all candidates. That's fine — the other 4 factors still produce meaningful rankings.

### All candidates fail the 30-day dedup
If the champion has been posting frequently and all fresh mentions are duplicates of things they already covered, return:

```
{champion_name} has already posted about all 5 top subjects in the last 30 days.
Consider: wait for new topics, run /discover --days=14 to find less recent subjects, or pick a different angle on an existing subject.
```

## Output for Downstream Consumers

The `generate-content` skill accepts this skill's output as input. The top subject (or operator-selected subject) is passed with:

- Subject headline
- Source mention (OctoLens URL for context)
- Suggested angle
- Source sentiment (informs the tone of the response)
- Related inspiration (if any) — generate-content can match the inspiration's pattern

When no topic is explicitly provided to generate-content, it calls this skill first and picks the top subject automatically.

## The Champion's Experience

With this skill wired in:

**Before (manual):**
> Operator: "/generate dor-blech"
> Agent: "What topic?"
> Operator: "umm... something about the Anthropic ship button?"

**After (automated):**
> Operator: "/generate dor-blech"
> Agent runs discover-subjects → finds 5 top subjects for Dor's comms persona
> Agent picks top scorer: "Anthropic chat-to-app feature getting mixed reactions (28 mentions, 3 inspirations posting)"
> Agent runs generate-content with that subject
> Agent delivers 3 drafts via Slack DM

Zero operator choice required. The champion never asks "what should I post about?" because the pipeline answers that question before they can.
