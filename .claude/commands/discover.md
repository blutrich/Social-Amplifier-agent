---
description: Discover interesting subjects for a champion before content generation
---

Discover subjects for champion: $ARGUMENTS

Load the Social Amplifier plugin and use the `discover-subjects` skill to find interesting topics this champion should write about.

The argument is the champion ID (e.g., `dor-blech`). Optional flags:
- `--days=N` — extend the freshness window beyond default
- `--dedup-days=N` — override the 30-day duplicate window
- `--include-evergreen` — include evergreen subjects regardless of age
- `--check-inspirations` — add the expensive Bright Data inspiration activity check

Process:
1. Load the champion's profile, style-preferences, inspirations, and content-history
2. Query OctoLens via the persona-mapped saved views
3. Filter candidates by topic match, recency, and content-history dedup
4. Score top candidates on the 5-factor rubric (topic, recency, engagement, inspiration, originality)
5. Return the top 5 subjects with full metadata using the schema in references/subject-output-schema.md

After returning results, the operator can:
- Pick a rank to feed into generate-content: /generate {champion_id} --subject-rank=1
- Run /generate without an explicit topic to auto-pick the top subject
- Skip if all candidates score weak (<25/50)

Follow the process in plugins/social-amplifier/skills/discover-subjects/SKILL.md. Read references on demand, not all at once.
