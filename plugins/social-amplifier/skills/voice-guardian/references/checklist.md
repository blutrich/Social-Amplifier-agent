# Voice Guardian Checklist

The 10-point scoring checklist used to evaluate generated content before delivery. Each item scores PASS (1) or FAIL (0). Total = score out of 10.

## How to Use This Checklist

Load this file when scoring a piece of content. For each of the 10 items, read the check criteria, inspect the content, and assign PASS or FAIL with a short note explaining why. The notes matter — they drive the auto-rewrite decision and feed back into the champion's `rules.md` when corrections happen.

Don't skim. A rubber-stamp PASS on all 10 is almost always wrong — AI content usually fails on items 1-3 in subtle ways that are easy to miss.

---

## Section A: Anti-AI Tells (3 items)

These check for universal patterns that make text sound AI-generated regardless of who's writing. Load `universal-ai-tells.md` for the full banned word and pattern lists.

### 1. No AI Vocabulary
**Check:** Does any word in the content appear in the banned verb, adjective, or adverb lists from `universal-ai-tells.md`?

**Fail examples:**
- "We leverage AI to streamline your workflow" (leverage + streamline)
- "A truly transformative experience" (transformative)
- "Significantly improves your output" (significantly)

**Pass examples:**
- "We use AI to make your workflow simpler"
- "A different kind of experience"
- "Makes your output faster and more accurate"

**Edge case:** Meta-references are allowed. Writing ABOUT the word "leverage" as an example of AI vocabulary is fine — using it as your own word is not.

### 2. No AI Structure
**Check:** Does the content use any banned structural patterns — em dashes, rule-of-three cadence, self-narration, contrast framing, transition openers, significance inflation?

**Fail examples:**
- "Fast. Simple. Powerful." (rule of three)
- "It's not just a tool — it's a revolution" (contrast framing + em dash)
- "Here's why this matters:" (self-narration)
- "A testament to modern design" (significance inflation)

**Pass examples:**
- "Here's what it does: it makes you faster at the stuff you already do." (direct, no drama)
- "It's a tool. It helps you build things." (simple declarative)

**Edge case:** Per-champion overrides can allow em dashes if the champion uses them naturally. Check `champions/{id}/style-preferences.md` for `em_dashes: allow`.

### 3. No AI Phrases
**Check:** Does the content use common AI-generated phrases from `universal-ai-tells.md`?

**Fail examples:**
- "I'm excited to announce..."
- "In today's fast-paced world..."
- "Let that sink in"
- "Read that again"
- "This changes everything"

**Pass examples:**
- Opens with a specific fact, number, or observation
- Ends with an insight, not a catchphrase

---

## Section B: Personal Voice (4 items)

These check whether the content matches THIS specific champion. Load the champion's `tone-of-voice.md`, `profile.json`, and `style-preferences.md` before scoring.

### 4. Matches Champion's Tone
**Check:** Compare the content's vocabulary, sentence length, energy, and humor against the champion's `tone-of-voice.md`. Does it sound like them?

**How to evaluate:**
- Read 2-3 of the champion's real writing samples from `tone-of-voice.md`
- Compare sentence structure: are they long? short? punchy? meandering?
- Compare vocabulary: technical? casual? slang? academic?
- Compare energy: measured? excited? skeptical? enthusiastic?

**Fail:** The content sounds like a generic "tech professional" voice that could be anyone.

**Pass:** You can picture this specific person saying these exact words.

### 5. Uses Champion's Topics
**Check:** Is the content within the champion's declared interest areas from `profile.json.topics`?

**Example:** If the champion's topics are ["developer tools", "AI infrastructure", "team productivity"], a post about fashion trends fails. A post about how AI tools affect developer workflow passes.

**Edge case:** Off-topic content can pass IF the champion explicitly wrote about it recently (as shown in their Slack/LinkedIn history). Check before rejecting.

### 6. Feels Personal
**Check:** Does it include a specific detail, anecdote, number, or personal perspective? Generic content fails.

**Fail examples:**
- "AI is changing how we build software" (generic, could be anyone)
- "Teamwork makes the dream work" (nothing personal)

**Pass examples:**
- "Spent 3 days this week on the Reputation Drop campaign. The math was interesting: 8,000 users, 120 req/min Printful rate limit..." (specific)
- "I've been in comms for 12 years. The last 6 months are the strangest..." (personal)

### 7. The {Name} Test
**Check:** Would this champion actually copy-paste this into their LinkedIn and hit post without editing?

**This is the most important check.** It's a holistic judgment, not a rule. Ask:
- Would they use these words?
- Would they take this angle?
- Would they feel comfortable attaching their name to this?
- If their most honest friend read this, would they say "yep, that sounds like you"?

**Fail:** "It's fine but I'd probably tweak it."
**Pass:** "Yes, I'd post this."

---

## Section C: Platform Format (2 items)

Load `platform-rules.md` for the full format specifications.

### 8. Correct Format
**Check:** Does the content match the target platform's format rules?

**LinkedIn:**
- 150-300 words (optimal engagement range)
- Short paragraphs (1-3 sentences each)
- Line breaks between paragraphs
- Hook in first 2 lines (before "see more" fold)

**X (Twitter):**
- Single tweet: 280 chars maximum
- Thread: numbered tweets, max 7, each under 280 chars
- Thread hook must work standalone

**Fail:** LinkedIn post that's 500 words with no line breaks. X thread that's 15 tweets long.
**Pass:** LinkedIn post that's 200 words with short paragraphs and a hook in the first line.

### 9. No Link/Emoji Violations
**Check:**
- LinkedIn: no external links in main post body (put in first comment if needed)
- Max 2 emojis per post
- No emoji bullets
- No hashtag collections (max 2 hashtags, at end only)

**Fail:** Post opening with "🚀 Exciting news 💡 I've been 🔥 working on..."
**Pass:** Post with one emoji used at a natural emphasis point, no links in body, no hashtag spam.

---

## Section D: Independence (1 item)

### 10. Not Corporate
**Check:** Does the content sound like a Base44 press release, marketing campaign, or brand account post?

**Fail examples:**
- "We're thrilled to announce our latest innovation..."
- "Base44 is revolutionizing the way developers..."
- "Join us as we transform the future of software..."

**Pass examples:**
- "I built X this week. Here's what I learned..." (first person)
- "Talking to users yesterday, I noticed..." (personal observation)
- "My team shipped Y and I keep thinking about Z..." (individual voice)

**The rule:** Champions are individual people with individual voices. Even when they're talking about company work, they should sound like themselves, not like the brand account.

---

## Scoring Output

After checking all 10 items, output the result using this exact structure:

```
## Voice Guardian Review

**Champion:** {name}
**Platform:** {platform}
**Score:** {X}/10

### Checklist
1. No AI vocabulary: PASS/FAIL - {notes}
2. No AI structure: PASS/FAIL - {notes}
3. No AI phrases: PASS/FAIL - {notes}
4. Matches tone: PASS/FAIL - {notes}
5. Champion topics: PASS/FAIL - {notes}
6. Feels personal: PASS/FAIL - {notes}
7. The {Name} Test: PASS/FAIL - {notes}
8. Correct format: PASS/FAIL - {notes}
9. No link/emoji violations: PASS/FAIL - {notes}
10. Not corporate: PASS/FAIL - {notes}

### Verdict: APPROVED / REWRITE / REJECT
{If REWRITE: list the specific items to fix}
{If REJECT: explain what went wrong and what the content-specialist should change}
```

## Thresholds

- **9-10/10:** APPROVED. Ship it.
- **7-8/10:** AUTO-REWRITE. Fix only the failing items, preserve everything that passed, re-score.
- **Below 7:** REJECT. Send back to content-specialist with feedback. Do not attempt to rewrite.
