---
name: voice-guardian
description: |
  Quality gate skill. Loads anti-AI-tells and champion voice profile for comparison.
  Used by the voice-guardian agent to score and approve/rewrite content.
disable-model-invocation: true
---

# Voice Guardian Skill

## Reference Files

Load these before scoring:
```
Read(file_path="shared/anti-ai-tells.md")
Read(file_path="champions/{champion_id}/tone-of-voice.md")
Read(file_path="champions/{champion_id}/rules.md")
```

## Scoring Thresholds

- 9-10/10: APPROVED (ship)
- 7-8/10: AUTO-REWRITE (fix failing items, re-score)
- <7/10: REJECT (regenerate from scratch)

## Max Rewrite Attempts: 2

After 2 failed rewrites, escalate to the user with the best version + specific feedback.
