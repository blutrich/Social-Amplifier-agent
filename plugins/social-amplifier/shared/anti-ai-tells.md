# Anti-AI-Tells (Moved)

This file has been moved to `plugins/social-amplifier/skills/voice-guardian/references/universal-ai-tells.md` as part of the progressive disclosure refactor.

## Why It Moved

The anti-AI-tells list is only used by the Voice Guardian skill. Keeping it at the plugin root meant every agent and skill that mentioned the Voice Guardian loaded it implicitly, even when they only needed to know that a quality gate exists.

Moving it into `skills/voice-guardian/references/` means:

1. The content lives next to the skill that uses it
2. Only the Voice Guardian loads it, on demand
3. Per-champion overrides (`champions/{id}/style-preferences.md`) can cleanly relax specific rules without touching the baseline
4. The universal vs per-champion rule separation is visible in the file structure itself

## New Location

`plugins/social-amplifier/skills/voice-guardian/references/universal-ai-tells.md`

If you're updating the banned word list, edit that file. This file will be deleted in a future cleanup pass once we verify nothing still references `shared/anti-ai-tells.md`.
