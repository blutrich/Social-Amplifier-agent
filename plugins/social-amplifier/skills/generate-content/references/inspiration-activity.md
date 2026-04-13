# Inspiration Activity Check (Phase 2 of the Generate-Content Waterfall)

How to check what the champion's inspirations are posting about THIS WEEK. This is the highest-signal external context — if your inspirations are writing about a topic, that topic is hot in your space and you should consider weighing in.

## Why This Phase Matters

Inspirations are people the champion explicitly wants to learn from or sound like. When they post, three things are true:

1. The topic is current (they thought it was worth their time today)
2. The angle is one the champion's audience also cares about (they share readership)
3. The voice patterns are validated (the inspirations write the way the champion aspires to write)

When the champion responds to or builds on what an inspiration just posted, the resulting post has:
- A built-in audience (the inspiration's followers might engage)
- Pre-validated topic relevance
- Voice patterns the champion already wants to emulate
- Network effects (the inspiration might engage back)

This is the highest-leverage signal we have. Always check it before writing.

## Loading Champion Inspirations

```
inspirations = read champions/{id}/inspirations.md
```

Parse out the top 3-5 inspirations. The file format from the inspiration-seeds.json has each inspiration with:
- name
- linkedin handle (if available)
- twitter handle (if available)
- why they were chosen
- voice signature

If `inspirations.md` is empty or missing (champion hasn't been onboarded with inspirations yet), skip this entire phase. Log "no inspirations configured" so the operator knows to enrich the profile.

## Approach 1: OctoLens Author Search (Cheap, Try First)

OctoLens indexes posts from many platforms. If the inspiration is indexed as an author, we can pull their recent posts cheaply:

```
mcp__octolens__list_mentions(
  filters={
    "startDate": "{7_days_ago_ISO}"
  },
  limit=100
)
```

Then filter the response by `author` matching any of the inspiration's known handles. This is a single OctoLens call that covers ALL inspirations at once.

If the champion has 5 inspirations, this single call returns posts by any of them in the last 7 days. Group by author and you have a per-inspiration activity map.

**Limitation:** OctoLens only indexes authors who frequently mention tracked keywords. If an inspiration doesn't talk about Base44/Lovable/Replit/Anthropic, they won't be in OctoLens. Fall back to Approach 2.

## Approach 2: Bright Data Scrape (Expensive, Use When OctoLens Misses)

For inspirations not indexed by OctoLens, scrape their LinkedIn profile directly:

```
mcp__brightdata__scrape_as_markdown(
  url="https://www.linkedin.com/in/{inspiration_handle}/"
)
```

Then parse the activity feed for posts in the last 7 days. The scrape returns a large file (50-150KB) — use a subagent to extract just the recent posts:

```python
def extract_recent_posts(scrape_result, days=7):
    # Parse the activity feed
    # Filter to posts within last N days
    # Return list of {date, body, engagement}
```

**Cost awareness:** Each Bright Data scrape costs $0.005-0.015 depending on plan. For 5 inspirations × 10 champions × daily generation = 50 scrapes/day = $0.75/day. Reasonable for production but should be cached.

**Caching rule:** Cache the inspiration scrape for 24 hours. The same inspiration doesn't post 50 times a day — checking once daily is enough.

```
cache_key = f"inspiration_activity:{inspiration_handle}:{date_today}"
cache_dir = ".claude/social-amplifier/inspiration-cache/"
```

If the cache file exists and is < 24h old, use it. Otherwise fetch fresh.

## Approach 3: X / Twitter Scrape (When Inspiration Is Twitter-Only)

Some inspirations (Pieter Levels, Naval Ravikant) post primarily on X, not LinkedIn. For these:

```
mcp__brightdata__scrape_as_markdown(
  url="https://x.com/{inspiration_handle}"
)
```

Parse the timeline for tweets in the last 7 days. X timelines are noisier than LinkedIn (more replies, retweets, threading) so filter heavily:

- Drop retweets without commentary
- Drop replies that don't standalone
- Drop tweets under 50 chars (unless they have engagement)
- Keep original tweets and threads

## Step-by-Step Process

### Step 1: Load champion inspirations
```
read champions/{id}/inspirations.md → list of inspiration objects
```

### Step 2: Try OctoLens batch query
```
all_recent = mcp__octolens__list_mentions(filters={startDate: 7_days_ago}, limit=100)
matched_by_author = group_by_author(all_recent, inspiration_handles)
```

### Step 3: For inspirations not in OctoLens, scrape
```
for inspiration in inspirations:
    if inspiration.handle not in matched_by_author:
        if cached_today(inspiration.handle):
            posts = read_cache(inspiration.handle)
        else:
            scrape = mcp__brightdata__scrape_as_markdown(inspiration.linkedin_url)
            posts = extract_recent_posts(scrape, days=7)
            write_cache(inspiration.handle, posts)
        matched_by_author[inspiration.handle] = posts
```

### Step 4: Analyze each inspiration's recent activity

For each inspiration with posts in the last 7 days, extract:

```yaml
inspiration_name: "Aakash Gupta"
handle: "@aakashgupta"
recent_posts_count: 4
top_topics_this_week:
  - "Anthropic ship button kills vibe coding (3 posts)"
  - "Product strategy at AI startups (1 post)"
sample_hooks:
  - "Anthropic is about to mass-extinction event the entire vibe coding category"
  - "If you're building in this space, the next 90 days matter more than the last 12 months"
last_post_age_hours: 6
engagement_signal: high
```

### Step 5: Score inspiration relevance

For each inspiration, score how relevant their recent activity is to the champion's topics:

```python
def score_inspiration_relevance(inspiration_posts, champion_topics):
    relevance_score = 0
    for post in inspiration_posts:
        topic_match = compute_topic_overlap(post.body, champion_topics)
        recency_factor = 1 - (post.age_hours / 168)  # decay over week
        relevance_score += topic_match * recency_factor
    return min(relevance_score, 10)
```

Sort inspirations by score. The top 1-2 become input for Phase 4 (write content) — their hooks and angles inform the variations.

## Output Format

```yaml
inspiration_activity:
  status: ok | partial | empty
  inspirations_checked: 5
  inspirations_with_recent_activity: 3
  total_recent_posts: 12
  sources_used:
    octolens: 2
    bright_data_scraped: 1
    bright_data_cached: 0
  
  active_inspirations:
    - rank: 1
      name: "Aakash Gupta"
      handle: "@aakashgupta"
      relevance_score: 9
      recent_posts:
        - timestamp: "2026-04-13T04:00:00Z"
          age_hours: 6
          body_excerpt: "Anthropic is about to mass-extinction event..."
          engagement: high
          topics: ["AI startup landscape", "vibe coding category"]
        - timestamp: "2026-04-12T15:00:00Z"
          age_hours: 19
          body_excerpt: "Lovable raised $25M. Bolt raised $100M+..."
          engagement: high
          topics: ["AI funding", "vibe coding"]
      summary: "Aakash is dominating the 'Anthropic killing vibe coding' narrative this week"
      suggested_response_angle: "As someone building at one of those startups, here's what the narrative misses..."
    
    - rank: 2
      name: "Jack Clark"
      handle: "@jackclarkSF"
      relevance_score: 7
      ...
  
  inactive_inspirations:
    - name: "Mike Krieger"
      reason: "No posts in last 7 days"
    - name: "Karina Nguyen"
      reason: "Posts in OctoLens but topics don't match champion's areas"
```

This output feeds Phase 4 — the writer can use `suggested_response_angle` directly when generating the inspiration-echo variation.

## Special Cases

### When all inspirations are inactive

If no inspirations have posted in the last 7 days, return:

```yaml
inspiration_activity:
  status: empty
  inspirations_checked: 5
  inspirations_with_recent_activity: 0
  message: "No inspirations have posted recently. Phase 4 will skip the inspiration-echo angle."
```

The waterfall continues — Phase 4 generates 2 variations instead of 3, dropping the inspiration-echo angle.

### When the champion has no inspirations configured

Skip the entire phase:

```yaml
inspiration_activity:
  status: skipped
  reason: "Champion has no inspirations.md or it's empty"
  recommendation: "Operator should run /match-inspirations to enrich profile"
```

### When OctoLens is unavailable

Fall back to Bright Data for all inspirations. Log the source change:

```yaml
sources_used:
  octolens: 0  # mcp unavailable
  bright_data_scraped: 5  # all fetched fresh
```

This is slower but functional. The waterfall continues normally.

### When Bright Data is rate-limited

Use cached results from earlier in the day if available. If no cache exists, fall back to OctoLens-only data even if it's incomplete. Log "partial coverage" in the output.

## Performance

- OctoLens batch query: ~5s
- Bright Data scrape per inspiration: ~5-10s (cached: instant)
- Analysis and scoring: ~2s

Total for Phase 2:
- Best case (all cached): ~2 seconds
- Average case (mix of cache + 1-2 fresh scrapes): ~10 seconds
- Worst case (OctoLens down, 5 fresh scrapes): ~50 seconds

## Cache Management

The inspiration cache lives at:

```
.claude/social-amplifier/inspiration-cache/{handle}-{YYYY-MM-DD}.json
```

Cache structure:

```json
{
  "handle": "@aakashgupta",
  "cached_at": "2026-04-13T08:00:00Z",
  "valid_until": "2026-04-14T08:00:00Z",
  "source": "bright_data",
  "posts": [
    {
      "url": "https://...",
      "timestamp": "2026-04-13T04:00:00Z",
      "body": "Full post text",
      "engagement": {"reactions": 650, "comments": 42}
    }
  ]
}
```

Cache is per-day per-inspiration. Multiple champions sharing inspirations all read from the same cache, so checking 5 champions with the same inspiration only costs 1 scrape.

## Integration With discover-subjects

The discover-subjects skill ALSO checks inspiration activity in its 5-factor scoring (Factor 4: inspiration resonance). To avoid double-fetching, generate-content should:

1. If discover-subjects already ran in this generation flow, reuse its inspiration data
2. If running standalone, do the full inspiration check

The waterfall typically chains discover-subjects → generate-content, so Phase 2 here usually reuses cached results from discover-subjects' analysis. This is why the per-day cache is critical.
