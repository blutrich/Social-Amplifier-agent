# Delivery Log Schema

How to structure the content-history entries so the feedback loop, metrics, and retry logic can all read them consistently.

## File Location

Each delivery gets its own file in the champion's content history:

```
plugins/social-amplifier/champions/{champion_id}/content-history/{YYYY-MM-DD}-{topic-slug}.md
```

**Filename rules:**
- Date is delivery date in the champion's local timezone (not UTC)
- Topic slug is kebab-case, max 30 chars, from the primary topic or "daily-digest" if no specific topic
- Multiple deliveries per day use suffix: `2026-04-13-daily-digest-01.md`, `2026-04-13-retry-02.md`

## Full Schema

Every delivery log uses this frontmatter + body structure:

```markdown
---
champion_id: {kebab-case-id}
date: {YYYY-MM-DD}
delivered_at: {ISO 8601 timestamp with timezone}
dm_channel: {D0XXXXXX}
template: {daily-digest | single-draft | welcome | revision | pause | apology}
trigger: {scheduled | manual | retry | onboarding}
trigger_id: {scheduled pipeline run ID or operator user ID}
variations_delivered: {1 | 2 | 3}
topic: {primary topic of the batch}
topic_source: {octolens | slack | trend | manual}
voice_guardian_scores: [{score1}, {score2}, {score3}]
delivery_status: {sent | failed | dry-run}
message_ts: {Slack message timestamp if sent}
failure_reason: {if delivery_status is failed}
---

# Draft 1: {angle_type}
**Voice Guardian score:** {N}/10 ({APPROVED | REWRITE | REJECT})
**Rewrite count:** {0 | 1 | 2}

{full draft text}

---

# Draft 2: {angle_type}
**Voice Guardian score:** {N}/10 ({verdict})
**Rewrite count:** {count}

{full draft text}

---

# Draft 3: {angle_type}
**Voice Guardian score:** {N}/10 ({verdict})
**Rewrite count:** {count}

{full draft text}

---

# Source Signal
- OctoLens mention ID: {if triggered by a specific mention}
- OctoLens URL: {url of the source post}
- OctoLens sentiment: {positive | neutral | negative}
- OctoLens tags: {list of tags}
- Generated hook: {which mention led to which draft}

---

# Reply
(Populated when the champion replies. Empty at delivery time.)

- Timestamp: {ISO 8601}
- Raw text: {verbatim quote}
- Category: {approval | rejection | feedback | question | rewrite | silence}
- Chosen variation: {1 | 2 | 3 | none}
- Feedback extracted: {structured feedback items}
- Profile updates: {list of file.field → new_value changes}
- Agent response: {which template was sent in reply, if any}
- Response timestamp: {ISO 8601}

---

# Outcome
(Populated at end of day or when next delivery supersedes.)

- Final status: {approved | rejected | no-response | rewritten | paused}
- Posted URL: {if champion provided the URL after posting, e.g., via a later DM}
- Engagement: {if known, e.g., likes/reactions after champion posts}
- Feedback impact: {summary of how this delivery improved the profile}
```

## Minimum Viable Entry

If you can't populate every field (e.g., source signal is manual, no OctoLens data), use this minimum:

```markdown
---
champion_id: dor-blech
date: 2026-04-13
delivered_at: 2026-04-13T09:00:12+03:00
dm_channel: D0XXXXXX
template: daily-digest
trigger: scheduled
variations_delivered: 3
delivery_status: sent
message_ts: 1776055326.645449
---

# Draft 1
{text}

# Draft 2
{text}

# Draft 3
{text}

# Reply
(pending)
```

The required fields are: `champion_id`, `date`, `delivered_at`, `delivery_status`, plus the draft texts. Everything else is optional but recommended.

## Reading the Log

### For the feedback skill
Read the most recent file in `content-history/` to get the current delivery state. Check the `# Reply` section — if empty, no reply yet. If populated, use the parsed category + feedback to update the profile.

### For the scheduled pipeline
Before sending, check if a file with the same `champion_id + date + trigger:scheduled` already exists. If yes, skip (dedup protection).

### For the metrics dashboard
Aggregate across all `content-history/` files for a champion to compute:
- Delivery rate (files per day over N days)
- Approval rate (final_status: approved / total)
- Reply rate (files with non-empty Reply / total)
- Average Voice Guardian score across approved drafts
- Most common feedback categories

## Retention

Keep the last 90 days of delivery logs. Older logs are archived to `content-history/archive/{year}/{month}/` as compressed markdown. This keeps the active directory small and easy to read.

For the feedback skill, only the last 30 days are relevant — anything older doesn't influence current profile updates.

## Migration Note

The old generate-content skill wrote to this same location with a simpler format:

```markdown
---
date: YYYY-MM-DD
platform: linkedin
topic: {topic}
chosen: A/B/C
score: {guardian_score}
---

{post content}
```

This format is a subset of the new schema. Old files will be read correctly; new files will be written with the full schema. No migration needed — the new fields are all optional in parsers.
