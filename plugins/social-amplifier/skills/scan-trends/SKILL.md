---
name: scan-trends
description: |
  Scans fresh social signal via OctoLens for a specific champion. Returns recent mentions, trending topics, and narrative moments that match the champion's persona and interests. OctoLens is the primary source (tagged, sentiment-scored, pre-filtered per-persona). Bright Data is a fallback when OctoLens is unavailable.

  Use this skill when an operator wants to see what's trending for a specific champion before generating content, or when discover-subjects needs raw signal data to score. Triggers on: scan trends, trending, what's hot, popular topics, what's happening, show me trends.
---

# Scan Trends Skill

The raw signal layer of the Social Amplifier pipeline. Queries social listening sources (OctoLens primary, Bright Data fallback) to return fresh mentions that match a specific champion's persona and topics.

## Relationship to Other Skills

This skill is the **data retrieval layer**. It returns raw filtered mentions but doesn't score, deduplicate, or pick subjects. That's the job of `discover-subjects`, which calls this skill and then applies the 5-factor scoring rubric.

When to use this skill directly vs `discover-subjects`:

- **Use scan-trends directly** when you want raw mention data for debugging, manual review, or custom analysis
- **Use discover-subjects** when you want actionable subject recommendations for content generation

In 95% of the scheduled pipeline flow, discover-subjects is the entry point and it calls scan-trends internally.

## Primary Source: OctoLens

OctoLens is the preferred signal source because it:

1. **Pre-ingests from 15+ platforms** — Reddit, Twitter, LinkedIn, Dev.to, GitHub, HackerNews, YouTube, TikTok, Bluesky, newsletters, podcasts, news sites
2. **Pre-tags each mention** — sentiment (positive/neutral/negative), relevance (high/medium/low), semantic tags (own_brand_mention, competitor_mention, industry_insights, buy_intent, user_feedback, bug_report, etc.)
3. **Has saved views that map to personas** — we use view IDs directly
4. **Handles the scraping we do not want to maintain** — no auth gates, no rate limits we manage

See `../discover-subjects/references/octolens-query-patterns.md` for the full query pattern library. Scan-trends uses the same patterns, just without the scoring step.

## Fallback: Bright Data

When OctoLens is unavailable, fall back to direct scraping via Bright Data MCP:

- `https://news.ycombinator.com/` — AI industry discussions
- Search URLs for keyword scans
- Reddit and Dev.to community pages
- Specific inspiration profile URLs

Bright Data is slower, noisier, and more expensive than OctoLens. Use it only as a fallback or for specific targeted scrapes.

## Process

### Step 1: Load Champion Context

```
Read(file_path="plugins/social-amplifier/champions/{champion_id}/profile.json")
```

Extract: persona, secondary_personas, topics[], platforms[], delivery_days, delivery_time_local.

### Step 2: Determine Source Strategy

Try OctoLens first by calling its context tool:

```
mcp__octolens__list_mentions_context()
```

If successful, proceed with OctoLens. If it errors, fall back to Bright Data and log the source change in the output (`source: bright_data` instead of `source: octolens`).

### Step 3: Query OctoLens Views

Load `../discover-subjects/references/octolens-query-patterns.md` for the persona-to-view mapping. Execute 1-3 queries depending on persona:

| Persona | Primary View | Secondary Filter |
|---------|-------------|------------------|
| comms | 20496 (Brand monitoring) | + 20500 (Crisis) for negative sentiment |
| marketing | 20498 (Competitor intelligence) | + 20497 (Buy intent) |
| dev | 20499 (Industry insights) | + tag:product_question |
| product | 20499 (Industry insights) | + tag:user_feedback |
| founder | 20511 (Positive) | + minXFollowers: 5000 |
| builder_indie | 20499 (Industry insights) | + keywords: base44, lovable, replit, anthropic |
| ops | tag:industry_insights + tag:bug_report | 7-day window |

Each query returns 20-50 mentions. Total candidates: typically 40-100 raw.

### Step 4: Normalize Output

Convert each OctoLens mention into the trend-candidate format:

```yaml
mention_id: 162839768
url: https://...
platform: twitter | reddit | linkedin | dev | youtube | other
author: "@handle"
sentiment: positive | neutral | negative
body: "Full mention text"
age_hours: 7
tags: [industry_insights, competitor_mention]
keywords: [base44]
octolens_relevance: relevant
source_type: octolens
```

### Step 5: Return Raw Candidates

Don't score, don't dedupe, don't rank. That's discover-subjects' job. Return the normalized list:

```yaml
status: ok
champion_id: {id}
source: octolens | bright_data | mixed
queried_at: {ISO timestamp}
window_hours: {N}
views_queried: [20496, 20500]
total_returned: 47
trends:
  - [normalized candidate 1]
  - [normalized candidate 2]
  ...
```

## Persona-Specific Examples

### Comms (Dor) - Crisis-Aware Scan

```
primary = mcp__octolens__list_mentions(
  view=20496,
  filters={
    "startDate": "{24h_ago_ISO}",
    "relevance": [0, 1],
    "!tag": ["promotional_post", "ai_generated"]
  },
  limit=50
)

crisis = mcp__octolens__list_mentions(
  view=20500,
  filters={
    "startDate": "{12h_ago_ISO}",
    "sentiment": ["Negative"]
  },
  limit=20
)
```

### Builder (Ofer) - Industry Narrative Scan

```
industry = mcp__octolens__list_mentions(
  view=20499,
  filters={
    "startDate": "{48h_ago_ISO}",
    "relevance": [0, 1],
    "keyword": [34724, 34728, 34729, 34731],
    "!tag": ["promotional_post"]
  },
  limit=40
)
```

### Founder (Maor) - High-Reach Amplification Scan

```
positive = mcp__octolens__list_mentions(
  view=20511,
  filters={
    "startDate": "{24h_ago_ISO}",
    "minXFollowers": 5000
  },
  limit=20
)
```

## Output Format For Direct Operator Calls

When called directly (not via discover-subjects), the operator wants a human-readable summary:

```
Top trends for {champion_name} ({persona}) as of {timestamp}:

1. [Twitter] @{author} (7h ago, neutral)
   "{first 100 chars of body}..."
   Tags: industry_insights, competitor_mention
   URL: {url}

2. [Reddit] u/{author} (12h ago, negative)
   "{first 100 chars of body}..."
   Tags: own_brand_mention, user_feedback
   URL: {url}

[5 more...]

Total: 47 candidates from OctoLens (3 queries, 24h window)
Next step: run /generate {champion_id} to create content based on these trends, or pick a number to focus on a specific trend.
```

## Migration Notes

Earlier versions of this skill used Bright Data as the primary source for LinkedIn and X scraping. That approach is now retired because:

- OctoLens pre-ingests and pre-tags the same data with sentiment + semantic categories
- Bright Data direct scraping is 10x slower and costs budget per request
- OctoLens saved views map cleanly to champion personas, Bright Data does not
- OctoLens handles auth gates and rate limits internally

Bright Data is retained for these specific use cases:

1. **Champion profile scraping during onboarding** (new-champion skill) — fetching the champion's own LinkedIn posts
2. **Inspiration analysis** (match-inspirations skill) — fetching specific people's writing samples
3. **Targeted source scrapes** when OctoLens doesn't index a specific platform
4. **Fallback** when OctoLens is unavailable

Do not use Bright Data for daily trend scanning — always prefer OctoLens.

## Reference Files

The query patterns and persona mappings live in the discover-subjects references rather than duplicated here:

- `../discover-subjects/references/octolens-query-patterns.md` — full query library
- `../discover-subjects/references/freshness-and-dedup.md` — recency windows per persona
- `../discover-subjects/references/scoring-rubric.md` — how scores are computed downstream

Read those when you need the details. This SKILL.md stays focused on the retrieval layer.
