# Platform Rules (Moved)

This file has been moved to `plugins/social-amplifier/skills/voice-guardian/references/platform-rules.md` as part of the progressive disclosure refactor.

## Why It Moved

Platform format rules are used by two skills: `voice-guardian` (to verify format compliance during scoring) and `generate-content` (to generate within format constraints). Keeping them at the plugin root meant every triggered skill loaded them, even when the skill wasn't doing platform-specific work.

Moving the canonical copy into the Voice Guardian references means it lives with the skill that enforces the rules. The `generate-content` skill can load the same file by reference when needed, rather than having its own copy.

## New Location

`plugins/social-amplifier/skills/voice-guardian/references/platform-rules.md`

If you're updating platform format rules (LinkedIn word count, X thread limits, emoji rules, etc.), edit that file. This file will be deleted in a future cleanup pass.
