---
name: voice-guardian
description: |
  Quality gate for champion content. Scores generated LinkedIn/X posts against a 10-point checklist, enforces per-champion voice rules on top of universal AI-tell bans, and either approves, auto-rewrites, or rejects.

  Use this skill whenever content is about to be delivered to a champion — this is the last line of defense against AI-generated content leaking through. Also use when a champion gives feedback on a delivered post, to trigger a rescore against their updated preferences.
disable-model-invocation: true
---

# Voice Guardian Skill

Quality gate that catches AI-generated content before it reaches a champion. Every draft passes through this skill. Nothing ships without scoring 9+/10.

## When This Skill Runs

- **Before delivery:** After the content-specialist generates 2-3 variations, each one is scored here
- **After feedback:** When a champion replies "too formal" or "not my style", this skill re-scores with updated preferences
- **On demand:** When an operator wants to verify a specific piece of content before sending

## The Core Insight

**Universal rules are not enough.** An em dash is an AI tell for Maor but a natural part of Ofer's writing voice. If we apply one universal ban list, every post for every champion will either be too loose (bad content ships) or too strict (good content gets killed). The fix is two layers:

1. **Universal baseline** — patterns that are always AI tells, regardless of who's writing (see `references/universal-ai-tells.md`)
2. **Per-champion overrides** — structural rules that each champion can relax based on their real writing style (see `champions/{id}/style-preferences.md` + schema in `references/style-preferences-schema.md`)

Hard-ban items (corporate announcement phrases, engagement bait, contrast framing) cannot be overridden. Everything else can be tuned per-champion.

## Process

### Step 1: Load Context

Read these files in order:

```
Read(file_path="plugins/social-amplifier/skills/voice-guardian/references/universal-ai-tells.md")
Read(file_path="plugins/social-amplifier/skills/voice-guardian/references/checklist.md")
Read(file_path="plugins/social-amplifier/skills/voice-guardian/references/platform-rules.md")
Read(file_path="plugins/social-amplifier/champions/{champion_id}/tone-of-voice.md")
Read(file_path="plugins/social-amplifier/champions/{champion_id}/style-preferences.md")
Read(file_path="plugins/social-amplifier/champions/{champion_id}/profile.json")
```

If `style-preferences.md` doesn't exist (champion hasn't been fully profiled), use universal defaults only and note this in the output.

### Step 2: Score

Follow the 10-point checklist in `references/checklist.md`. For each item, score PASS (1) or FAIL (0) with a specific note explaining why. Don't skim — AI content usually fails on items 1-3 in subtle ways that are easy to miss.

When checking structural rules (item 2), remember to apply per-champion overrides. Example: if the champion has `em_dashes: allow` in `style-preferences.md`, em dashes pass item 2 for that champion only.

### Step 3: Determine Verdict

Apply the thresholds:

- **9-10/10 → APPROVED.** Ship it. Return the content and verdict to the caller.
- **7-8/10 → AUTO-REWRITE.** Load `references/rewrite-patterns.md` and rewrite the failing items only. Re-score. If the rewrite score is 9+, ship. If still 7-8, try ONE more rewrite. If still below 9 after 2 rewrites, escalate to the user with the best version.
- **Below 7/10 → REJECT.** Do not attempt to rewrite. Send the content back to the content-specialist with specific feedback about what failed and why.

### Step 4: Output

Use the exact output format from `references/checklist.md` (the "Scoring Output" section at the bottom). This structure is parsed by the delivery skill to know whether to ship or rewrite.

## Reference Files

This skill loads reference material on demand rather than keeping everything in the SKILL.md body. Each file has a specific purpose:

| File | When to Read | Purpose |
|------|-------------|---------|
| `references/checklist.md` | Every scoring run | The 10-point checklist with criteria, examples, and output format |
| `references/universal-ai-tells.md` | Every scoring run | Baseline banned words, phrases, and structures |
| `references/platform-rules.md` | Every scoring run (for item 8) | LinkedIn and X format specifications |
| `references/rewrite-patterns.md` | Only on AUTO-REWRITE verdict | How to fix failing items without over-polishing |
| `references/style-preferences-schema.md` | Only when creating/updating a champion's style-preferences.md | Schema documentation for the per-champion overrides file |

Don't preload all of them. Read the ones you need when you need them.

## Rewrite Rules (Summary)

Full details in `references/rewrite-patterns.md`. The short version:

- Fix only the failing items, preserve everything that passed
- Never rewrite more than 40% of the words (that's a regeneration, not a rewrite)
- Don't over-polish (clean writing often reads as AI writing)
- Don't change the angle (that's also a regeneration)
- Re-read the champion's `tone-of-voice.md` before writing replacements
- Max 2 rewrite attempts, then escalate

## Escalation

When 2 rewrite attempts both fail:

1. Return the best version with the highest score
2. List which items keep failing
3. Identify the root cause (tone mismatch? missing data? wrong angle?)
4. Recommend what the content-specialist should do differently on regeneration

Full escalation format in `references/rewrite-patterns.md`.

## Integration With Other Skills

- **Called by:** `generate-content` (after creating variations), delivery flows (before sending)
- **Calls:** No other skills. This skill is terminal — it either returns APPROVED/REWRITE/REJECT and the caller decides what to do next.
- **Loads:** The reference files above plus champion-specific files
- **Writes:** Nothing directly. Feedback skill updates `champions/{id}/style-preferences.md` based on Voice Guardian output.

## The Champion Test

Every scoring run ends with the same question: **would this specific champion copy-paste this into their LinkedIn and hit post without editing?**

If the answer is "yes": APPROVED.
If the answer is "it's fine but they'd probably tweak it": not good enough — either REWRITE or REJECT.
If the answer is "no": REJECT.

This is the holistic check that catches what the item-by-item checklist misses. Trust it.
