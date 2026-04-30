# Fallback Questions for Manual Onboarding

The zero-touch onboarding flow profiles a champion entirely from Slack + public social activity. But sometimes auto-profiling fails or produces incomplete data. This file documents the minimal question set to fill the gaps.

**Philosophy:** Never ask more than 3 questions. The whole point of the refactor is that shy devs won't do 8-step wizards. Every question you ask is a friction point that might kill the onboarding. Only ask what you absolutely can't infer.

## When to Use Questions

Ask questions only when auto-profiling fails to produce actionable data. The three common failure modes:

1. **Slack has too few messages.** New employee, inactive user, or someone who mostly uses other tools. If total substantive messages < 20, auto-profiling voice patterns is unreliable.

2. **Role is ambiguous from Slack title.** Some titles are cryptic (e.g., "Chief Vibe Officer", "Builder", or just an emoji). The operator should disambiguate.

3. **Topics can't be inferred from channel membership.** Champion is in very few channels, or their channels don't map cleanly to a persona (dev/marketing/comms/ops/sales).

## The Minimum Viable Question Set

These are the ONLY questions worth asking. Never add more without removing an existing one.

### Question 1: Role / Persona (ALWAYS ask if not provided by operator)

```
"What persona should I map you to? This controls which social signals I send your way:

1. Comms / PR — brand mentions, crisis management, industry narratives
2. Dev / Engineering — technical debates, tool launches, bug stories
3. Product / PM — product design, user insights, feature decisions
4. Marketing — competitor moves, growth tactics, content trends
5. Founder / Exec — strategic moves, wins to amplify, high-reach content
6. Ops — scaling stories, infrastructure, process
7. Sales / AE / SE — customer wins, competitive intel, use-case stories, ROI proof

Just reply with a number."
```

**Why this question:** The OctoLens view mapping depends on persona. A dev gets "Industry insights" + product_question tags. A comms person gets "Brand monitoring" + "Crisis management". This drives the entire content feed.

**When to skip:** The operator provided `role:comms` (or similar) when running `/new-champion`. In that case, trust the operator and skip.

### Question 2: Topics (ONLY if channel inference failed)

```
"What topics do you actually want to write about? (not your job description — your genuine interests)

You can pick from:
• The work you do at Base44 day-to-day
• Industry trends in your space
• Tools and techniques you're excited about
• Lessons from specific projects
• Hot takes on things you disagree with

Or just type 2-4 topics in your own words."
```

**Why this question:** Some champions are in generic channels (`#general`, `#random`) that don't reveal topic preferences. When channel inference gives fewer than 2 confident topics, ask.

**When to skip:** Slack channel analysis produced 3+ confident topics. Use those.

### Question 3: Writing Samples (ONLY if Slack analysis produced thin voice data)

```
"I couldn't find enough of your writing in Slack to figure out your voice. Could you paste 2-3 examples of things you've written? 

Anything works:
• A LinkedIn post you wrote (even a short one)
• A long Slack message you're proud of
• An email where you explained something
• A blog post or doc you wrote

Don't worry about formatting — I just need to see how you actually write."
```

**Why this question:** Voice analysis needs at least 50 sentences of real writing. If Slack has fewer, we need direct samples.

**When to skip:** Slack analysis found 100+ substantive messages. That's enough.

## What NEVER to Ask

The old 8-step flow asked for:

- ❌ **Full name** — Get it from Slack profile
- ❌ **Role** (literal title) — Get it from Slack profile title field  
- ❌ **Inspirations / people you follow** — Infer from LinkedIn engagement via OctoLens, or skip
- ❌ **Content preferences** (checkbox list) — Derive from actual post patterns, don't ask
- ❌ **Confirmation step** ("does this look right?") — Trust the auto-profile, let feedback correct it later
- ❌ **Platform preferences** — Default to LinkedIn unless public X activity detected

Every one of these is a friction point. If you need the data, derive it. If you can't derive it, make a reasonable default and let the feedback loop correct it over time.

## Delivery Mode

The questions are designed for Slack DM delivery by the agent, not an in-terminal Claude Code Q&A. When a new champion needs a clarifying question, the agent DMs them through the Slack MCP:

```
mcp__plugin_slack_slack__slack_send_message(
  channel_id="{champion_user_id}",
  text="{question from this file, formatted with the options}"
)
```

The champion replies with a number or short text. The onboarding process then:
1. Reads the reply via `slack_read_thread` or the next search
2. Updates the profile
3. Sends a final confirmation DM with the first batch of content

Total champion effort: 10-30 seconds if they reply immediately. The operator (Ofer/Dor) does not need to be in the loop for clarifying questions.

## Confidence Thresholds

Only ask questions when auto-profiling confidence is low. Rough thresholds:

| Signal | Auto-profile | Ask question |
|--------|--------------|--------------|
| Substantive Slack messages | ≥ 50 | < 50 |
| Confident topics inferred | ≥ 3 | < 3 |
| Role disambiguation | Slack title matches known pattern | Ambiguous or missing |
| Public posts found | ≥ 5 | < 5 AND needed |

If all signals are above threshold, run fully automated. If one is below, ask the single corresponding question. Never ask more than one question per onboarding session if you can avoid it.

## Fallback Path When Champion Doesn't Reply

Champions are busy. If they don't reply to a clarifying DM within 24 hours:

1. Build the profile with reasonable defaults anyway
2. Mark the profile as `status: auto_with_defaults` in `profile.json`
3. Start delivering content based on the default profile
4. When the champion eventually replies with feedback ("this isn't my voice"), use that feedback to correct the profile via the feedback skill

**Don't block onboarding on unanswered questions.** The product has to work even when champions don't engage with the onboarding flow. Feedback corrects defaults over time.

## Example Interaction

Scenario: Operator runs `/new-champion @dan.cohen` (no role provided)

Auto-profile succeeds on everything EXCEPT role (Dan's Slack title is just "Builder 🚀").

The skill sends Dan one DM:

> Hey Dan! Ofer set you up with Social Amplifier — I'll draft LinkedIn/X posts for you from real Base44 mentions and industry conversations.
>
> Quick question, what's your main focus?
>
> 1. Comms / PR
> 2. Dev / Engineering  
> 3. Product / PM
> 4. Marketing
> 5. Founder / Exec
> 6. Ops
> 7. Sales / AE / SE
>
> Reply with a number (or "no thanks" to opt out). First posts coming tomorrow morning.

Dan replies: "2"

Skill finalizes the profile with `persona: dev`, stores it, schedules the first content delivery for 9am Dan's local time.

Total friction for Dan: 10 seconds. Profile quality: ~85% of what the 8-step flow would produce, refined via feedback over the next week.
