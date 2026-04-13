# Slack MCP Usage Guide for Delivery

How to actually send messages to champions via the Slack MCP. This is the plumbing reference — the DM content comes from `dm-templates.md`, this file explains how to get that content into the champion's inbox.

## Prerequisites

The Slack MCP must be connected. Verify with:

```
mcp__plugin_slack_slack__slack_read_user_profile()
```

If this returns a profile, Slack MCP is connected. If it errors, stop and tell the operator to connect Slack in Cowork/Claude Code settings. Never fall back silently to "just save the drafts locally" — that defeats the whole push-delivery model.

## Resolving Champion to a DM Channel

The Slack MCP doesn't have an "open DM with user X" tool directly. Instead, you send a message to a user ID and Slack routes it to the existing DM channel (or creates one). The key is getting the right `channel_id` to pass to `slack_send_message`.

### Approach 1: Use the user ID directly

```
mcp__plugin_slack_slack__slack_send_message(
  channel_id="{slack_user_id}",
  text="{message content}"
)
```

Slack's `conversations.open` API accepts a user ID in the channel field and opens a DM. The Slack MCP passes this through. This is the cleanest approach.

### Approach 2: Look up existing DM channel ID

Check existing DMs the agent has with the champion. The Slack MCP's search can find them:

```
mcp__plugin_slack_slack__slack_search_public_and_private(
  query="in:@{username}",
  channel_types="im",
  limit=1
)
```

The first result's `channel_id` (format `D0XXXXX`) is the existing DM channel. Use that for future messages — it keeps all deliveries in the same thread.

**Prefer Approach 2 for ongoing delivery.** It keeps the DM history clean and lets the champion scroll through past drafts.

## Sending the Message

Use `slack_send_message` with the DM channel ID and the formatted text from `dm-templates.md`:

```
mcp__plugin_slack_slack__slack_send_message(
  channel_id="{dm_channel_id}",
  text="{full formatted template text}",
  markdown=true
)
```

Slack MCP supports markdown formatting — specifically, `*bold*`, line breaks, and bullet points. Test that `*text*` renders as bold in Slack, not as literal asterisks.

## Timing and Scheduling

For daily delivery, use `slack_schedule_message` instead of `slack_send_message`:

```
mcp__plugin_slack_slack__slack_schedule_message(
  channel_id="{dm_channel_id}",
  text="{formatted content}",
  post_at={unix_timestamp_for_delivery}
)
```

Compute `post_at` from the champion's timezone (stored in `profile.json`). Default delivery: 9am in the champion's local timezone.

**Example:** Dor is `Asia/Jerusalem`. If it's 3am UTC when the scheduled pipeline runs, schedule his DM for 6am UTC (9am Jerusalem). Use `datetime.now(pytz.timezone('Asia/Jerusalem'))` or equivalent to compute the right timestamp.

**Fallback for immediate delivery:** If the champion's timezone is unknown or the schedule would be more than 24h out, send immediately via `slack_send_message`.

## Handling Send Failures

`slack_send_message` can fail for these reasons:

- **Invalid channel_id:** User doesn't exist or bot doesn't have permission to DM them
- **Rate limiting:** Too many messages in a short window (rare at our volume)
- **Message too long:** Slack has ~40k character limit; drafts should be nowhere near this
- **Slack API down:** Rare but possible

Handling:

1. Catch the error from the MCP call
2. Log it to `.claude/social-amplifier/delivery-failures.log` with timestamp + champion_id + error
3. Don't retry immediately — wait for the next scheduled run
4. If the same champion fails 3 days in a row, flag to the operator

## Parsing Replies

When a champion replies to a DM, the agent needs to read the reply. Slack MCP gives you two tools for this:

### Polling approach (simple)
Periodically check for new messages in the DM channel:

```
mcp__plugin_slack_slack__slack_read_channel(
  channel_id="{dm_channel_id}",
  limit=10
)
```

Look for messages from the champion (not from the agent/bot) that are newer than the last delivered draft. Parse them through `reply-parsing.md` rules.

### Search approach (more reliable)
Search for recent replies from the champion in the DM channel:

```
mcp__plugin_slack_slack__slack_search_public_and_private(
  query="from:@{champion_username} in:@{agent_dm}",
  sort="timestamp",
  sort_dir="desc",
  limit=5
)
```

This returns the champion's most recent replies. Process them with `reply-parsing.md`.

## Delivery Logging

Every send should log to `champions/{champion_id}/content-history/{date}.md` with:

```markdown
---
date: 2026-04-13
delivered_at: 2026-04-13T09:00:00+03:00
dm_channel: D0XXXXX
template: daily-digest
variations_delivered: 3
message_ts: 1776055326.645449
---

# Draft 1: Personal experience angle
{full text}

# Draft 2: Industry insight angle
{full text}

# Draft 3: Product/feature angle
{full text}

# Voice Guardian scores
- Draft 1: 9/10 (APPROVED)
- Draft 2: 9/10 (APPROVED)
- Draft 3: 8/10 (REWRITE applied)

# Reply status
(Populated by reply parser when champion responds)
```

This log is the source of truth for what got delivered when, and it feeds the feedback loop when the champion replies.

## Rate Limit Considerations

Slack's rate limit for bot messages is generous (~1 message/second per channel). At realistic volumes (10-30 champions, 1 delivery/day), we'll never hit it.

One thing to watch: if the scheduled pipeline fails mid-batch and retries, you could send duplicate messages. Always check the delivery log before sending to avoid duplicates. Specifically, if a delivery for `{champion_id}` + `{YYYY-MM-DD}` already exists with a `message_ts`, skip re-sending.

## Testing Without Real Delivery

For testing or dry-runs, the skill supports a `--dry-run` mode. Instead of calling `slack_send_message`, it:

1. Writes the formatted message to `{champion_id}/content-history/DRYRUN-{date}.md`
2. Logs the intended action
3. Returns without calling Slack

This lets you test the template formatting, variable substitution, and delivery log format without spamming real champions during development.
