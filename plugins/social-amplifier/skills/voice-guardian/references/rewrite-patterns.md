# Auto-Rewrite Patterns

When the Voice Guardian scores content 7-8/10, it triggers an auto-rewrite loop. This file documents HOW to rewrite — the goal is to fix the failing items without over-polishing (over-polishing is itself an AI tell).

## Rewrite Philosophy

The rewrite is a scalpel, not a rewrite from scratch. Preserve everything that passed. Fix only what failed. If a rewrite requires changing the core angle or structure, the content probably deserved a REJECT verdict — send it back to the content-specialist instead.

**Rule of thumb:** If you're rewriting more than 40% of the words, you're doing a regeneration, not a rewrite. Stop and reject instead.

## Rewrite Process

1. Read the failing items from the scoring output
2. For each failing item, identify the specific words/phrases/structures to change
3. Rewrite only those elements, using the patterns below
4. Re-read the champion's `tone-of-voice.md` before writing replacements (use their vocabulary, not yours)
5. Re-score the full content
6. If score is 9+, ship
7. If score is still 7-8, try ONE more rewrite pass
8. If score is still below 9 after 2 rewrites, escalate to the user with the best version + specific feedback

## Pattern: Fix Banned Vocabulary (Item 1)

**Before:** "We leverage AI to streamline your workflow and unlock productivity gains."

**After:** "We use AI to make your workflow faster and cut the busywork."

**Rule:** Replace each banned verb/adjective with a specific concrete word from the champion's actual vocabulary. Never replace with another generic AI word.

## Pattern: Fix Em Dashes (Item 2)

Check if the champion has `em_dashes: allow` in their `style-preferences.md`. If yes, em dashes pass — don't rewrite. If no, proceed.

**Before:** "The thing is — and I've been thinking about this a lot — most builders don't need another tool."

**After (option 1, commas):** "The thing is, and I've been thinking about this a lot, most builders don't need another tool."

**After (option 2, periods):** "The thing is: most builders don't need another tool. I've been thinking about this a lot."

**After (option 3, parentheses):** "The thing is (and I've been thinking about this a lot), most builders don't need another tool."

**Rule:** Use whichever option sounds most natural for the champion's tone. Don't default to one pattern.

## Pattern: Fix Rule of Three (Item 2)

**Before:** "Fast. Simple. Powerful."

**After (option 1, full sentence):** "It's fast and simple, and it actually works."

**After (option 2, different number):** "Fast, simple, powerful, and — most importantly — finally built with the user in mind." (Note: 4 items breaks the rule-of-three pattern)

**After (option 3, eliminate):** Just write the real point directly. "It runs in milliseconds on my laptop, and I didn't have to read any docs."

**Rule:** The fix for rule-of-three is usually to add specificity. Triple-word cadence exists because the writer had nothing concrete to say.

## Pattern: Fix Self-Narration (Item 2)

**Before:** "Here's why this matters: AI is changing how we build software."

**After:** "AI is changing how we build software."

**Rule:** Just delete the self-narration opener. The sentence after it almost always works better on its own.

## Pattern: Fix Corporate Tone (Item 10)

**Before:** "We're thrilled to announce our latest innovation in AI-powered development."

**After:** "I built something this week that I can't stop using. Here's what it does."

**Rule:** Switch from "we" (brand voice) to "I" (champion voice). Replace announcements with personal observations.

## Pattern: Fix Generic Content (Item 6)

**Before:** "AI is changing everything. Every business needs to adapt."

**After:** "I talked to a founder yesterday who fired their SEO agency because their ChatGPT app pulls better traffic than any campaign. That's the new playbook."

**Rule:** Generic content fails because it has no specific detail. The rewrite must add a named person, a real number, or a concrete scenario. If you can't add a specific detail, reject instead of rewriting.

## Pattern: Fix Length Violations (Item 8)

### LinkedIn too long (400+ words)
Cut the middle section. Preserve:
- First 2 lines (hook)
- Last 2-3 lines (payoff)
- The most specific example

Remove:
- Generic industry context
- "Background" paragraphs that set up the point
- Restatements of the hook

### LinkedIn too short (<100 words)
This usually means the content is too thin. Reject and regenerate rather than padding.

### X single tweet too long
1. Remove filler words ("just", "really", "actually", "basically")
2. Cut qualifiers ("kind of", "sort of", "I think")
3. If still too long, split into a 2-tweet mini-thread

### X thread too long
Merge redundant tweets. Look for two adjacent tweets that make the same point with different wording — combine them.

## Pattern: Fix Tone Mismatch (Item 4)

This is the hardest rewrite. It requires actually understanding the champion's voice, not just fixing patterns.

**Approach:**
1. Re-read 2-3 samples of the champion's real writing from `tone-of-voice.md`
2. Identify their characteristic sentence patterns, vocabulary, and energy
3. Rewrite the content AS IF the champion were writing it from scratch
4. Keep the core point and structure, but change the voice completely

**Rule:** If you can't match the champion's voice, that's a signal the content-specialist needs better tone-of-voice data, not that the rewrite failed. Escalate with a note: "Tone matching impossible without [specific missing data]."

## What NOT to Do in Rewrites

### Don't over-polish
The instinct on a rewrite is to make everything "cleaner". Resist it. Clean writing often reads as AI writing. Real writing has natural rough edges — incomplete thoughts, abrupt transitions, tangents. Preserve those.

### Don't add new content
The rewrite is editing, not expanding. If the original content had 3 points, the rewrite should still have 3 points. Adding a 4th point means the original was missing something — that's a regeneration case.

### Don't change the angle
If the original was a "personal experience" angle (Variation A), keep it as a personal experience angle. Don't turn it into an "industry insight" angle (Variation B) during rewrite. Changing angles means you're doing a new generation, not a rewrite.

### Don't second-guess the content-specialist
If the content-specialist picked a specific example (e.g., a CS:GO randomizer story), don't swap it for a different example. Trust the example choice. Rewrite the voice, not the content.

## When to Escalate Instead of Rewriting

Send back to the content-specialist (REJECT, not REWRITE) if:
- The content scores below 7 on the first pass
- Two rewrite attempts both score below 9
- The core angle doesn't match the champion's topics (item 5 fail)
- The content requires adding a specific personal detail that you don't have
- The tone mismatch can't be fixed without actually knowing the champion better

Escalation format:
```
## Voice Guardian Escalation

**Champion:** {name}
**Platform:** {platform}
**Attempts:** 2 rewrites
**Best score:** {X}/10

### What Failed Persistently
{list of items that kept failing}

### Root Cause
{specific reason the rewrites couldn't fix it}

### Recommendation
{what the content-specialist should do differently on regeneration}
```
