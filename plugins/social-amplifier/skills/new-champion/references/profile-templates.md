# Champion Profile Templates

Templates for the files created by the new-champion skill. Each template has placeholders that are filled in by the auto-profiling process.

## Directory Structure

```
plugins/social-amplifier/champions/{champion_id}/
├── profile.json              (structured data)
├── tone-of-voice.md          (voice analysis with samples)
├── style-preferences.md      (per-champion Voice Guardian overrides)
├── rules.md                  (personalized content rules)
├── inspirations.md           (people the champion engages with)
└── content-history/          (empty directory; fills as content is generated)
```

All files must exist before the champion is considered fully onboarded. The `content-history/` directory stays empty at onboarding time and is populated by the generate-content skill later.

---

## Template: profile.json

```json
{
  "name": "{Full Name from Slack}",
  "champion_id": "{kebab-case-of-name}",
  "slack_user_id": "{U0XXXXXXX}",
  "email": "{email from Slack profile}",
  "role": "{role derived from Slack title or operator input}",
  "team": "{team derived from Slack title}",
  "persona": "{comms | dev | product | marketing | founder | ops}",
  "topics": ["{topic1}", "{topic2}", "{topic3}"],
  "platforms": ["linkedin", "x"],
  "timezone": "{from Slack profile, e.g., Asia/Jerusalem}",
  "uses_hebrew": {true|false},
  "created_at": "{YYYY-MM-DD}",
  "updated_at": "{YYYY-MM-DD}",
  "version": 1,
  "status": "{active | auto_with_defaults | paused | archived}",
  "profile_source": {
    "slack_analyzed": true,
    "octolens_analyzed": {true|false},
    "linkedin_samples_provided": {true|false},
    "questions_asked": {0-3}
  }
}
```

### Field Definitions

- **persona**: Maps to OctoLens saved views for content filtering
- **topics**: 3-5 specific topics derived from channel activity + message content analysis
- **platforms**: Where to generate content (default ["linkedin"] unless X activity detected)
- **status**: "active" means delivery happens. "auto_with_defaults" means profile exists but clarifying questions went unanswered — still delivers, just less tuned.
- **profile_source**: Tracks how the profile was built, useful for debugging why some profiles work better than others

---

## Template: tone-of-voice.md

```markdown
# {Name} - Tone of Voice

## Voice Summary
{One sentence synthesizing how this champion writes. Example: "A marketing builder who writes like a senior engineer — TL;DR format, em dashes, shows the math, names collaborators, opinionated without being combative."}

## Tone
- **Register:** {casual | professional | technical | academic | mixed}
- **Energy level:** {high | measured | low}
- **Formality:** {formal | conversational | casual | code-switches}
- **Humor frequency:** {frequent | occasional | rare | never}
- **Humor style:** {self-deprecating | observational | dry | absurdist | none}

## Sentence Patterns
- **Typical length:** {short (1-8 words) | medium (9-15) | long (16+) | mixed}
- **Structure:** {bullet-heavy | prose | numbered | TL;DR-first | meandering}
- **Paragraph style:** {short 1-3 sentence chunks | long dense paragraphs | mixed}
- **Opens with:** {observation | question | number | hook | story | transition}
- **Closes with:** {takeaway | question | concrete ask | silence (no CTA) | named reference}

## Vocabulary

### Words They Use Naturally
{10-15 specific words and phrases observed in their real writing}
- "TL;DR"
- "no-brainer"
- "the thing that's going to bite us"
- "infrastructure"
- "shipped"
- ...

### Words They Conspicuously Avoid
{5-10 words they never use in their writing — not just the universal banned list, but things specific to this person}
- "leverage"
- "synergy"
- "at the end of the day"
- ...

### Character Tics
{Punctuation habits, emoji usage, specific phrases they repeat}
- Uses em dashes for parenthetical thoughts
- Maximum 1 emoji per post, usually at the end
- Opens technical messages with "Hey [name] —"
- Uses TL;DR format for anything over 5 lines

## Humor
{How and when this champion uses humor. Specific enough that the content-specialist can replicate it.}

Example: "Dry, understated humor in Slack (deadpan observations, no exclamation marks). Less humor in LinkedIn (measured, professional). Occasional self-deprecating aside about being 'two months in at Base44'."

## Topics
{3-5 topic areas this champion writes about, with the angle they take}

1. **{Topic}** — {angle they bring to it}
2. **{Topic}** — {angle}
...

## What Works
{Empty at onboarding. The feedback skill populates this section as posts get approved. Each entry is a specific pattern that landed.}

Format (populated by feedback skill):
- [YYYY-MM-DD] {pattern that worked} — {example or context}

## Style References

### Private Voice (from Slack, unfiltered)

**Sample 1** (Slack DM, {date}):
> {Verbatim quote from real Slack message, 3+ sentences showing voice}

**Sample 2** (Slack channel, {date}):
> {Verbatim quote}

**Sample 3** (Slack DM, {date}):
> {Verbatim quote}

### Public Voice (from LinkedIn/X, if available)

**Sample 1** ({platform}, {date}, {engagement if known}):
> {Verbatim quote from real public post}

### Voice Delta (private vs public)
{If samples from both sources are available, describe how the champion's voice shifts between private and public writing}

Example: "In Slack, uses Hebrew/English mix, em dashes, technical jargon. In LinkedIn, all English, slightly more formal, shorter paragraphs. Same opinions, cleaner delivery."

## The {Name} Test
Would {Name} copy-paste this content into their LinkedIn and hit post without editing? If the answer is "it's fine but they'd probably tweak it", it fails. The Voice Guardian uses this as the holistic check.
```

---

## Template: style-preferences.md

Use the schema from `plugins/social-amplifier/skills/voice-guardian/references/style-preferences-schema.md`. The new-champion skill writes the initial version with values derived from auto-profiling. The feedback skill updates it over time.

```markdown
---
champion_id: {champion_id}
updated_at: {YYYY-MM-DD}
version: 1

# Structural overrides (derived from Slack/public writing analysis)
em_dashes: {allow | deny}              # allow if count >3 per 100 sentences
rule_of_three: deny                    # rarely relax
numbered_lists: {allow | deny}         # allow if observed in real writing
thread_numbering_linkedin: deny        # keep disabled for LinkedIn
emoji_max: {integer, default 2}        # average emoji per message, capped at 5
hashtag_max: {integer, default 2}

# Vocabulary overrides
banned_words_add:                      # extra words THIS champion never uses
  - "{word1}"
  - "{word2}"
banned_words_remove:                   # universal banned words THIS champion uses naturally
  - "{word1}"

# Tone characteristics (descriptive)
sentence_length: {short | medium | long | mixed}
vocabulary_register: {casual | professional | technical | mixed}
energy_level: {high | measured | low}
humor_frequency: {frequent | occasional | rare | never}
formality: {formal | conversational | casual | mixed}
uses_hebrew: {true | false}
mixes_languages: {true | false}

# Platform-specific overrides
linkedin:
  word_count_min: 150
  word_count_max: 300
  paragraph_style: {short | medium | long}
  hook_style: {story | observation | number | hot-take}

x:
  single_tweet_preferred: {true | false}
  thread_max: 7
  emoji_style: {minimal | moderate | frequent}
---

# {Name} Style Notes

## Writing Patterns Observed
{Specific patterns from the auto-profiling analysis. 3-5 bullet points.}

- {Pattern 1 observed in Slack writing}
- {Pattern 2}
- {Pattern 3}

## Phrases to Use
{Observed phrases from their real writing}
- "{actual phrase they use}"
- "{actual phrase}"

## Phrases to Avoid
{Universal + observed avoidances}
- {category or specific phrase}

## Feedback Learnings
{Empty at onboarding. Feedback skill fills this in over time.}
```

---

## Template: rules.md

```markdown
# {Name}'s Content Rules

## Always
- Sound like {Name}, not an AI
- Use first person ("I") except when speaking for the team ("we")
- Reference specific experiences, numbers, or named collaborators
- Match the energy level observed in real writing: {level from analysis}

## Never
- Corporate marketing language (see universal-ai-tells.md for the full list)
- Base44 press release tone
- Generic motivational content ("keep pushing", "stay hungry")
- Emojis as bullet points
- Engagement bait ("What would you build?", "Thoughts?")
- Fake vulnerability ("Honestly wasn't sure...")

## Avoid
{Populated by feedback skill as champion gives corrections}

## Do More Of
{Populated by feedback skill as patterns get validated}

## Platform-Specific

### LinkedIn
- Length: 150-300 words
- Structure: {observed pattern}
- Hook style: {observed pattern}

### X / Twitter
- Single tweet preferred: {true | false based on analysis}
- Thread style: {numbered | unnumbered | avoided}
- Voice shift from LinkedIn: {how their X voice differs from LinkedIn voice}
```

---

## Template: inspirations.md

This file is populated only if public social profiling succeeded and found engagement patterns. Otherwise, it's a minimal placeholder.

```markdown
# {Name}'s Inspirations

## People They Engage With
{3-5 people the champion replies to, quotes, or mentions frequently in their public posts. From OctoLens or manual analysis.}

### @{handle} — {Name if known}
**Voice signature:** {short summary of distinctive style}
**What {Name} likely borrows:** {specific pattern observed in the champion's own writing that echoes this person}
**Sample post by them:**
> {quote}

## Content They Enjoy
{Platforms, blogs, podcasts, etc. the champion references in their writing}

## Voice Patterns This Champion Has Absorbed
{Observed patterns that suggest influence from these inspirations}

- Uses {pattern} — likely borrowed from {inspiration}
- Avoids {pattern} — consistent with {inspiration}'s approach
```

If no inspirations data available at onboarding time, write:

```markdown
# {Name}'s Inspirations

## Status
This file is empty because auto-profiling didn't find enough public engagement patterns to identify inspirations. It will be updated if:
1. The champion provides manual inspiration URLs via the operator
2. Their public posting activity grows enough for OctoLens to map engagement patterns
3. Feedback interactions reveal which voices they're trying to match

For now, voice analysis is based on the champion's own writing in Slack.
```

---

## Writing These Files

After auto-profiling completes:

```
Bash(command="mkdir -p plugins/social-amplifier/champions/{champion_id}/content-history")

Write(file_path="plugins/social-amplifier/champions/{champion_id}/profile.json", content="{populated JSON}")

Write(file_path="plugins/social-amplifier/champions/{champion_id}/tone-of-voice.md", content="{populated template}")

Write(file_path="plugins/social-amplifier/champions/{champion_id}/style-preferences.md", content="{populated template}")

Write(file_path="plugins/social-amplifier/champions/{champion_id}/rules.md", content="{populated template}")

Write(file_path="plugins/social-amplifier/champions/{champion_id}/inspirations.md", content="{populated template or placeholder}")
```

All 5 files in 5 tool calls. Total onboarding time ~30-60 seconds for full auto-profiling.

## Verification

After writing:

```
Read(file_path="plugins/social-amplifier/champions/{champion_id}/profile.json")
Read(file_path="plugins/social-amplifier/champions/{champion_id}/tone-of-voice.md")
Read(file_path="plugins/social-amplifier/champions/{champion_id}/style-preferences.md")
Read(file_path="plugins/social-amplifier/champions/{champion_id}/rules.md")
```

Confirm all files exist and contain the expected fields. Report to the operator:

```
Champion profile created for {Name} ({champion_id}).

Source: Slack + {OctoLens | public social data | samples provided}
Persona: {persona}
Topics: {topics}
Voice confidence: {high | medium | low}

First content delivery: scheduled for {time} in {timezone}.
You can run /generate {champion_id} to test immediately.
```
