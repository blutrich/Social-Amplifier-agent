---
name: new-champion
description: |
  Interactive onboarding flow that builds a champion's personal profile.
  Walks through 8 steps: name, role, interests, inspirations, writing samples, content preferences, confirmation, tone generation.

  Triggers on: new champion, onboard, set up, create profile, /new-champion.
---

# New Champion Onboarding

## Process (8 Steps)

Run each step sequentially. Wait for user input before proceeding.

### Step 1: Name

Ask: "What's your full name?"

Store as `name` in profile.json. Derive `champion_id` as kebab-case (e.g., "Dor Blech" -> "dor-blech").

### Step 2: Role

Ask: "What's your role at Base44? (e.g., Frontend Developer, Product Manager, CEO)"

Store as `role` in profile.json.

### Step 3: Interests Beyond Role

Ask: "What topics interest you beyond your job title? These become your content themes. Examples: UX design, developer tools, AI in production, startup culture, remote work, open source."

Store as `topics[]` array in profile.json. Accept 3-7 topics.

### Step 4: Inspirations - People

Ask: "Name 3-5 people you follow on LinkedIn or X whose content you enjoy. Share their profile URLs if possible."

For each URL provided:
- Use WebFetch to analyze their recent posts
- Extract: posting frequency, typical topics, tone (formal/casual/humorous), post length, use of stories vs data

Store in `inspirations.md` with analysis.

### Step 5: Writing Samples

Ask: "Share 2-3 posts you've written before (LinkedIn, X, blog, anything). If you haven't posted before, share messages from Slack or emails where you explained something you're proud of."

Analyze the samples for:
- Sentence length patterns (short/medium/long)
- Vocabulary level (simple/technical/mixed)
- Humor usage (none/light/frequent)
- Structure preference (story/list/insight)
- Energy level (measured/enthusiastic/intense)
- Use of personal anecdotes (rare/occasional/frequent)

### Step 6: Content Preferences

Ask: "What kind of posts do you want to create? Pick your top 3:"
- Behind-the-scenes of building at Base44
- Industry insights and hot takes
- Personal lessons from your work
- Feature announcements with a personal angle
- Technical deep-dives made accessible
- Career/growth reflections

Store as `content_preferences[]` in profile.json.

### Step 7: Confirmation

Present a summary of everything collected:

```
Here's what I understand about you:

Name: {name}
Role: {role}
Topics: {topics}
Inspirations: {inspirations list}
Writing style: {analysis summary}
Content types: {preferences}

Does this look right? Any corrections?
```

Wait for confirmation. Apply any corrections.

### Step 8: Tone-of-Voice Generation

Using all collected data, generate `tone-of-voice.md`:

```
Read the inspiration analysis + writing samples analysis.
Synthesize into a voice guide that captures THIS person's style.
```

The tone-of-voice.md must include these sections (used as stable anchors for the feedback skill):
- **## Voice Summary** - One sentence, e.g., "A frontend dev who gets excited about clean UX and explains complex things simply"
- **## Tone** - Formal/casual/conversational, energy level
- **## Sentence Patterns** - typical lengths, structures
- **## Vocabulary** - words they actually use, words they avoid
- **## Humor** - how and when they use humor
- **## Topics** - what they write about and their angle on it
- **## What Works** - (empty initially, populated by feedback skill when posts are approved)
- **## Style References** - links to inspirations and their analyzed patterns
- **## The {Name} Test** - "Would {Name} copy-paste this and hit post without editing?"

## Output Files

After all steps, create the champion directory:

```
Bash(command="mkdir -p champions/{champion_id}/content-history")
```

Write these files:

1. `champions/{champion_id}/profile.json`:
```json
{
  "name": "Full Name",
  "champion_id": "kebab-case-id",
  "role": "Role at Base44",
  "topics": ["topic1", "topic2", "topic3"],
  "content_preferences": ["pref1", "pref2", "pref3"],
  "platforms": ["linkedin", "x"],
  "created": "YYYY-MM-DD",
  "version": 1
}
```

2. `champions/{champion_id}/tone-of-voice.md` - Generated voice guide (using the format above)

3. `champions/{champion_id}/inspirations.md` - People they follow + analysis

4. `champions/{champion_id}/rules.md`:
```markdown
# {Name}'s Content Rules

## Always
- Sound like {Name}, not an AI
- Use first person ("I")
- Reference personal experience when possible
- Match energy level: {level}

## Never
- Corporate marketing language
- Base44 press release tone
- Generic motivational content
- Emojis as bullet points

## Avoid
(populated automatically by feedback - specific words, phrases, patterns this champion doesn't like)

## Do More Of
(populated automatically by feedback - patterns and styles that work well for this champion)

## Platform-Specific
- LinkedIn: {their preferred LinkedIn style}
- X: {their preferred X style}
```

## Verification

After creating all files, verify:
```
Read(file_path="champions/{champion_id}/profile.json")
Read(file_path="champions/{champion_id}/tone-of-voice.md")
Read(file_path="champions/{champion_id}/inspirations.md")
Read(file_path="champions/{champion_id}/rules.md")
```

Confirm all files exist and contain valid data. Report to user: "Champion profile created for {name}! You can now run /generate {champion_id} to create content."
