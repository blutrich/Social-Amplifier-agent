---
name: new-champion
description: |
  Zero-touch champion onboarding. Given a Slack username and optional persona, auto-profiles the champion from their real Slack + public social activity and produces a complete voice profile in ~30-60 seconds. No 8-step wizard.

  Use this skill when an operator (Ofer, Dor) wants to add a new champion to the Social Amplifier. Triggers on: new champion, onboard, /new-champion, set up X for content. Also use when refreshing an existing champion's profile after significant writing activity changes.
---

# New Champion Onboarding

Builds a complete champion voice profile with minimal friction. The champion never fills out a wizard. The operator runs one command. The skill does the rest.

## Core Principle

**Shy devs and busy people won't go through an 8-step onboarding.** The old version of this skill asked 8 questions interactively. Champions would abandon at step 2. The new version asks 0-3 questions max, and only when auto-profiling fails.

**The data is already there.** Every Base44 employee has a Slack footprint, a role in their profile, channels they're active in, and (usually) some public social presence. Auto-profiling can extract all of this in under a minute, producing a profile that's 85% as good as the 8-step wizard would have been. Feedback closes the remaining 15% over the first week of usage.

## How to Invoke

The skill accepts these input patterns:

### Pattern 1: Operator provides everything (fastest)
```
/new-champion @dor.blech role:comms
```
Zero questions. Runs fully automated. ~30 seconds.

### Pattern 2: Operator provides just a username
```
/new-champion @dor.blech
```
One question (persona) if Slack title is ambiguous. Otherwise zero questions. ~30-60 seconds.

### Pattern 3: Operator provides name only
```
/new-champion "Dor Blech"
```
Resolves to Slack user first, then follows Pattern 2.

### Pattern 4: Refresh existing champion
```
/new-champion @dor.blech --refresh
```
Re-runs profiling on an existing champion, preserving feedback learnings and content history. Use after significant writing activity changes or when you suspect the profile has drifted.

## Process Overview

The auto-profiling runs in 5 phases. Details for each phase live in the reference files — this skill orchestrates the flow.

### Phase 1: Resolve the Champion

Take the operator's input (`@username`, name, or user ID) and resolve it to a specific Slack user. Read their Slack profile to get name, title, timezone, and team.

**Details:** `references/auto-profile-from-slack.md` Step 1 and Step 2

### Phase 2: Profile From Slack (Primary Source)

Pull ~200 substantive messages the champion has written. Analyze writing patterns: sentence length, vocabulary, punctuation habits, structure preferences, humor, language mix, named references.

**Details:** `references/auto-profile-from-slack.md` Steps 3-7

### Phase 3: Enrich From Public Social (If Available)

Query OctoLens for the champion's LinkedIn/X posts. If they're indexed, extract public writing samples and engagement patterns. If not, fall back to operator-provided samples or mark the profile as "Slack-only".

**Details:** `references/auto-profile-from-octolens.md` (entire file)

### Phase 4: Ask Clarifying Questions (Only If Needed)

Check confidence levels:
- If persona is unclear and operator didn't provide → ask Question 1 from `references/fallback-questions.md`
- If topics inference produced fewer than 2 confident topics → ask Question 2
- If Slack voice data is sparse (<50 substantive messages) and no public samples → ask Question 3

Maximum 1 question per onboarding session. Questions are delivered via Slack DM to the champion, not as a terminal prompt to the operator.

**Details:** `references/fallback-questions.md`

### Phase 5: Write Profile Files

Create the champion's directory and write 5 files:
- `profile.json`
- `tone-of-voice.md`
- `style-preferences.md` (critical — this powers per-champion Voice Guardian overrides)
- `rules.md`
- `inspirations.md` (or placeholder if no data)

**Details:** `references/profile-templates.md`

## Reference Files

This skill loads reference material on demand rather than embedding everything in the SKILL.md body. Each file has a specific purpose:

| File | When to Read | Purpose |
|------|-------------|---------|
| `references/auto-profile-from-slack.md` | Always (primary profiling path) | Slack MCP queries, writing analysis patterns, how to extract voice from real messages |
| `references/auto-profile-from-octolens.md` | If OctoLens MCP available OR public social data needed | LinkedIn/X profiling via OctoLens, fallback to WebFetch, voice delta analysis |
| `references/fallback-questions.md` | Only if auto-profile confidence is low | The 3 minimum-viable questions and when to ask each |
| `references/profile-templates.md` | Always (writing phase) | Templates for all 5 output files with field definitions |

Don't preload all of them. Start with `auto-profile-from-slack.md`, follow the process, and read the other references when you actually need them.

## The Zero-Touch Flow (Happy Path)

This is what should happen ~80% of the time, when the champion has a rich Slack history:

1. Operator runs `/new-champion @dor.blech role:comms`
2. Skill resolves `@dor.blech` → `U0AJME2T1RB` (Dor's Slack user ID)
3. Skill reads Dor's Slack profile → name "Dor Blech", title "Head of Communications", timezone "Asia/Jerusalem"
4. Skill queries Slack for Dor's last 200 messages → gets 180 substantive writing samples
5. Skill analyzes patterns:
   - Sentence length: mixed (short punchy + long explanatory)
   - Vocabulary: conversational, bilingual (English + Hebrew)
   - Em dash usage: 5 per 100 sentences → allow
   - Emoji usage: average 1 per message → emoji_max: 2
   - Structure: TL;DR format when explaining, short when asking
6. Skill queries OctoLens for author "Dor Blech" or "dor_blech" on any platform → finds 3 LinkedIn posts
7. Skill extracts LinkedIn voice samples, adds to tone-of-voice.md
8. Skill writes all 5 profile files
9. Skill confirms: "Champion profile created for Dor Blech. First content delivery scheduled for 9am Asia/Jerusalem."

Total time: ~45 seconds. Total Dor effort: zero. Total operator effort: typing the command.

## When to Fall Back to Questions

Ask the minimum-viable question set (from `references/fallback-questions.md`) only in these cases:

- **Persona ambiguous:** Slack title is cryptic ("Builder", "Chief Vibe Officer", emoji-only) AND operator didn't provide `role:`. Ask Question 1 (persona).
- **Topics sparse:** Channel membership + message analysis produced <2 confident topic candidates. Ask Question 2.
- **Voice data thin:** <50 substantive Slack messages AND no public social samples available. Ask Question 3 (writing samples).

Ask at most 1 question per onboarding. Send it via Slack DM to the champion, not as a terminal prompt. If the champion doesn't reply in 24 hours, fall back to defaults and proceed — don't block the onboarding on an unanswered question.

## Integration With Other Skills

- **Called by:** Operator via `/new-champion` slash command
- **Reads:** Slack MCP (user profiles + message search), OctoLens MCP (public social history)
- **Writes:** Champion profile files in `plugins/social-amplifier/champions/{champion_id}/`
- **Triggers:** First content generation via `generate-content` skill if operator runs `/generate {champion_id}` next

## Voice Guardian Dependency

The output of this skill feeds directly into the Voice Guardian. Specifically:

- `tone-of-voice.md` is the baseline for the Voice Guardian's tone-matching check (item 4)
- `style-preferences.md` is the per-champion override file that the Voice Guardian loads alongside the universal rules
- `profile.json` topics feeds item 5 (champion topics check)
- `rules.md` informs rewrite patterns

Every file this skill creates has a consumer in the Voice Guardian flow. If the champion's posts fail Voice Guardian scoring, the root cause is often that this skill produced thin or inaccurate profile data. The fix is usually to refresh the profile with more Slack activity or operator-provided samples.

## Output

On success:

```
Champion profile created for {Name} ({champion_id}).

Source: Slack ({N} messages analyzed) + {OctoLens | samples provided | Slack-only}
Persona: {persona}
Topics: {3-5 topics}
Voice confidence: {high | medium | low}

Voice signature:
- {pattern 1}
- {pattern 2}
- {pattern 3}

Style overrides:
- Em dashes: {allow | deny}
- Emoji max: {N}
- Humor frequency: {level}

Files created:
- plugins/social-amplifier/champions/{champion_id}/profile.json
- plugins/social-amplifier/champions/{champion_id}/tone-of-voice.md
- plugins/social-amplifier/champions/{champion_id}/style-preferences.md
- plugins/social-amplifier/champions/{champion_id}/rules.md
- plugins/social-amplifier/champions/{champion_id}/inspirations.md

Next step: run /generate {champion_id} to create the first test content.
```

On partial success (fell back to questions or defaults):

```
Champion profile created for {Name} with defaults.

Reason: {specific gap, e.g., "Only 23 substantive Slack messages found"}
Status: auto_with_defaults

Profile will improve over time as the champion gives feedback on delivered content. You can also refresh manually with /new-champion {champion_id} --refresh after they've been active for a week.

Next step: run /generate {champion_id} to create the first test content.
```

On failure:

```
Could not create champion profile.

Reason: {specific blocker, e.g., "Slack MCP not connected" or "User @{username} not found"}

Fix and retry.
```
