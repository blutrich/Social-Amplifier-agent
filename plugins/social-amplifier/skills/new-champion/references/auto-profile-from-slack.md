# Auto-Profiling from Slack

How to build a champion's voice profile by reading their real Slack activity. This is the core of zero-touch onboarding — the operator provides a name and role, and this file documents how to extract everything else from the champion's existing Slack footprint.

## Why Slack First

Slack is the richest source of a person's real writing voice for three reasons:

1. **Volume.** Most Base44 employees write dozens of Slack messages per day. That's 1000s of sentences of real writing.
2. **Unedited.** Slack messages are stream-of-consciousness — no "editing for LinkedIn", no marketing polish. This is how they actually think and talk.
3. **Authenticated.** We can identify the exact user via Slack user ID and filter strictly to their own messages.

LinkedIn and X are edited, polished, performative. Slack is real. For tone-of-voice learning, real beats polished every time.

## Required MCPs

The Slack MCP must be connected. Tool prefix: `mcp__plugin_slack_slack__*`.

If Slack MCP is not available, fall back to the LinkedIn/X OctoLens path (see `auto-profile-from-octolens.md`), but expect lower-quality voice extraction.

## Step 1: Resolve the Champion's Slack User ID

You're given `@slack.username` by the operator. Convert to a Slack user ID:

```
mcp__plugin_slack_slack__slack_search_users(query="{username or full name}")
```

This returns a list of users. Pick the one matching the provided identifier. Store:
- `slack_user_id` (e.g., "U0AJME2T1RB")
- `display_name`
- `real_name`
- `email`

If multiple matches, use `slack_read_user_profile(user_id=...)` on each candidate to disambiguate by email or title.

## Step 2: Read the Champion's Slack Profile

```
mcp__plugin_slack_slack__slack_read_user_profile(user_id="{slack_user_id}")
```

Extract:
- `name` — from `display_name` or `real_name`
- `title` — from profile `title` field (e.g., "AI Product Builder | Base44 Marketing | 🧙")
- `timezone` — for scheduling DM delivery at the right local time
- `email` — for Base44 entity linkage later

Parse the `title` field for role signals. Base44 titles often combine role + team + personality emoji. Extract all three:
- Role (e.g., "AI Product Builder", "Head of Comms", "Senior Engineer")
- Team (e.g., "Base44 Marketing", "Engineering", "Product")
- Personality signal (emoji like 🧙, 🚀, 🎨 — useful for humor analysis)

## Step 3: Pull Recent Messages Written by the Champion

Search Slack for their last ~200 messages. Use `from:me` if the champion is the current user, or `from:@username` otherwise:

```
mcp__plugin_slack_slack__slack_search_public_and_private(
  query="from:{username}",
  limit=20,
  sort="timestamp"
)
```

Paginate to get 200+ messages. Filter out:
- Pure emoji reactions
- Single-character acknowledgments ("ok", "yep", "👍")
- Automated bot-triggered outputs (you'll see patterns like "Auto-Waterfall v2 Scan Complete" from Ofer's self-DMs — those are scripts, not voice)
- Messages in languages other than the target (unless code-switching is part of their voice)

Keep the **substantive writing samples** — real sentences where the champion explains, argues, jokes, or thinks out loud.

## Step 4: Read Their Sent Channel Messages

DMs capture 1:1 conversation style. Public channel messages capture broadcast style. You want both:

```
mcp__plugin_slack_slack__slack_search_public_and_private(
  query="from:{username}",
  channel_types="public_channel",
  limit=20
)
```

Compare DM voice vs channel voice. Most people are slightly more formal in public channels. Note this pattern — it's a signal for how to tune LinkedIn (public) vs X (casual).

## Step 5: Analyze the Writing Samples

For each substantive message, extract these signals:

### Sentence Length Pattern
Count words per sentence across 50+ sentences. Categorize:
- **Short** (1-8 words average): Punchy, fast-paced
- **Medium** (9-15 words average): Conversational
- **Long** (16+ words average): Deliberate, structured
- **Mixed** (high variance): Dynamic, varies by context

### Vocabulary Register
Look at word choices:
- **Technical:** Specific tech terms, API names, implementation details
- **Casual:** Contractions, slang, interjections ("yo", "haha", "dude")
- **Professional:** Corporate language, formal transitions
- **Academic:** Multi-syllable words, complex structures
- **Mixed:** Switches register based on context

### Punctuation Habits
Count across samples:
- Em dashes per 100 sentences → if >3, the champion uses em dashes naturally → set `em_dashes: allow`
- Exclamation marks per 100 sentences → high count = enthusiastic energy
- Semicolons → rare in casual writing, common in formal
- Ellipses → casual/trailing-thought style

### Structure Preferences
- **Bullet points:** Do they structure messages with bullets/lists? How often?
- **TL;DR:** Do they use "TL;DR" or summary markers?
- **Numbered sections:** Do they number points explicitly?
- **Long paragraphs:** Do they write dense paragraphs or break into chunks?

### Humor and Personality
- Jokes per 100 messages
- Self-deprecation frequency
- Sarcasm markers
- Emoji usage (count, variety, context — structural use vs decorative)
- Strong opinions ("no-brainer", "this is wild", "absolutely not")

### Language Mix
- Percentage Hebrew vs English
- Code-switching patterns (do they mix within a single message, or switch based on audience?)

### Named References
Do they name specific people in their writing? This is a strong signal of a "connector" voice (mentions collaborators, tags experts) vs "solo" voice (talks about the work, not the team).

## Step 6: Build the Voice Profile

Using the analysis, populate these files (templates in `profile-templates.md`):

### profile.json
- `name` — from Slack profile
- `champion_id` — kebab-case of name
- `role` — derived from Slack title or operator-provided
- `team` — extracted from title or channel membership
- `topics` — inferred from channel membership + message topics (see Step 7)
- `platforms` — default ["linkedin"] unless X activity detected
- `timezone` — from Slack profile
- `created_at`, `version`

### tone-of-voice.md
Use the template. Populate each section from the analysis:
- **Voice Summary** — one sentence synthesizing the patterns (e.g., "A marketing builder who writes like a senior engineer: TL;DR format, em dashes, shows the math, names collaborators, opinionated.")
- **Tone** — from register + energy analysis
- **Sentence Patterns** — from length analysis
- **Vocabulary** — list 10-15 words/phrases the champion actually uses, plus 5-10 they conspicuously avoid
- **Humor** — frequency and style
- **Topics** — from channel/message analysis
- **What Works** — start empty, feedback skill fills in
- **Style References** — names 3-5 real writing samples with quotes
- **The {Name} Test** — the holistic Champion Test question

### style-preferences.md
Use the schema from `voice-guardian/references/style-preferences-schema.md`. Populate from analysis:
- `em_dashes` — allow if count >3 per 100 sentences, else deny
- `emoji_max` — average emoji per message, capped at 5
- `sentence_length` — from analysis
- `vocabulary_register` — from analysis
- `energy_level` — from exclamation + strong opinion frequency
- `humor_frequency` — from joke count
- `formality` — from register analysis
- `uses_hebrew` — true if Hebrew detected in >10% of messages
- `banned_words_add` — words the universal list doesn't cover but this champion never uses
- `banned_words_remove` — universal banned words this champion actually uses naturally

### rules.md
Mostly boilerplate, personalized with name. The feedback skill populates "Avoid" and "Do More Of" over time.

## Step 7: Infer Topics from Channel Membership

The channels a champion is active in reveal their interests:

```
mcp__plugin_slack_slack__slack_list_channels(types="public_channel")
```

Then for each channel, check if the champion has recent activity:

```
mcp__plugin_slack_slack__slack_read_channel(channel_id="{id}", limit=50)
```

Filter for messages from the champion's `slack_user_id`. Channels where they post frequently are topic signals:

- `#feat-*` channels → product/engineering topics
- `#product-marketing-sync` → marketing topics  
- `#design-*` → UX/design topics
- `#gtm-*` → go-to-market topics
- Named product channels (e.g., `#reputation-drop`) → specific project involvement

Use these to populate `profile.json.topics[]`. Prefer 3-5 specific topics over generic ones.

## Step 8: Write Sample Quotes to tone-of-voice.md

Grab 3-5 real, substantive quotes from the champion and drop them verbatim into the "Style References" section of `tone-of-voice.md`. These become the comparison baseline for the Voice Guardian's tone-matching check.

Choose quotes that:
- Show at least 3 sentences of connected writing
- Are representative (not edge cases)
- Include the champion's signature patterns (TL;DR, named references, specific numbers, whatever their signature is)
- Don't contain sensitive or private information

Attribute each sample with just the date — don't include the channel name if it could be private.

## What NOT to Include

- Direct quotes from DMs unless the champion would be comfortable seeing them in their own tone-of-voice file
- Messages in languages the system doesn't have processing rules for (unless code-switching is explicitly part of the voice)
- Bot-triggered outputs (`Auto-Waterfall v2 Scan Complete`, etc.)
- Messages that are just links without context
- Reaction chains (`✅`, `👍`, `+1`)

## Validation

After building the profile, do a sanity check:

1. Re-read 5 real Slack messages from the champion
2. Ask: does the generated `tone-of-voice.md` predict how these messages sound?
3. If not, the analysis missed something. Iterate on the patterns section.

If the champion is "you" (the current operator), you can validate directly by reading your own profile and asking "does this feel like me?" If the champion is someone else (e.g., Dor), compare the generated profile against 2-3 of their real LinkedIn posts as a cross-check.

## Output

A complete set of champion files ready for the content-specialist and voice-guardian to use:

```
champions/{champion_id}/
├── profile.json
├── tone-of-voice.md
├── inspirations.md (often empty initially — populated if LinkedIn/X analysis runs)
├── rules.md
├── style-preferences.md
└── content-history/
```

Total time from `@username` to complete profile: ~30-60 seconds.
