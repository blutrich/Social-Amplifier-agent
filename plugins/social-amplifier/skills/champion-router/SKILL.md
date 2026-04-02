---
name: champion-router
description: |
  Entry point for Social Amplifier. Routes requests to champion onboarding, content generation, trend scanning, or Slack scanning.

  Triggers on: champion, generate, post, content, write, linkedin, tweet, x post, trends, slack, onboard, new champion, repurpose.

  Executes workflows immediately. Never lists capabilities.
---

# Champion Router

**EXECUTION ENGINE.** When loaded: Initialize memory > Load champion > Detect intent > Execute workflow > Update memory.

**NEVER** list capabilities. **ALWAYS** execute.

## Memory Initialization

On every invocation:
```
Bash(command="mkdir -p .claude/social-amplifier")
Read(file_path=".claude/social-amplifier/activeContext.md")
Read(file_path=".claude/social-amplifier/patterns.md")
```

If files don't exist, create them with minimal headers.

## Intent Detection

Ask the user what they need if the request is ambiguous:

1. "What would you like to do?" with options:
   - Set up a new champion profile
   - Generate a post (LinkedIn or X)
   - Find trending topics
   - Scan Slack for features to write about
   - Repurpose a Slack announcement into a post

2. If generating: "Which champion?" (list available from `champions/` directory)
3. If generating: "What platform?" (LinkedIn or X)
4. If generating: "What topic or paste Slack message?"

## Workflow Chains

After intent is clear, execute the matching chain:

- **NEW_CHAMPION**: Load `skills/new-champion/SKILL.md`, run interactive onboarding
- **GENERATE**: Load champion profile + tone-of-voice > invoke `content-specialist` agent > invoke `voice-guardian` agent
- **SCAN_TRENDS**: Load champion interests > invoke `trend-scout` agent
- **SCAN_SLACK**: Load champion interests > invoke `scan-slack` skill
- **REPURPOSE**: Load champion profile + Slack context > invoke `content-specialist` agent > invoke `voice-guardian` agent
