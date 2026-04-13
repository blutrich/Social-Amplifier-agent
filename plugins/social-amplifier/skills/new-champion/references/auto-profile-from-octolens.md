# Auto-Profiling from OctoLens & Social Platforms

How to enrich a champion's voice profile with data from LinkedIn, X, and other public social platforms. This runs after (or alongside) Slack profiling and adds the "polished public voice" layer to the "unfiltered private voice" captured from Slack.

## Why Public Social Data Matters

Slack gives you the real voice. Public social adds three things Slack can't:

1. **How they ACTUALLY post in public.** If someone writes raw Slack dumps but polished LinkedIn thought pieces, you need to see both.
2. **Their past posts as training data.** Existing LinkedIn posts become direct samples for the Voice Guardian's tone-matching check.
3. **Their engagement patterns.** Which topics got responses? Which formats landed? This feeds into content-specialist's angle selection.

## Required MCPs

- **OctoLens MCP** (preferred): Pre-indexed, tagged, sentiment-scored social mentions across 15+ platforms
- **WebFetch** (fallback): Direct LinkedIn/X URL fetching when OctoLens doesn't have the champion indexed

If neither is available, skip this profiling path and rely on Slack-only analysis.

## Step 1: Check If the Champion Is Indexed in OctoLens

OctoLens tracks keywords, not people. For champions who are also Base44 employees, they often appear in OctoLens data as AUTHORS of posts about Base44-related topics.

Query mentions where the author matches the champion:

```
mcp__octolens__list_mentions(
  filters={
    "startDate": "2025-10-01T00:00:00Z"
  },
  limit=100
)
```

Then filter results by `author` field matching the champion's known handles. Handles to check:
- LinkedIn display name
- Twitter/X username (without @)
- GitHub username
- Reddit username
- Dev.to username

If OctoLens returns hits, great — that's a ready-made corpus of the champion's public posts with sentiment, tags, and engagement data.

## Step 2: Fall Back to LinkedIn Profile Fetching

LinkedIn blocks most automated fetches (WebFetch returns 999 or redirects to login). Expect this to fail for most champions. If it does fail:

1. Ask the operator: "Does {name} have any public LinkedIn posts? If yes, paste 2-3 recent ones as text."
2. If the operator can provide them, treat them as writing samples
3. If not, rely on Slack-only profiling and mark the profile as "Slack-only" with a note to refresh later

## Step 3: Fall Back to X (Twitter) via OctoLens or Direct

X is more fetch-friendly than LinkedIn. Options:

1. **OctoLens query** with the X handle as a filter
2. **Direct tweet URLs** via WebFetch if the operator provides them
3. **Search X for the handle** via OctoLens (they index Twitter broadly)

Extract the last 20-50 tweets by the champion. Filter to substantive ones (not replies, not retweets without commentary).

## Step 4: Analyze Public Social Samples

Run the same analysis patterns from `auto-profile-from-slack.md` on the social samples, but note the differences between public and private voice:

### Voice Delta Analysis
Compare the champion's Slack voice against their LinkedIn/X voice. Most people are slightly different across contexts. Record the delta:

- **Slack:** Casual, unfiltered, technical, uses Hebrew
- **LinkedIn:** Polished, English-only, 2-3 paragraphs max, 1 emoji
- **X:** Punchy, opinionated, 280-char-disciplined, 2-3 emojis

This delta becomes a key input to the content-specialist: when generating LinkedIn content, match the LinkedIn voice. When generating X, match the X voice. Don't apply Slack voice to LinkedIn or you'll produce cringey over-casual content.

### Engagement Signal
For posts that got high engagement (likes, comments, reposts), note:
- What topic?
- What angle?
- What structure?
- What emotion?

These successful posts are the highest-quality voice samples — they prove the champion's voice landed when written this way. The Voice Guardian should use them as tone-match anchors.

## Step 5: Pull Specific LinkedIn/X Posts via OctoLens Analytics

If the champion has significant OctoLens presence, use the analytics tool to query their post patterns:

```
mcp__octolens__analytics(
  query="SELECT source, COUNT(*) as count, AVG(engagement) as avg_engagement FROM posts WHERE author = '{handle}' GROUP BY source ORDER BY count DESC"
)
```

This gives you:
- Which platforms they post on most
- Which platforms get the most engagement
- Posting frequency over time

Use this to populate `profile.json.platforms` accurately. Don't assume every champion wants content for both LinkedIn and X — some only use one.

## Step 6: Enrich tone-of-voice.md with Public Samples

Add a "Public Voice Samples" subsection to `tone-of-voice.md` under "Style References":

```markdown
## Style References

### Private Voice (from Slack)
Sample 1 (from Slack DM, 2026-04-12):
> [Real quote]

### LinkedIn Voice (public)
Sample 1 (LinkedIn post, 2026-03-28, 47 reactions):
> [Real quote from their actual LinkedIn post]

### X Voice (public)
Sample 1 (X, 2026-04-02, 12 retweets):
> [Real tweet]
```

Label each sample with platform + date + engagement. This gives the Voice Guardian explicit tone anchors for each platform.

## Step 7: Enrich inspirations.md with Who They Follow

If we have OctoLens data, we can often see who the champion engages with (replies to, quotes, mentions). These people are implicit inspirations — the champion interacts with their content, which means their voice patterns influence the champion's own voice.

For each top-5 person the champion engages with:
1. Fetch their public posts via OctoLens or WebFetch
2. Extract voice signatures (structure, vocabulary, humor)
3. Add to `inspirations.md` with a note on what the champion likely borrows from them

Format:
```markdown
## People This Champion Engages With

### @[handle] — [Name if known]
**Voice signature:** [short summary of their distinctive style]
**What this champion borrows:** [specific pattern, e.g., "short-sentence hooks" or "TL;DR format"]
**Engagement pattern:** [how often they reply/retweet, what topics trigger engagement]
**Sample post:**
> [quote]
```

## What to Skip If Data Is Sparse

Not every champion has a rich LinkedIn history. Common scenarios:

### Scenario: Champion has 0 LinkedIn posts
- Skip the "LinkedIn Voice" section of tone-of-voice.md
- Mark the profile as "LinkedIn cold-start" — the first generated posts will be based purely on Slack voice extrapolated to LinkedIn format
- Set `platforms: ["linkedin"]` anyway — we're trying to get them posting, even from zero
- The Voice Guardian will be more lenient on first posts, knowing the Slack→LinkedIn voice translation is a guess

### Scenario: Champion has private Twitter/X
- Skip X analysis
- Set `platforms: ["linkedin"]` only (don't try to generate X content)
- Add a note to `tone-of-voice.md`: "X account is private, not profiled"

### Scenario: Champion is in Hebrew only
- Skip LinkedIn analysis (LinkedIn is English-dominant for Israeli tech)
- Keep Slack Hebrew samples for future Hebrew content generation
- Set `uses_hebrew: true` in style-preferences.md
- Note: Content-specialist will generate English posts for LinkedIn even if champion writes Slack in Hebrew, matching the LinkedIn format norm

### Scenario: Champion is verbose on X but minimal on LinkedIn
- Weight X voice samples heavily
- For LinkedIn generation, extrapolate from X voice (shorter → longer, more structured)
- Mark LinkedIn output as experimental until the champion reviews and gives feedback

## Integration With Slack Profiling

The two profiling paths (Slack and OctoLens) should run in parallel during onboarding, not sequentially. Slack gives the unfiltered voice, OctoLens gives the public voice. Both feed into the same `tone-of-voice.md` and `style-preferences.md` files.

When the two sources conflict:
- **For vocabulary:** Trust Slack (more volume, more authentic)
- **For structural patterns:** Trust the platform-specific source (LinkedIn patterns from LinkedIn samples, X patterns from X samples)
- **For topics:** Merge both, prefer topics that appear in both sources
- **For formality:** Use both — Slack = private voice, public platforms = public voice

The resulting profile captures how the champion writes differently across contexts, which is exactly what the content-specialist needs to generate platform-appropriate content.

## Validation

After public social profiling:

1. Pick one of the champion's real LinkedIn posts
2. Run it through the Voice Guardian
3. Does it score 9+/10?
4. If yes: the profile is dialed in. Real posts from the champion pass their own voice check.
5. If no: the profile missed some patterns. Iterate.

This is the best validation available — testing against the champion's actual public writing.

## Output

Data added to the champion profile:

```
champions/{champion_id}/
├── tone-of-voice.md              (now includes public voice samples)
├── inspirations.md                (now includes who they engage with)
├── style-preferences.md           (em_dashes, emoji count, etc. refined from public posts)
└── profile.json                   (platforms array refined based on actual usage)
```

Combined with the Slack profiling output, this gives the content-specialist everything it needs to generate content that sounds like the champion on the right platform.
