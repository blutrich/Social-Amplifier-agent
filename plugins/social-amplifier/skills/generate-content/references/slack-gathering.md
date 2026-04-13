# Slack Gathering (Phase 1 of the Generate-Content Waterfall)

How to mine Slack for fresh, champion-relevant context BEFORE writing any content. The Slack signals discovered here become the grounding for variations in Phase 4.

## Why Slack First

The champion's voice is rooted in what they actually work on. Slack is where the work lives. Three things Slack gives you that no external source can:

1. **Internal feature signals** — what shipped this week, what's about to ship, what's blocked
2. **Champion's own voice in the wild** — what they actually said in threads, how they talk to their team
3. **Implicit topic signals** — what they share, who they tag, what channels they're active in

OctoLens gives you the external signal. Slack gives you the internal signal. The waterfall combines both.

## Required Tool

Slack MCP must be connected. Verify with:

```
mcp__plugin_slack_slack__slack_read_user_profile()
```

If unavailable, skip this phase entirely. The waterfall continues without Slack signals — Phase 4 (write content) will just have less internal context to ground variations in.

## Step 1: Resolve Champion's Slack User ID

The champion's `profile.json` should already have `slack_user_id`. If missing, look up:

```
mcp__plugin_slack_slack__slack_search_users(query="{champion_name}")
```

Pick the matching user. Save the `slack_user_id` back to profile.json for next time.

## Step 2: Search The Champion's Recent Messages

Pull the champion's last 20-50 substantive messages across all accessible channels. This shows what they've been thinking about and discussing in the last few days:

```
mcp__plugin_slack_slack__slack_search_public_and_private(
  query="from:@{champion_username}",
  limit=20,
  sort="timestamp"
)
```

Filter the results:
- Drop pure links with no commentary
- Drop bot output (Auto-Waterfall, scan reports, etc.)
- Drop one-word acknowledgments ("ok", "thanks", "👍")
- Keep messages over 20 words
- Keep messages where they explained or argued for something
- Keep messages where they shared an article + their take

Output: 5-15 substantive recent messages from the champion. These reveal what they're thinking about right now.

## Step 3: Scan Feature Announcement Channels

Read the channels where new features get announced:

```
# The features intel digest channel (synthesized daily)
mcp__plugin_slack_slack__slack_read_channel(
  channel_id="C0AKHFFRS1Y",  # features-intel-changelog-4marketing
  limit=10
)

# The product marketing sync (raw discussions)
mcp__plugin_slack_slack__slack_search_channels(query="product-marketing-sync")
# Then read the matched channel ID
```

For each message:
- Filter to messages from the last 48-72 hours
- Filter to messages mentioning a specific feature, ship, or milestone
- Note the feature name, owner, status, and key details

These become candidate "shipped feature" subjects for the champion to write about.

## Step 4: Find Feat-* Channels Matching Champion Topics

The champion's profile.json has a `topics[]` array. Find feature channels matching those topics:

```
mcp__plugin_slack_slack__slack_search_channels(query="feat-{topic_keyword}")
```

For each matched channel, read the most recent activity:

```
mcp__plugin_slack_slack__slack_read_channel(channel_id="{matched_channel_id}", limit=15)
```

This catches feature work the champion might not have seen yet but is in their topic area. Especially useful for marketing/comms champions who don't read every feat-* channel themselves.

## Step 5: Filter and Score Slack Signals

You now have raw Slack data from 4 sources. Filter and score:

### Filter A: Substance check
- Body length > 30 characters
- Contains a verb (not just a link or emoji)
- Not a bot message (check author against known bot IDs)
- Not a duplicate of a signal from another channel (e.g., the same feature mentioned in #features-intel and #feat-X)

### Filter B: Recency
- Default: last 48 hours
- Extended: last 7 days if no signals in the primary window

### Filter C: Topic relevance
- Champion has topics like "AI agent infrastructure" → keep messages mentioning agents, MCP, runtimes, infrastructure
- Champion has topics like "Base44 product" → keep messages mentioning new features, ships, milestones

### Score (1-10)

| Factor | Weight | Notes |
|--------|--------|-------|
| Recency | 3 | Fresh > stale |
| Champion involvement | 4 | Did the champion participate in the thread? Highest signal. |
| Specificity | 2 | Specific feature/number > vague discussion |
| Cross-source confirmation | 1 | Mentioned in multiple channels = stronger signal |

Sort signals by score. Keep top 5-10 for Phase 4.

## Step 6: Output Format

Return a structured list of Slack signals:

```yaml
slack_signals:
  - signal_type: feature_ship | thread_discussion | champion_message | shared_link
    source_channel: "#feat-credits-rollover"
    permalink: "https://base44workspace.slack.com/archives/..."
    timestamp: "2026-04-12T18:30:00+03:00"
    age_hours: 18
    score: 8
    body_excerpt: "First 200 chars of the message"
    why_relevant: "Champion is in this channel and topic matches 'AI agent infrastructure'"
    champion_involved: true | false
    related_topics: ["AI agent infrastructure", "Base44 product"]
```

The `body_excerpt` keeps the first 200 chars so Phase 4 can quote it directly without re-fetching.

The `permalink` lets the operator click through to verify the source if they want.

## Examples

### Signal type: Feature ship
```
{
  signal_type: "feature_ship",
  source_channel: "#features-intel-changelog-4marketing",
  body_excerpt: "🚀 SHIPS TOMORROW — Apr 13: Base44 New Look — Liron Monitz, Base44 Workflow — Rotem Eisenkot, Manage Apps v2 — Raphael",
  age_hours: 18,
  score: 9,
  why_relevant: "3 features ship tomorrow, no marketing content yet, champion is in marketing"
}
```

### Signal type: Champion's own message
```
{
  signal_type: "champion_message",
  source_channel: "#mkt-agent-launch",
  body_excerpt: "I tried to make it easy to our busy heads.. created for us some personal social posts and comment on the company posts",
  age_hours: 6,
  score: 10,
  why_relevant: "Champion explicitly described work that could become a LinkedIn post about their own process",
  champion_involved: true
}
```

### Signal type: Shared link
```
{
  signal_type: "shared_link",
  source_channel: "DM with Maor Shlomo",
  body_excerpt: "https://www.linkedin.com/posts/maor-shlomo-1088b4144_were-launching-base44-superagents-today-...",
  age_hours: 36,
  score: 7,
  why_relevant: "Champion shared Maor's launch post — could write a follow-up reflection"
}
```

## When To Skip This Phase

- Slack MCP is unavailable → skip with log "slack_mcp_unavailable, continuing without Slack signals"
- Champion has zero Slack activity in the last 7 days → skip with log "no recent Slack activity for this champion"
- All channel reads return empty → skip with log "all feature channels empty, no shipped signals to ground in"

When skipping, the waterfall continues to Phase 2 (inspirations). Variations in Phase 4 will be grounded in inspiration activity + champion's tone, but lose the specific feature/internal context.

## Performance

- Step 1 (resolve user): instant if cached, ~1s if lookup needed
- Step 2 (champion messages): ~3-5s for one search call
- Step 3 (feature channels): ~5-10s for 2-3 channel reads
- Step 4 (feat-* matching): ~5-15s depending on number of matched channels
- Filter and score: ~1s

Total for Phase 1: 15-30 seconds. The bottleneck is `slack_read_channel` calls, which are not parallelizable.

## Cost Awareness

Each Slack MCP call counts against the user's Slack rate limit. The current setup uses ~5-8 Slack calls per champion per generation. At 10 champions × 5 generations/week = 250-400 Slack calls/week. Well within free-tier limits.

If you need to reduce calls (e.g., during a high-volume launch), drop Step 4 (feat-* scanning) first — it's the most expensive and has the lowest hit rate.
