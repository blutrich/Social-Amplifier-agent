# Platform Format Rules

Format specifications for each supported platform. Used by item 8 (Correct Format) in the Voice Guardian checklist.

## LinkedIn

### Format Requirements
- **Length:** 150-300 words (sweet spot for engagement)
- **Paragraphs:** Short (1-3 sentences each), line breaks between
- **Hook:** Must land in first 2 lines (before the "see more" fold)
- **Links:** No external links in main post body — put in first comment if needed
- **Mobile rendering:** Assume readers see it on phone, formatted paragraphs matter

### What Works
- Personal stories with a professional insight
- Behind-the-scenes of building something
- Lessons from specific experiences (not generic advice)
- Contrarian takes backed by personal experience
- "I did X. Here's what happened." format with real details

### What Fails
- Generic motivational content
- Engagement bait ("Like if you agree", "Thoughts?")
- Pure self-promotion without value
- Wall of text with no line breaks
- External links in main post body (kills reach ~50%)
- More than 2 hashtags (signals spam to algorithm)

### Emoji Rules
- Maximum 2 per post
- Never as bullet points
- Only at natural emphasis points
- Approved list: 🎉 🚀 🔥 💡 ✨ 👀 🙏

### Hashtag Rules
- Maximum 2 hashtags
- Only at the end of the post
- Use broad topics, not niche phrases

## X (Twitter)

### Format Requirements
- **Single tweet:** Maximum 280 characters
- **Thread:** Numbered tweets (1/ 2/ 3/), maximum 7 tweets
- **Thread hook:** First tweet must stand alone AND signal the thread (🧵 emoji or "thread 👇")
- **Links:** Avoid in first tweet of a thread (hurts reach)

### What Works
- Sharp observations in 1-2 sentences
- Hot takes with evidence
- "I just [did thing]. [Surprising result]." format
- Threads that tell a story with a payoff
- Replies to trending conversations in your space

### What Fails
- Threads longer than 7 tweets (engagement drops fast after tweet 5)
- Generic advice without specifics
- Pure promotion
- Too many hashtags (max 1-2 on X)
- Engagement bait
- Quote tweets with no added insight

### Emoji Rules
- Maximum 2-3 per tweet
- Approved list: 🧵 (threads), 👇 (thread signal), 🔥 💡 👀 🚀 ✨ 😅

### Thread Structure
```
Tweet 1: [Hook/claim] 🧵
Tweet 2: [Supporting point 1 with specific detail]
Tweet 3: [Supporting point 2 with specific detail]
...
Tweet N: [Payoff/conclusion/link]
```

## Format Detection Logic

When scoring a piece of content:

1. Read the content length in words and characters
2. Check the target platform from the generation request
3. Compare against the rules above
4. Flag specific violations (too long, too short, wrong structure, link in body, emoji overload, etc.)

## Format-Specific Rewrite Rules

If the Voice Guardian has to auto-rewrite for format violations:

### LinkedIn → too long (400+ words)
Cut the middle. Preserve the hook (first 2 lines) and the payoff (last 2-3 lines). Trim supporting detail.

### LinkedIn → too short (under 100 words)
Usually means the content is too sparse. Reject rather than rewrite — ask content-specialist to add a specific example or anecdote.

### LinkedIn → wall of text
Add line breaks between logical sections. Target 1-3 sentence paragraphs.

### X → tweet over 280 chars
First try to shorten by removing filler words and unnecessary qualifiers. If it still won't fit, convert to a 2-tweet thread.

### X → thread too long
Merge redundant tweets. Most threads can be cut by 30-40% without losing substance.

## Platform-Specific Hook Patterns

### LinkedIn (first 2 lines visible before "see more")
**Works:**
- Unexpected number: "$100M ARR. Definitely the fastest without VC backing."
- Specific observation: "Spent 3 days this week debugging something I thought would take 20 minutes."
- Bold opinion: "Unpopular opinion: your AI strategy doesn't need more tools."
- Story opener: "3 years ago I got fired. Best thing that ever happened."

**Fails:**
- Generic questions: "What if I told you..."
- Corporate announcement: "Excited to share..."
- Clickbait numbers: "5 lessons I learned..."

### X (full tweet visible, 280 chars)
**Works:**
- Hot take: "Every vibe coding startup has 90 days to live. They don't."
- Observation: "Spent this week in a vibe coding startup. Here's what the 'ship button' narrative misses:"
- Specific number: "8,000 users. $483K. 120 req/min rate limit. A queue is not optional."

**Fails:**
- Listicle: "5 things I learned this week"
- Generic motivation: "Keep pushing"
- Vague hooks: "Wild week"
