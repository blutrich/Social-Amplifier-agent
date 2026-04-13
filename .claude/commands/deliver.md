---
description: Deliver generated content to a champion via Slack DM
---

Deliver content for champion: $ARGUMENTS

Load the Social Amplifier plugin and use the `deliver-content` skill to send draft posts via Slack DM.

The argument is the champion ID (e.g., `dor-blech`). If the argument includes `--dry-run`, use dry run mode which writes the formatted message to `content-history/DRYRUN-{date}.md` instead of actually sending.

Before delivery:
1. Verify the champion profile exists at `plugins/social-amplifier/champions/{champion_id}/`
2. Verify the champion's `profile.json` has `status: active`
3. Verify content has been generated and passed Voice Guardian scoring

During delivery, follow the process in `plugins/social-amplifier/skills/deliver-content/SKILL.md`:
1. Validate inputs
2. Resolve the DM channel via Slack MCP
3. Pick the right template (usually daily-digest for a `/deliver` command)
4. Populate the template with drafts and variables
5. Send via `slack_send_message` or `slack_schedule_message`
6. Write the delivery log to `content-history/`

After delivery, report the outcome using the output format from the skill's Output section.
