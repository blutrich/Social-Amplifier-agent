---
name: feedback
description: |
  Automatically captures champion feedback during content generation and updates their voice profile.
  Listens for corrections like "too formal", "I'd never say that", "more like my other posts".
  Updates tone-of-voice.md and rules.md in real-time.

  Triggers on: too formal, too casual, not my style, I'd never say, sounds like AI, more like, less like, wrong tone, fix my voice, update my tone, add inspiration, follow like, write like, inspired by.
  Also activates automatically after any content generation when the user gives feedback.
---

# Champion Feedback Skill

## When This Activates

This skill runs automatically whenever a champion gives feedback on generated content. The content-specialist and voice-guardian should watch for feedback signals after presenting content.

**Feedback signals (any of these trigger an update):**
- Direct corrections: "too formal", "too casual", "I wouldn't say it like that"
- Style preferences: "more like [person]", "less corporate", "shorter sentences"
- Rejections: "this doesn't sound like me", "sounds like AI", "I'd never post this"
- Positive signals: "this is perfect", "yes, more like this", "nailed it"
- Specific edits: when the user rewrites part of the generated content

## Process

### Step 1: Classify the Feedback

Determine what type of feedback was given:

| Type | Examples | What to update |
|------|----------|---------------|
| **Tone correction** | "too formal", "too casual", "more conversational" | tone-of-voice.md → Tone section |
| **Vocabulary preference** | "I don't use that word", "I'd say X instead of Y" | rules.md → add to avoid/prefer lists |
| **Structure preference** | "shorter paragraphs", "I use more lists", "no emojis" | tone-of-voice.md → Structure section |
| **Topic refinement** | "I don't write about that", "add AI ethics to my topics" | profile.json → topics[] |
| **Positive reinforcement** | "this is great", "perfect tone", "more like this" | rules.md → add to "what works" list |
| **Style reference** | "more like [person]", "write like my last post" | tone-of-voice.md → Style References |
| **Inspiration request** | "add Mike Krieger as inspiration", "follow like Harry Dry", "inspired by @pieterlevels", "write like lenny rachitsky" | inspirations.md → add person + trigger match-inspirations skill to pull their content |

### Inspiration Request Sub-Process

When a champion asks for a specific inspiration, run this flow:

1. **Parse the name/handle from the message.** Handle variations: "Mike Krieger", "@mikeyk", "mike krieger from instagram", "the anthropic CPO". Use context clues.

2. **Check banned list first.** Load `plugins/social-amplifier/shared/inspiration-seeds.json` and verify the requested person is NOT in the `banned.people` list and NOT affiliated with any company in `banned.company_patterns`.

   - If banned: reply to champion with a specific refusal. Example: "I can't use Amjad Masad as an inspiration — he's the CEO of Replit, a direct competitor. Want me to suggest some alternatives in the same space?"
   - If on a banned company but might be individually OK (engineer vs CEO), ask the operator via memory marker before adding.

3. **Resolve to a social profile.** If the champion gave a name, use:
   - Bright Data `scrape_as_markdown` on `https://www.linkedin.com/in/{handle}` if they provided a LinkedIn handle
   - OctoLens `list_mentions` with author filter if they gave a general name
   - Google search via WebSearch if nothing else resolves

4. **Analyze the person's content.** Pull 5-10 of their recent posts via Bright Data. Extract voice patterns (sentence length, vocabulary, humor, structure) using the same 8-dimension analysis from `new-champion/references/auto-profile-from-slack.md`.

5. **Add to the champion's inspirations.md.** Use the format documented in `match-inspirations/references/inspirations-schema.md`. Include:
   - Name, handle(s)
   - Voice signature (2-3 sentence summary)
   - 2-3 verbatim sample posts
   - Why the champion requested them (their own words)
   - Date added

6. **Update tone-of-voice.md "Style References" section.** Add a pointer to the new inspiration so the Voice Guardian loads their patterns during scoring.

7. **Confirm to the champion.** Short DM reply:
   > "Added {person_name} as inspiration. Your next drafts will pick up their style patterns — {1-2 specific patterns observed}. Let me know if that shifts the voice in the direction you wanted."

8. **Do NOT regenerate old content.** The new inspiration applies to future generations only. Re-scoring or re-writing past content is noisy and confusing.

### Step 2: Read Current Profile

```
Read(file_path="champions/{champion_id}/tone-of-voice.md")
Read(file_path="champions/{champion_id}/rules.md")
Read(file_path="champions/{champion_id}/profile.json")
```

### Step 3: Apply the Update

**For tone-of-voice.md:**

Find the relevant section and append the learned preference. Use Edit tool with stable anchors.

Example - user said "too formal":
```
Edit(file_path="champions/{champion_id}/tone-of-voice.md",
     old_string="## Tone",
     new_string="## Tone\n- [LEARNED] User prefers more casual/conversational tone. Avoid formal phrasing.\n")
```

Example - user said "this is perfect, more like this":
```
Edit(file_path="champions/{champion_id}/tone-of-voice.md",
     old_string="## What Works",
     new_string="## What Works\n- [LEARNED] The following style was approved: {brief description of what made it good}\n")
```

**For rules.md:**

Append to the appropriate section:

```
Edit(file_path="champions/{champion_id}/rules.md",
     old_string="## Avoid",
     new_string="## Avoid\n- [LEARNED] {specific thing to avoid based on feedback}\n")
```

Or for positive feedback:
```
Edit(file_path="champions/{champion_id}/rules.md",
     old_string="## Do More Of",
     new_string="## Do More Of\n- [LEARNED] {specific thing that worked}\n")
```

**For profile.json topics:**

If the user says "add X to my topics" or "I don't write about Y":
- Read profile.json
- Parse JSON
- Add/remove from topics[]
- Write back

### Step 4: Confirm the Update

Tell the champion what was learned:

> "Got it - I've updated your voice profile:
> - Added to your rules: avoid formal phrasing, keep it conversational
> - This preference will apply to all future posts."

Keep it brief. One or two lines max.

### Step 5: Log to Memory

Append to `.claude/social-amplifier/patterns.md`:

```
Edit(file_path=".claude/social-amplifier/patterns.md",
     old_string="## Champion Feedback",
     new_string="## Champion Feedback\n- [{date}] {champion_id}: {brief feedback summary} → updated {file}\n")
```

## Rules

1. **Never ask permission to update.** When feedback is given, just update and confirm. The whole point is zero friction.
2. **Prefix learned items with [LEARNED]** so they're distinguishable from onboarding-generated content.
3. **Don't overwrite** - always append. The champion's original tone-of-voice stays intact, learned preferences stack on top.
4. **Positive feedback matters as much as negative.** When something works, record it so we do more of it.
5. **Be specific in what you record.** Not "user didn't like it" but "user prefers shorter sentences under 15 words, avoids compound clauses."
6. **After updating, regenerate if asked.** If the user gave feedback on a specific post, offer to regenerate with the new preferences applied.

## Integration with Content Generation

The `generate-content` skill should:

1. After presenting 3 variations, watch for feedback
2. If the user says something negative about the style → trigger this feedback skill
3. If the user picks a variation and says something positive → also trigger this skill
4. If the user manually edits the text → compare their edit to the original to learn preferences

The `voice-guardian` skill should:

1. Read ALL [LEARNED] entries from tone-of-voice.md and rules.md
2. Apply them as additional checklist items during scoring
3. Weight [LEARNED] preferences higher than onboarding-generated ones (direct feedback > inferred style)
