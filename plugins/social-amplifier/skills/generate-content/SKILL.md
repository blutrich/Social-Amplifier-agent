---
name: generate-content
description: |
  Content generation pipeline for champions. Loads profile, generates 2-3 variations with different angles, passes through Voice Guardian.

  Triggers on: generate, write post, create content, linkedin post, tweet, thread, new post.
---

# Content Generation Pipeline

## Inputs Required

1. **champion_id** - Which champion (resolved by router)
2. **platform** - "linkedin" or "x" (ask if not specified)
3. **topic** - What to write about. Can come from:
   - User-provided topic
   - Slack message (from scan-slack)
   - Trending topic (from scan-trends)
   - Freeform brief

## Pipeline

### Step 1: Load Champion Context

```
Read(file_path="champions/{champion_id}/profile.json")
Read(file_path="champions/{champion_id}/tone-of-voice.md")
Read(file_path="champions/{champion_id}/rules.md")
Read(file_path="shared/anti-ai-tells.md")
Read(file_path="shared/platform-rules.md")
```

### Step 2: Determine Topic

If topic not provided, ask:

"What do you want to post about? Options:
- Paste a Slack message or announcement
- Describe a topic or experience
- I can scan Slack for recent features (/scan-slack {champion_id})
- I can find trending topics (/scan-trends {champion_id})"

### Step 3: Generate Variations

Generate 3 variations with different angles:

**Variation A: Personal Experience**
- Frame as "I did/saw/learned X"
- Include a specific detail or anecdote
- End with an insight, not a CTA

**Variation B: Industry Insight**
- Frame as "Here's what I think about X in the industry"
- Reference the champion's expertise area
- Take a stance (not fence-sitting)

**Variation C: Product/Feature Angle**
- Frame as "I helped build/use X at work"
- Personal pride or surprise about the outcome
- Not corporate marketing - personal reaction

Apply platform-specific formatting from platform-rules.md.

### Step 4: Voice Guardian

Pass all 3 variations to the voice-guardian agent for quality check.

If any variation scores <7: regenerate that variation from scratch.
If any variation scores 7-8: auto-rewrite with Voice Guardian feedback.
If variation scores 9+: approved, present to user.

### Step 5: Present Results

Show all approved variations to the user. Ask which one they want to use (or if they want edits).

### Step 6: Log

Save the chosen variation (or all if user wants them) to content history:
```
Write(file_path="champions/{champion_id}/content-history/YYYY-MM-DD-{topic-slug}.md",
      content="---\ndate: YYYY-MM-DD\nplatform: {platform}\ntopic: {topic}\nchosen: {A/B/C}\nscore: {guardian_score}\n---\n\n{post content}")
```
