# Subject Scoring Rubric

The 5-factor scoring system used in Phase 4 of `discover-subjects`. Each candidate subject gets scored 0-10 on each factor, for a total of 0-50. Rankings come from the sum.

## Why 5 Factors, Not 1

A single-factor scoring (e.g., "relevance") produces brittle rankings. A mention can be highly relevant but 2 weeks old (stale), or fresh but from an account with 12 followers (low engagement signal), or both but identical to a post the champion already wrote last week. The 5 factors encode these tradeoffs explicitly.

## Factor 1: Topic Match (0-10)

**Question:** How strongly does this subject align with the champion's declared topics from `profile.json.topics[]`?

### Scoring

| Score | Criteria | Example (Ofer's topics: AI agent infra, marketing automation, building AI tools, Base44 product) |
|-------|---------|---------|
| 10 | Exact match to a listed topic | Mention about "MCP credentials in managed agents" matches "AI agent infrastructure" exactly |
| 8-9 | Direct adjacent topic | Mention about "LLM context windows" — adjacent to agent infra |
| 6-7 | Same domain, different angle | Mention about "Claude Code hooks" — same domain (builder tools), different specific topic |
| 4-5 | Same industry, tangential | Mention about "OpenAI embeddings" — related industry, not Ofer's focus |
| 2-3 | Weak thematic link | Mention about "SaaS pricing models" — marketing-adjacent but far from his declared topics |
| 0-1 | Unrelated | Mention about "crypto trading bots" — no connection |

### Matching Algorithm

Use simple substring matching first, then semantic similarity if the champion has many topics:

```python
def topic_match_score(mention_body, mention_tags, champion_topics):
    # Exact match check
    for topic in champion_topics:
        topic_keywords = topic.lower().split()
        if all(kw in mention_body.lower() for kw in topic_keywords):
            return 10
    
    # Partial match — count matching keywords
    match_count = 0
    for topic in champion_topics:
        topic_keywords = topic.lower().split()
        matches = sum(1 for kw in topic_keywords if kw in mention_body.lower())
        if matches > 0:
            match_count += matches
    
    # Map match count to score
    if match_count >= 5: return 9
    if match_count >= 3: return 7
    if match_count >= 2: return 5
    if match_count >= 1: return 3
    return 0
```

This is a heuristic — semantic similarity with embeddings would be more accurate but adds a dependency. Substring matching works well enough for the scoring signal.

### Gotcha

If the champion has very broad topics ("AI", "tech", "startups"), almost everything matches at 4-5. Narrow topics ("AI agent memory models", "MCP credential injection") give sharper signals. Encourage operators to keep topics specific during onboarding.

## Factor 2: Recency (0-10)

**Question:** How fresh is this mention?

### Scoring

| Score | Age | Rationale |
|-------|-----|-----------|
| 10 | < 6 hours | Just broke, catching it early = competitive advantage |
| 9 | 6-12 hours | Still fresh, most responders haven't chimed in yet |
| 8 | 12-24 hours | Yesterday's news, still actionable |
| 6 | 24-48 hours | Two-day-old news, narrative partially formed |
| 4 | 48-72 hours | Reaching the point where responding looks late |
| 2 | 3-7 days | Stale for news-type subjects, OK for evergreen topics |
| 1 | 7-14 days | Only useful if the subject is timeless |
| 0 | > 14 days | Dead for discovery purposes |

### Exceptions

Certain persona-subject combinations have different recency curves:

- **Crisis response (comms):** Recency weight is 2x. A 6-hour-old negative mention is more urgent than a 6-hour-old positive one.
- **Evergreen topics (product philosophy, architecture patterns):** Recency weight is 0.5x. A 3-day-old thoughtful post is just as good as a 6-hour-old one.
- **Ops (infrastructure):** 7-day window is normal. Ops mentions don't age out fast.

Apply the weight by multiplying the recency score before adding to the total:

```
adjusted_recency = raw_recency_score * persona_weight
```

## Factor 3: Engagement Signal (0-10)

**Question:** Does this mention have audience pull? Is it something people are actively discussing, or a tree falling in an empty forest?

### Scoring

OctoLens doesn't return engagement counts directly. Use proxies:

| Signal | Score Contribution |
|--------|-------------------|
| OctoLens `relevance: 0` (high) | +4 |
| OctoLens `relevance: 1` (medium) | +2 |
| Author has >10K followers (X/LinkedIn) | +3 |
| Author has 1K-10K followers | +1 |
| Post on high-engagement platform (Reddit, Dev.to, HackerNews) | +2 |
| Post on medium platform (LinkedIn, Twitter) | +1 |
| Post has multiple tags (signals rich content) | +1 |
| Subject is a quoted-reply or debate (signals engagement in progress) | +2 |
| OctoLens `engaged: true` (someone in your org already reacted) | +2 |

Sum the contributions, cap at 10.

### Author Credibility Check

For high-score subjects, verify author isn't a known low-quality account:

- Bot signals (obvious account names like "crypto_trader_42069")
- Account age < 30 days (OctoLens doesn't provide, but URL can hint)
- Single-topic spam (only promotes one thing)

If any of these flags, subtract 5 from the engagement score.

## Factor 4: Inspiration Resonance (0-10)

**Question:** Is the champion's inspiration list actively talking about this subject? If yes, responding amplifies the conversation loop with their chosen voices.

### Scoring

Load `champions/{id}/inspirations.md` and check if any inspiration has recently posted about the same topic:

```
for each inspiration in champion.inspirations:
    if inspiration has posted about mention.topic in last 7 days:
        if inspiration posted in last 24h: +10
        if inspiration posted in last 48h: +7
        if inspiration posted in last 7 days: +4
```

Cap at 10. Only count the highest-scoring match (don't stack).

### How to Check Inspiration Activity

Three options, ranked by cost:

**Option A (cheapest): OctoLens keyword overlap**
If the mention has keywords and any inspiration's known posts in OctoLens (within 7 days) share those keywords, score +5. This is free but imprecise.

**Option B (moderate): Slack reference check**
Has the champion (or anyone in their org) shared a link from this inspiration in the last 7 days? If yes, assume the inspiration is active on relevant topics. Score +4.

**Option C (expensive, accurate): Bright Data scrape**
Scrape the inspiration's LinkedIn/X feed for recent posts. Check if any of the last 10 posts match the mention's topic. This is accurate but costs Bright Data budget.

Default to Option A for daily scans. Use Option C only for high-value daily picks or weekly digests.

### Gotcha

If the champion has zero configured inspirations, this factor scores 0 across the board. That's fine — the other 4 factors still produce meaningful rankings. But it's a signal that the champion's profile should be enriched with inspirations.

## Factor 5: Originality (0-10)

**Question:** Has the champion already posted something about this exact subject? Fresh angles matter even on repeated topics.

### Scoring

| Score | Criteria |
|-------|---------|
| 10 | No similar post in content-history. Completely fresh subject for this champion. |
| 8 | Similar topic appeared 30+ days ago, can revisit with updated context |
| 6 | Similar topic in last 30 days, but this mention offers a clearly different angle |
| 4 | Similar topic in last 14 days, small angle variation |
| 2 | Same topic in last 7 days, only minor nuance |
| 0 | Duplicate of something posted in last 7 days |

### Duplicate Detection Algorithm

1. Load all content-history files from the last 30 days
2. Extract subject keywords from each historical file's frontmatter
3. Compute keyword overlap with the candidate subject
4. Score by overlap percentage:
   - >80% overlap → score 0-2
   - 50-80% → score 4-6
   - 20-50% → score 7-8
   - <20% → score 9-10

### Angle-Aware Dedup

A champion can write about the same topic twice if the ANGLE is different. Examples:

- Week 1: "I built a Voice Guardian for my internal tool" (personal-experience angle, score 10)
- Week 2: "The Voice Guardian turned out to be the whole product" (architecture angle, different hook) — score 6 because angle is different
- Week 3: "Building a Voice Guardian: lessons from 70 days" (how-to angle) — score 5

Score 0 only if the angle is literally identical, not just the topic.

## Total Score and Thresholds

Sum all 5 factors (0-50 range). Map to decision thresholds:

| Total Score | Status | Action |
|-------------|--------|--------|
| 40-50 | High confidence | Auto-proceed to generation |
| 30-39 | Good signal | Proceed, present as top recommendation |
| 20-29 | Weak signal | Present with caveat, let operator decide |
| 10-19 | Marginal | Include in top 5 only if nothing better exists |
| 0-9 | Skip | Don't include in output |

## Example Scoring: Subject About Anthropic Ship Button for Ofer

```
Subject: "Anthropic's 'ship button' in Claude sparks 'vibe coding dead' viral narrative"
Source: Twitter, @jbuilderx, 7 hours old, 85 reactions, relevance: 0 (high)

Factor 1 (topic match): 10
  - Ofer's topics include "AI agent infrastructure" and "Ship-in-public builder journey"
  - Mention directly concerns AI builder tools and competitive landscape
  - Exact match

Factor 2 (recency): 9
  - 7 hours old → base 9
  - Builder persona, standard weight 1.0 → 9

Factor 3 (engagement): 8
  - OctoLens relevance: 0 → +4
  - @jbuilderx has 8K followers → +1
  - Twitter (medium platform) → +1
  - Multiple tags (competitor_mention, industry_insights) → +1
  - Subject is part of ongoing narrative debate → +2
  - Total: 9, capped at 10... wait, that's 9 actually. Let me recount.
  - Actually: 4 + 1 + 1 + 1 + 2 = 9. Close to cap.

Factor 4 (inspiration): 8
  - Aakash Gupta (Ofer's inspiration) posted the original tweet this narrative derives from
  - Aakash posted in last 24h → +10 (but cap at 10)
  - Actually: Aakash started the narrative, other inspirations (Jack Clark) are commenting on it
  - Score 8 (strong resonance, not perfect because Aakash's post itself isn't the mention being scored)

Factor 5 (originality): 7
  - Ofer hasn't posted about this specific narrative yet
  - He has posted about Anthropic's managed agents (adjacent topic) 2 days ago
  - Score 7 (fresh angle on adjacent theme)

Total: 10 + 9 + 9 + 8 + 7 = 43/50
Status: HIGH CONFIDENCE → auto-proceed
```

## Example Scoring: Low-Match Subject for Same Champion

```
Subject: "New study shows remote work reduces employee loneliness"
Source: LinkedIn post from Harvard Business Review, 3 days old, 500 reactions

Factor 1 (topic match): 1 — nothing to do with Ofer's topics
Factor 2 (recency): 4 — 3 days old, mid-stale
Factor 3 (engagement): 7 — high-authority source, strong engagement signal
Factor 4 (inspiration): 0 — no inspiration resonance
Factor 5 (originality): 10 — Ofer has never posted about remote work

Total: 1 + 4 + 7 + 0 + 10 = 22/50
Status: WEAK SIGNAL → filtered out of top 5
```

The high engagement and perfect originality score don't save this — the topic match is too weak and nobody Ofer follows cares about it.

## Calibration Notes

After shipping, track the correlation between discover-subjects total_score and actual post performance (champion accept rate, generated post engagement). If total_score of 40+ posts routinely get rejected or perform poorly, the scoring weights need tuning. Log this in patterns.md under "Common Gotchas" so the operator can adjust.

Early calibration hypothesis: topic_match and inspiration are the highest-leverage factors. Recency matters but is easy to game (always recent is always 10). Engagement is noisy. Originality is important but binary — mostly 0 or 10, rare middle values.
