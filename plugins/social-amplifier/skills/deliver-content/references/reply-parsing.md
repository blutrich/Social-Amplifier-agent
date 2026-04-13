# Reply Parsing Rules

How to interpret a champion's reply to a draft delivery. The champion's Slack reply is short, unstructured, and often ambiguous. This reference documents how to turn "1" or "too formal" or "yes, post 2" into a structured action that updates the profile and triggers the next flow.

## Reply Categories

Every reply falls into one of these categories. The first matching rule wins — check them in order.

### 1. Approval-by-number (highest precedence)

The champion says a number (1, 2, or 3) or references it:

**Examples:**
- "1"
- "2"
- "3"
- "option 1"
- "go with 1"
- "I'll post 2"
- "the first one"
- "let's do #3"
- "yep, 1"

**Action:**
1. Log the chosen variation to `content-history/{date}.md` as `chosen: 1|2|3`
2. Mark it as approved (no feedback adjustment)
3. Optionally reply with a brief ack: "Saved. I'll use that style more often."
4. Update `style-preferences.md` "What Works" section with a note about the approved variation's pattern

### 2. Explicit rejection with feedback

The champion says something negative with a reason:

**Examples:**
- "too formal"
- "not my style"
- "this sounds like AI"
- "I'd never say 'leverage'"
- "too corporate"
- "the first two are bad, the third is close"
- "more casual"
- "shorter sentences"

**Action:**
1. Route the feedback to the `feedback` skill
2. Feedback skill updates `style-preferences.md` based on the specific complaint
3. Feedback skill updates `tone-of-voice.md` if the correction is structural
4. Send Template 4 (Voice Profile Update Confirmation) to acknowledge
5. Optionally regenerate with the new preferences applied — but only if the champion asked for a retry. Don't surprise them with new drafts they didn't request.

### 3. Positive feedback without explicit choice

The champion says something nice but doesn't pick a variation:

**Examples:**
- "these are good"
- "nice work"
- "much better than yesterday"
- "love the angle on #3"
- "pretty close"

**Action:**
1. Log as positive signal without marking any specific variation as chosen
2. If a specific variation is praised ("love #3"), treat that as an implicit approval of #3
3. Update "What Works" in the champion's profile
4. No confirmation DM needed — positive feedback doesn't require acknowledgment

### 4. Request for more variations or a different angle

The champion wants retries or a different direction:

**Examples:**
- "try again with a different angle"
- "give me more options"
- "can you make one more focused on the technical side?"
- "same topic but more casual"
- "shorter please"

**Action:**
1. Extract the requested direction from the message
2. Call `generate-content` skill with:
   - Same topic as the original
   - Added constraint from the request (e.g., "technical focus", "casual tone", "under 100 words")
3. Run new variations through Voice Guardian
4. Send Template 2 (Single Draft) with the result — don't send 3 more variations unless explicitly asked

### 5. Pause / Stop / Resume

The champion wants to control delivery:

**Examples:**
- "pause"
- "pause for a week"
- "stop"
- "opt out"
- "resume"
- "start"
- "not now"
- "busy this week"

**Action:**
1. Update `profile.json` status:
   - "pause" → `status: paused`, `paused_until: {7_days_from_now}`
   - "stop" → `status: archived`, delivery never happens until explicit resume
   - "resume" → `status: active`
2. Send Template 5 (Pause/Resume/Stop Confirmation)
3. Don't send any more drafts until status returns to active

### 6. Question or meta-reply

The champion asks a question or comments on the process:

**Examples:**
- "how do I unsubscribe?"
- "can you scan slack for features?"
- "who else is getting these?"
- "what's your training data?"
- "can you do a newsletter too?"

**Action:**
1. Route to a general-purpose response (not the feedback skill)
2. Answer the question briefly in a DM reply
3. Don't treat this as voice feedback — it's operational
4. If the question reveals an unmet need (e.g., "can you do newsletters"), log it as a feature request for the operator

### 7. Manual rewrite (champion posts their own version)

The champion doesn't pick a number and doesn't explicitly reject — they post a modified version of one of the drafts:

**Example reply:**
```
Shipped a new Claude Code plugin today. Social Amplifier reads real mentions from Octolens, matches them to each person, and sends draft posts via Slack. Two months in at Base44. Building tools I actually want to use.
```

(This looks like a rewrite of Draft 1 but shorter and with different phrasing.)

**Action:**
1. Diff the champion's version against each of the 3 original drafts
2. Identify which draft it's closest to (by shared phrases, structure, topic)
3. Extract the differences:
   - Shorter? → update `style-preferences.md` with lower word count preference
   - Different word choices? → add removed words to avoidance list, add added words to "uses naturally" list
   - Different structure? → update tone-of-voice.md structure observation
4. Save the champion's version as `content-history/{date}-chosen-rewritten.md`
5. Reply with Template 4 (profile update confirmation) noting that their rewrite taught the agent something specific

This is the highest-value feedback type because it shows exactly how the champion actually writes, in the specific context of the topic.

### 8. Silence

The champion doesn't reply at all within 24 hours:

**Action:**
1. Don't nag
2. Don't ask for feedback
3. Don't escalate
4. Log as `reply_status: none` in the content history
5. Keep delivering tomorrow's batch on schedule

Silence is the most common reply. Champions are busy. They'll copy a draft and post it without telling the agent, or skip the day entirely. Both are fine. The only thing that breaks the flow is if the agent starts asking "did you see my drafts?" — that's pushy and kills the trust.

## Ambiguity Resolution

When a reply is ambiguous and could fit multiple categories, use these tiebreakers:

- **Number + negative comment** ("1, but it's too long") → Category 2 (feedback), with a note that the champion leaned toward variation 1
- **Number + positive comment** ("yep 1, nice work") → Category 1 (approval) with positive-feedback bonus
- **Hebrew/English code-switch** → parse whichever language the feedback keyword is in; translate with context from `style-preferences.md.uses_hebrew`
- **Message with only a link or image** → Category 8 (silence), don't try to interpret it
- **Multiple replies in quick succession** → wait 60 seconds before processing, then merge them as a single reply

## What the Parser Should NOT Do

- **Don't judge the reply.** If the champion says "this sucks", that's fine. Log it, update, move on. No defensive responses.
- **Don't ask follow-up questions.** The only exception is if the reply is completely unparseable, in which case reply with: "Got it. Want me to try a different angle?"
- **Don't explain why the agent generated what it did.** Champions don't care about the internal mechanics.
- **Don't re-send the drafts the champion already rejected.** That's how you lose trust fast.

## Logging the Parsed Reply

After categorizing and acting on a reply, log the outcome to `content-history/{date}.md`:

```markdown
# Reply
- Timestamp: 2026-04-13T09:34:12+03:00
- Raw text: "1, but make it shorter next time"
- Category: approval-with-feedback
- Chosen variation: 1
- Feedback extracted: "prefer shorter posts"
- Profile updates: style-preferences.md → linkedin.word_count_max reduced from 300 to 220
- Agent response: Template 4 acknowledgment sent at 2026-04-13T09:34:45+03:00
```

This log becomes the training data for future deliveries.
