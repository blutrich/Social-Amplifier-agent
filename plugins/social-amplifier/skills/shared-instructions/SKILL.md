---
name: shared-instructions
description: Core voice rules, anti-AI patterns, and mandatory pre-writing steps for all Social Amplifier content agents. Injected at startup via skills field.
disable-model-invocation: true
---

# Shared Agent Instructions

> Injected into all content-producing agents at startup.

## Before Writing (MANDATORY)

```
Read(file_path="shared/anti-ai-tells.md")
Read(file_path="shared/platform-rules.md")
```

Then load the champion's voice:
```
Read(file_path="champions/{champion_id}/tone-of-voice.md")
Read(file_path="champions/{champion_id}/rules.md")
```
