---
name: deliver-content
description: |
  Delivers generated draft posts to a champion via Slack DM. Handles daily digest delivery, welcome flows for new champions, feedback-triggered revisions, and pause/resume state. Logs every delivery to the champion's content history for the feedback loop to read.

  Use this skill whenever content has been generated and needs to reach a champion. Also use it when a champion replies to a previous delivery — this skill orchestrates both sending and reply parsing, with the feedback skill updating the profile based on what champions say.
---

# Deliver Content Skill

The last mile of the Social Amplifier pipeline. Content generation and Voice Guardian scoring produce clean, scored drafts. This skill turns those drafts into a Slack DM the champion actually receives, logs the delivery, and parses the reply when it comes.

## When This Skill Runs

- **Scheduled delivery:** The daily/weekly scheduled pipeline generates content for every active champion, then calls this skill to send the batch
- **Onboarding:** Right after `new-champion` completes, deliver the first batch as a welcome DM
- **Manual trigger:** Operator runs `/deliver {champion_id}` to force a one-off delivery
- **Revision:** Feedback skill asks for a retry after a rejection, this skill delivers the revised draft
- **Reply processing:** When a champion replies to a previous DM, this skill parses the reply and routes to the right follow-up action

## Core Principle

**Silence is acceptance.** The default state is that champions read the DM, copy whatever draft they like, and post it without telling anyone. The agent doesn't nag, doesn't ask for confirmation, doesn't escalate. Every delivery assumes the champion is a busy adult who will engage when they want to.

The product is a butler, not an assistant. Set down the tray, step back, say nothing.

## Process

### Step 1: Validate Inputs

Before attempting to deliver, check:

- `champion_id` exists as a directory in `plugins/social-amplifier/champions/`
- `profile.json` has `status: active` (not `paused`, `archived`, or missing)
- `profile.json` has a valid `slack_user_id` or `dm_channel`
- The content to deliver has passed Voice Guardian with at least one draft scoring 9+/10 (drafts below 7 should have been rejected upstream)
- The current date is a valid delivery day (not weekend-only if the champion opted out of weekends)

If any check fails, log the reason and stop. Don't attempt partial delivery.

### Step 2: Resolve the DM Channel

Read `references/slack-mcp-guide.md` for the exact approach. In short:

1. If the champion's `profile.json` has a cached `dm_channel_id`, use it
2. Otherwise, look up the existing DM via `slack_search_public_and_private` with `in:@{username}` filter
3. If no existing DM exists (first contact), use the champion's `slack_user_id` directly — Slack will route or create the DM channel
4. Cache the resolved channel ID back to `profile.json` for future deliveries

### Step 3: Pick the Right Template

Determine which template from `references/dm-templates.md` to use:

- **Template 3 (Welcome):** First delivery for this champion (no prior content history files exist)
- **Template 2 (Single Draft):** Only one variation to deliver (e.g., feedback-driven revision)
- **Template 1 (Daily Digest):** Standard case, 2-3 variations available
- **Template 4 (Profile Update):** After feedback skill updated the profile, acknowledging the change
- **Template 5 (Pause/Resume):** State change confirmation
- **Template 6 (Apology):** Pipeline failure acknowledgment

The template choice is determined by the caller's intent, not by this skill alone. The scheduled pipeline defaults to Template 1. The onboarding flow uses Template 3. The feedback handler uses Template 2 or 4.

### Step 4: Populate the Template

Load the chosen template from `references/dm-templates.md`. Substitute variables:

- `{first_name}` from profile.json
- `{operator_name}` from whoever triggered the delivery
- Draft texts from the Voice Guardian output (use the APPROVED version, not the pre-rewrite)
- Delivery cadence and dates from operator config

Test the substituted message for:

- No unfilled placeholders (`{variable_name}` visible in the final text)
- No markdown that would break Slack rendering
- No embedded links in the draft texts unless explicitly wanted
- Total character count under 40k (Slack hard limit, we'll be nowhere near this)

### Step 5: Send via Slack MCP

Read `references/slack-mcp-guide.md` for send mechanics. Use `slack_send_message` for immediate delivery or `slack_schedule_message` for delayed delivery to hit the champion's 9am local time.

Catch errors. Log failures to `.claude/social-amplifier/delivery-failures.log`. Do not retry immediately — wait for the next scheduled run.

### Step 6: Write the Delivery Log

Create or append to `plugins/social-amplifier/champions/{champion_id}/content-history/{YYYY-MM-DD}-{topic-slug}.md` using the schema in `references/delivery-log-schema.md`.

The minimum required fields at send time:

- `champion_id`, `date`, `delivered_at`, `delivery_status`, `message_ts`
- All draft texts
- `# Reply` section left empty (filled when the champion replies)

### Step 7: Handle Reply (If Applicable)

If this skill was invoked to process a reply rather than send a new delivery:

1. Read the champion's latest reply from the DM channel
2. Find the most recent delivery log entry in `content-history/`
3. Parse the reply using `references/reply-parsing.md` rules
4. Based on category:
   - **Approval:** Update the log's `chosen` field, log the positive signal, optionally send Template 4
   - **Rejection/feedback:** Route to `feedback` skill with the extracted feedback, then send Template 4 or Template 2 (revision)
   - **Rewrite:** Diff the champion's rewrite against the originals, extract patterns, route to feedback skill
   - **Pause/stop:** Update `profile.json.status`, send Template 5
   - **Question:** Answer briefly, don't treat as voice feedback
   - **Silence:** Do nothing, log `reply_status: none` at the next delivery window

## Reference Files

This skill loads references on demand, not all at once:

| File | When to Read | Purpose |
|------|-------------|---------|
| `references/dm-templates.md` | Every delivery (for template text) | The 6 DM templates with variable placeholders |
| `references/slack-mcp-guide.md` | Every delivery (for MCP calls) | How to resolve DM channels, send messages, handle failures |
| `references/reply-parsing.md` | Only when processing a reply | How to categorize and extract feedback from champion replies |
| `references/delivery-log-schema.md` | Every delivery (for logging) | The content-history file format and required fields |

Start with the two always-needed references (`dm-templates.md`, `slack-mcp-guide.md`, `delivery-log-schema.md`). Only load `reply-parsing.md` if you're in reply-processing mode.

## Integration With Other Skills

- **Called by:** 
  - `scheduled-pipeline` skill (future) for daily deliveries
  - `new-champion` skill immediately after onboarding
  - `generate-content` skill when delivery is requested inline
  - Operator via `/deliver {champion_id}` command (future)
- **Calls:**
  - Slack MCP tools (`slack_send_message`, `slack_schedule_message`, `slack_read_channel`, `slack_search_public_and_private`)
  - `feedback` skill when champion replies with feedback
  - `generate-content` skill when champion requests a retry with a different angle
- **Reads:**
  - Champion profile files (`profile.json`, `tone-of-voice.md`, `style-preferences.md`)
  - Voice Guardian output from upstream
  - Existing delivery logs for dedup + context
- **Writes:**
  - New delivery logs in `content-history/`
  - Cached `dm_channel_id` back to `profile.json`
  - Delivery failure logs to `.claude/social-amplifier/delivery-failures.log`

## Dry Run Mode

For testing without spamming real champions, support a `--dry-run` parameter:

```
/deliver dor-blech --dry-run
```

When dry-run is set:

1. Resolve the DM channel as normal (validates Slack MCP works)
2. Format the message using the chosen template
3. Write the formatted message to `content-history/DRYRUN-{date}.md` instead of sending
4. Log the intended action to `.claude/social-amplifier/dry-run.log`
5. Return without calling `slack_send_message`

Use this during development and to verify templates before a real delivery.

## Trust Rules

A few things this skill explicitly does NOT do, because they break champion trust:

1. **Doesn't send drafts without Voice Guardian approval.** If no variation scored 9+/10, don't deliver anything — send Template 6 (apology) or just skip the day silently.
2. **Doesn't ask champions to "please confirm receipt".** Silence is acceptance.
3. **Doesn't DM outside the champion's local business hours.** Respect timezones.
4. **Doesn't retry failed sends immediately.** Wait for the next scheduled run.
5. **Doesn't send the same content twice.** Check `message_ts` in existing logs before sending.
6. **Doesn't escalate to the operator on champion rejection.** Rejections are normal. Update the profile and move on.
7. **Doesn't include internal metrics in champion-facing messages.** They don't care about Voice Guardian scores or rewrite counts.

## Output

On success:

```
Delivered to {champion_id}.
Channel: {dm_channel_id}
Template: {template_name}
Variations: {N}
Voice Guardian scores: {[scores]}
Message timestamp: {ts}
Log: plugins/social-amplifier/champions/{champion_id}/content-history/{filename}
```

On failure:

```
Delivery failed for {champion_id}.
Reason: {error}
Recovery: {retry on next scheduled run | skip permanently | needs operator intervention}
Log: .claude/social-amplifier/delivery-failures.log
```

On dry-run:

```
Dry run complete for {champion_id}.
Template: {template_name}
Would have delivered to: {dm_channel_id}
Message length: {chars}
Intended message saved to: content-history/DRYRUN-{date}.md
```
