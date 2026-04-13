# Universal AI Tells - The Always-Banned List

These are patterns that make text sound AI-generated regardless of who's writing. They're the baseline rules every piece of content must pass. Per-champion style preferences can override SOME of these (see `champions/{id}/style-preferences.md`), but the rules marked **[HARD BAN]** cannot be overridden — they're universal tells that even a natural writer shouldn't use.

## Banned Verbs

leverage, utilize, craft (metaphorical), empower, streamline, curate, facilitate, harness, spearhead, pioneer, navigate (metaphorical), elevate, foster, cultivate, optimize, revolutionize, transform, drive (metaphorical), unlock, supercharge, catalyze, amplify (metaphorical), orchestrate, synergize, reimagine, democratize, delve, dive into, tapestry, weave, journey (metaphorical)

**Use instead:** use, help, write, let, simplify, pick, make easier, lead, find, improve, grow, build, explore, try

**Why banned:** These verbs are disproportionately used by LLMs because they're "impressive-sounding" neutral-positive vocabulary. Real writers reach for more specific, concrete words. "Leverage our platform" has no meaning — "use our platform" does.

## Banned Adjectives

groundbreaking, seamless, robust, transformative, unprecedented, innovative, cutting-edge, game-changing, best-in-class, world-class, state-of-the-art, next-generation, disruptive, holistic, synergistic, bespoke, turnkey, scalable (when used metaphorically, not infrastructurally), actionable, impactful, pivotal, mission-critical, enterprise-grade

**Use instead:** say what you actually mean specifically. Instead of "a groundbreaking new feature," say "a feature that lets you X."

**Why banned:** These are marketing adjectives that signal "I am trying to impress you" without conveying information. Real writers describe what something does, not how important it is.

## Banned Adverbs

significantly, dramatically, fundamentally, incredibly, remarkably, ultimately, essentially, literally (when not literal), absolutely, undoubtedly, definitively, surely, clearly (when used for emphasis)

**Why banned:** Intensifier adverbs are filler. "Significantly faster" is almost always wrong — either say how much faster, or don't qualify.

## Banned Phrases

**Filler openings:**
- "In today's [fast-paced/rapidly-evolving/digital/modern] world"
- "In the age of AI"
- "As we all know"
- "At the end of the day"
- "When it comes to..."

**Self-narration:**
- "Here's the thing"
- "Let me tell you"
- "Here's why this matters:"
- "Think about it"
- "Let that sink in"
- "Read that again"
- "Full stop."
- "Period." (as standalone emphasis)

**Contrast framing [HARD BAN]:**
- "It's not just X, it's Y"
- "This isn't a [thing], it's a [bigger thing]"

**Corporate announcement phrases [HARD BAN]:**
- "I'm excited to announce"
- "Thrilled to share"
- "Proud to announce"
- "Delighted to reveal"
- "Without further ado"

**Cliches:**
- "Game changer"
- "Deep dive"
- "Moving the needle"
- "Low-hanging fruit"
- "The future of X is Y"
- "This changes everything"
- "Paradigm shift"
- "At scale"
- "Best practices"

**Engagement bait [HARD BAN]:**
- "What would you build?"
- "Thoughts?"
- "Agree or disagree?"
- "Like if you agree"
- "Share if this resonates"

**Fake vulnerability [HARD BAN]:**
- "Honestly wasn't sure..."
- "Not gonna lie..."
- "I'll be real with you..."
- "Between you and me..."
- "I have to admit..."

## Banned Structures

### Em Dashes
**Default: banned.** Em dashes (—) are one of the strongest AI tells in 2026. Use commas, periods, or parentheses instead.

**Override:** Per-champion `style-preferences.md` can set `em_dashes: allow` if the champion naturally uses em dashes in their real writing. When this override is set, em dashes pass this check for that champion only.

### Rule of Three
**Default: banned.** Triples like "Fast. Simple. Powerful." or "One workspace. Unlimited builders. No friction." are a strong AI tell. 

**Exception:** Lists of three concrete examples with elaboration are fine. "I saw a CS:GO randomizer, a protocol on Ethereum, and a Spanish-learning game" is a list of examples, not a rule-of-three pattern. The banned pattern is specifically the punchy-three-word-sentence cadence.

### Numbered lists as the entire post body
A post that's just "1. Point one. 2. Point two. 3. Point three." without any prose connecting them reads as AI listicle output.

### Emoji bullets
Using 🚀 or 💡 or ✅ as list markers instead of normal bullets. Always fails.

### More than 2 emojis per post
Even natural writers who use emojis don't spray them across a post. Max 2, placed at natural emphasis points.

### Hashtag collections
More than 2 hashtags. #productivity #mindset #entrepreneurship #leadership #innovation = instant fail on LinkedIn.

### Thread numbering on LinkedIn
"1/ Here's the first point. 2/ Here's the second..." This is X/Twitter convention. On LinkedIn it looks like someone copy-pasted a tweet thread.

### Transition openers
"Here's what I learned.", "Here's what happened next.", "Here's the wild part." — these are AI self-narration. Real writers just... tell you the next thing, without announcing the transition.

## Summary Table: Per-Champion Overrides

Some rules are universal. Others can be relaxed per-champion based on their actual writing:

| Rule | Default | Overridable? | Override key in style-preferences.md |
|------|---------|--------------|--------------------------------------|
| Banned verbs | Banned | ❌ No | N/A |
| Banned adjectives | Banned | ❌ No | N/A |
| Em dashes | Banned | ✅ Yes | `em_dashes: allow` |
| Rule of three | Banned | ❌ No | N/A |
| Corporate announcement phrases | Banned | ❌ No | N/A (hard ban) |
| Engagement bait | Banned | ❌ No | N/A (hard ban) |
| Contrast framing | Banned | ❌ No | N/A (hard ban) |
| Emoji count (max 2) | Max 2 | ✅ Yes | `emoji_max: N` (where N ≤ 5) |
| Hashtag count (max 2) | Max 2 | ✅ Yes | `hashtag_max: N` |
| Bulleted lists in posts | Allowed | ✅ Yes | `bullets: heavy` / `light` / `none` |

## How the Voice Guardian Uses This File

When scoring content:

1. Check for banned verbs — flag any match as item 1 FAIL
2. Check for banned adjectives/adverbs — flag as item 1 FAIL
3. Check for banned phrases (especially hard-ban ones) — flag as item 3 FAIL
4. Check for banned structures (em dashes, rule-of-three, etc.) — flag as item 2 FAIL, UNLESS the champion's `style-preferences.md` overrides it

Hard-ban items cannot be overridden. Universal structural bans can be.
