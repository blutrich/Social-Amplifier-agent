# Champion Style Preferences Schema

Each champion has a `champions/{champion_id}/style-preferences.md` file that documents per-person overrides to the universal rules. This is the key to making the Voice Guardian work for everyone — universal rules are the baseline, but each champion can relax specific structural bans based on their actual writing style.

## Purpose

The universal rules in `universal-ai-tells.md` are correct for MOST people. But every rule has exceptions based on how the champion actually writes:

- **Ofer Blutrich** uses em dashes heavily in his Slack briefs ("Scope — 5 tier-specific LPs"). His posts should ALLOW em dashes.
- **Maor Shlomo** avoids em dashes (Base44 brand voice rule). His posts should BAN em dashes.
- **A developer who writes 12-tweet threads** should have a higher thread limit than the default 7.
- **A founder who uses emojis naturally** should be allowed 3-4 emojis instead of the default 2.

These overrides are learned from real writing samples during onboarding, then refined through feedback ("too formal", "I never use that word").

## File Location

```
plugins/social-amplifier/champions/{champion_id}/style-preferences.md
```

This file is created during onboarding and updated by the `feedback` skill when corrections happen.

## Schema

The file uses structured frontmatter with a markdown body for notes:

```markdown
---
champion_id: dor-blech
updated_at: 2026-04-13
version: 3

# Structural overrides (override universal-ai-tells.md)
em_dashes: deny              # allow | deny
rule_of_three: deny          # allow | deny (very rare to allow)
numbered_lists: allow        # allow | deny
thread_numbering_linkedin: deny  # allow | deny
emoji_max: 2                 # integer, default 2
hashtag_max: 2               # integer, default 2

# Vocabulary overrides
banned_words_add:            # extra words THIS champion never uses
  - "frankly"
  - "quite"
banned_words_remove:         # universal banned words THIS champion is allowed to use
  - "deep dive"              # Dor actually uses "deep dive" naturally

# Tone characteristics (descriptive, not enforced rules)
sentence_length: medium      # short | medium | long | mixed
vocabulary_register: casual  # casual | professional | technical | mixed
energy_level: measured       # high | measured | low
humor_frequency: rare        # frequent | occasional | rare | never
formality: conversational    # formal | conversational | casual | mixed
uses_hebrew: true            # true | false
mixes_languages: true        # true | false (code-switches in writing)

# Platform-specific overrides
linkedin:
  word_count_min: 150        # default 150
  word_count_max: 300        # default 300
  paragraph_style: short     # short | medium | long
  hook_style: story          # story | observation | number | hot-take

x:
  single_tweet_preferred: true   # vs threads
  thread_max: 7              # default 7
  emoji_style: minimal       # minimal | moderate | frequent

---

# Dor Blech Style Notes

## Writing Patterns Observed
- Writes in Hebrew for internal Slack, English for LinkedIn posts
- Uses "you" directly when making a point (not "we" or "one")
- Starts most posts with a specific observation, not a setup
- Ends posts with a clear takeaway, not a question
- Prefers 2-3 sentence paragraphs with white space between

## Phrases to Use
- "I've been thinking about..."
- "Here's what I keep coming back to..."
- "The thing that surprised me..."
- "I spent [specific time] on [specific thing]..."

## Phrases to Avoid
- "I'm excited to announce..." (corporate)
- "Thrilled to share..." (corporate)
- "What do you think?" (engagement bait)
- Any rhetorical questions as post openers

## Real Writing Samples
(Used by Voice Guardian for tone matching)

Sample 1 (from LinkedIn, 2026-03-15):
> [Actual sample from champion's real post]

Sample 2 (from LinkedIn, 2026-02-22):
> [Actual sample]

Sample 3 (from Slack, 2026-04-10):
> [Actual sample, even if informal — shows natural voice]

## Feedback Learnings
- [2026-04-12] Dor said "too formal" on a post about the Reputation Drop. Lesson: drop the "strategic implications" framing, get to the specific numbers faster.
- [2026-04-10] Dor approved a post with "I've been in comms for 12 years" hook. Lesson: personal timeline openers work for him.
```

## How the Voice Guardian Uses This File

When scoring content for a specific champion:

1. Load `universal-ai-tells.md` (the baseline)
2. Load the champion's `style-preferences.md` (the overrides)
3. For each rule in the checklist:
   - If the rule is marked **[HARD BAN]** in universal-ai-tells.md: enforce it regardless of overrides
   - If the rule has an override key in style-preferences.md: use the override
   - Otherwise: use the universal default
4. Score accordingly

**Example:**
- Universal rule: em dashes banned
- Dor's override: `em_dashes: deny`
- Result: Dor's posts fail item 2 if they contain em dashes ✅

- Universal rule: em dashes banned  
- Ofer's override: `em_dashes: allow`
- Result: Ofer's posts with em dashes pass item 2 ✅

## How the Feedback Skill Updates This File

When a champion gives feedback:

- "too formal" → update `formality` and `vocabulary_register`, add a feedback learning entry
- "I wouldn't use that word" → add the word to `banned_words_add`
- "I don't mind em dashes" → set `em_dashes: allow`, add a feedback learning entry
- "this is perfect, more like this" → add positive note to "Phrases to Use"
- Champion rewrites a specific sentence → compare old vs new, extract pattern, add to style notes

Each update increments the `version` and updates `updated_at`.

## How Onboarding Creates This File

The zero-touch onboarding reads real writing samples from Slack/LinkedIn/X and auto-populates:

1. Observed em dash usage → `em_dashes: allow` or `deny`
2. Observed emoji count per post → `emoji_max`
3. Observed sentence length patterns → `sentence_length`
4. Observed humor frequency → `humor_frequency`
5. Actual writing samples copied verbatim → "Real Writing Samples" section
6. Hebrew usage detected → `uses_hebrew: true`

Nothing is guessed. Everything is derived from real data. Champions never see this file unless they want to edit it manually.

## Schema Evolution

This schema will evolve as we learn more about per-champion variation. Any new override key follows this pattern:
- Add it to `universal-ai-tells.md` as "Overridable? ✅ Yes, key: `new_key`"
- Add it to this schema with allowed values and default
- Update the Voice Guardian to check the override during scoring
