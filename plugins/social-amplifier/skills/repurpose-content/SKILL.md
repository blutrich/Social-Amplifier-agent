---
name: repurpose-content
description: |
  Transforms a Slack announcement, feature description, or existing content into a personal social post.
  Takes source material + champion context, finds the personal angle, generates variations.

  Triggers on: repurpose, turn this into, from slack, make a post from, rewrite as.
---

# Content Repurposing Skill

## Process

### Step 1: Load Champion + Source

```
Read(file_path="champions/{champion_id}/profile.json")
Read(file_path="champions/{champion_id}/tone-of-voice.md")
```

Source material comes from:
- Pasted Slack message
- Output from scan-slack skill
- Any text the user provides

### Step 2: Find the Personal Angle

The source material is usually corporate or technical. The job is to find THIS champion's personal angle:

1. What's the champion's connection to this feature/topic? (based on role and interests)
2. What would they personally find interesting about it?
3. How would they explain it to their network?

**Critical:** The output must NOT sound like a rewritten press release. It must sound like the champion spontaneously decided to share their take.

### Step 3: Generate Angle Options

Present 2-3 angle options before generating full content:

```
## Repurposing Angles for {Name}

**Source:** {brief summary of source material}

### Option A: Personal Take
{1-sentence description of the personal experience angle}
Example hook: "{first line preview}"

### Option B: Industry Analysis
{1-sentence description of the broader industry angle}
Example hook: "{first line preview}"

### Option C: How-To / Tutorial
{1-sentence description of the practical/educational angle}
Example hook: "{first line preview}"

Which angle would you like me to develop into a full post?
```

### Step 4: Generate Full Content

Once the user picks an angle, route to content-specialist agent with:
- The source material
- The chosen angle
- The champion's profile and tone-of-voice

The content-specialist generates 3 variations as usual.

### Step 5: Voice Guardian

All variations pass through Voice Guardian. Extra scrutiny on "not corporate" check since source material is corporate.
