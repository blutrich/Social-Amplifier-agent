# DM Message Templates

The actual text formats used when sending draft posts to champions via Slack DM. These templates are what champions see in their Slack inbox every morning. The quality of these messages determines whether the champion engages with the draft or ignores it.

## Design Principles

1. **Under 1 screen on mobile** — Champions read these on phones. If they have to scroll, they won't.
2. **Content first, meta second** — The actual post goes at the top. Instructions, context, and formatting notes go at the bottom if at all.
3. **No friction to post** — The champion should be able to triple-click-copy each draft without any markdown or formatting getting in the way.
4. **One reply = one action** — Champions reply with a single number or phrase. Don't ask compound questions.
5. **Silence is acceptance** — If a champion doesn't reply, that's fine. Don't nag or escalate.

---

## Template 1: Daily Digest (2-3 Variations)

Used for the standard morning delivery when multiple content angles were generated. Most common template.

```
Good morning {first_name}! Here are today's {variation_count} drafts:

*Option 1 — {angle_label_1}*

{variation_1_text_with_no_markdown}

---

*Option 2 — {angle_label_2}*

{variation_2_text_with_no_markdown}

---

*Option 3 — {angle_label_3}*

{variation_3_text_with_no_markdown}

---

Reply *1*, *2*, or *3* to mark one as posted (I'll save it to your history).

Reply *"not my style"* + feedback to help me learn your voice — I'll update your profile and try again tomorrow.

Or just copy whichever you like and post it. Silence is fine too.
```

**Variables:**
- `{variation_count}` is `2` or `3` based on how many the Voice Guardian approved
- `{angle_label_1/2/3}` comes from the content-specialist's output per variation. Common labels: "Personal experience angle", "Industry insight angle", "Product/feature angle", "Voice Guardian technical angle", "Hot take", "Behind-the-scenes", "Customer story". Use whatever label the content-specialist tagged each variation with — do NOT hardcode defaults.
- If only 2 variations approved, drop the third block entirely (don't leave an empty Option 3).

**Slack formatting notes:**
- `*text*` is bold in Slack
- Triple-dash separators (`---`) create visual breaks
- No code blocks around the drafts (so triple-click-copy works cleanly)
- Each draft is in its own paragraph, separated by blank lines

**Length:** ~8 lines + 3 drafts. Fits on one mobile screen even with 200-word drafts.

---

## Template 2: Single Draft (Reply to Feedback)

Used when the champion rejected a previous batch and asked for a retry, or when we only have one strong angle to pitch.

```
{first_name}, here's a revised draft based on your feedback:

{draft_text}

What changed from last time: {one-line-summary-of-fix}

Post, reject, or give me more feedback. No hurry.
```

**When to use:**
- Champion said "too formal" on yesterday's batch → regenerate with casual preference applied
- Champion approved Option 2 from a batch but wants a variation → generate one more
- Voice Guardian auto-rewrite produced a cleaner version after initial delivery

**What not to include:**
- Don't say "I hope this is better!" (fake vulnerability, also pushy)
- Don't explain the full feedback loop mechanics
- Don't restate the old draft for comparison

---

## Template 3: Zero-Touch Welcome (First Delivery)

Used the first time a champion receives a DM from the agent. This is the onboarding confirmation.

```
Hey {first_name}! I'm the Social Amplifier. {operator_name} set me up to draft LinkedIn and X posts for you, based on what's trending in your space + real Base44 mentions.

I analyzed your Slack activity to figure out your voice. Here's what I picked up:

{3 bullet points from style-preferences.md — concrete patterns, not labels}

Your first drafts are ready:

{either Template 1 or Template 2 content follows}

---

Quick notes:
• I'll send new drafts every {frequency, e.g., "weekday morning"}
• Reply anytime with feedback and I'll adjust
• Reply *"pause"* to stop for a week, *"stop"* to opt out entirely
```

**When to use:**
- First DM ever to a champion
- Operator just ran `/new-champion` and this is the onboarding confirmation + first content

**What the 3 bullet points should look like (good):**
- Uses em dashes and TL;DR format in Slack briefs
- Opens technical messages with "Hey [name] —"
- Names specific collaborators and shows the math

**What they should NOT look like (bad):**
- Medium vocabulary register
- Measured energy level  
- Occasional humor

The first version is concrete and shows the agent actually read the champion's writing. The second version is labels that could apply to anyone. Always use the first version.

---

## Template 4: Voice Profile Update Confirmation

Used when feedback has caused a profile update, to acknowledge the correction.

```
Got it — updated your voice profile:

{1-2 line description of what changed}

Your next drafts will reflect this. Keep the feedback coming whenever something's off.
```

**When to use:**
- Champion replied "too formal" → feedback skill updated `formality: casual`
- Champion said "I don't use that word" → added to `banned_words_add`
- Champion rewrote a draft manually → analyzed the diff and updated style-preferences.md

**Keep it short.** This is an acknowledgment, not a sermon. The champion doesn't care about the internal mechanics.

---

## Template 5: Pause / Resume Confirmation

Used when the champion opts out temporarily.

### Pause
```
Paused for a week. I'll start sending drafts again on {date}. Reply *"resume"* anytime to restart earlier.
```

### Resume
```
Welcome back {first_name}. Here are this morning's drafts:

{Template 1 or 2 content}
```

### Stop
```
Stopped. Your profile is preserved but no more drafts. Reply *"start"* anytime if you want to come back — I'll use your existing voice profile, no re-onboarding.
```

---

## Template 6: Scheduled Trigger Failure / Apology

Used rarely — when the scheduled pipeline failed for a specific champion and they didn't get their morning batch.

```
{first_name}, no drafts this morning — the content pipeline hit an error while generating for you. I'll try again in a few hours. No action needed from you.
```

**Don't include technical details.** Champions don't care that OctoLens timed out or that Voice Guardian rejected everything. Just acknowledge and move on.

---

## Formatting Rules for All Templates

### Use
- `*bold*` for emphasis (one or two words per message max)
- Blank lines between paragraphs (Slack collapses consecutive text without them)
- `---` for visual separators between drafts
- `•` for bullet points (not `-` or `*` — they look uglier in Slack)
- Mobile-safe line breaks

### Don't Use
- Markdown headers (`#`, `##`) — they look weird in Slack
- Code blocks for drafts — they break copy-paste workflow
- Emojis in the agent's own messaging (except maybe 👋 in the welcome, maximum one)
- Threaded replies — stay in the main DM channel
- Links in the draft body (save those for the agent's own notes in Template 4)

### Variables

All templates use these variables, populated at send time:

- `{first_name}` — from `champions/{id}/profile.json`.name, first word only
- `{operator_name}` — who ran `/new-champion` for this person
- `{variation_count}` — integer, 2 or 3, based on approved drafts
- `{variation_1_text}`, `{variation_2_text}`, `{variation_3_text}` — clean post text from generate-content, no markdown
- `{angle_label_1}`, `{angle_label_2}`, `{angle_label_3}` — human-readable angle label per variation (from content-specialist output, never hardcoded)
- `{frequency}` — human-readable delivery cadence from operator config
- `{date}` — human-readable resume date for pause messages
