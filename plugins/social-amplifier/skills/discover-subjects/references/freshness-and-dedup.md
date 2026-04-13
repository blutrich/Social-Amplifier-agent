# Freshness and Deduplication Rules

Phase 3 of `discover-subjects` filters the raw candidate pool down to subjects that are (a) fresh enough to matter and (b) not duplicates of things the champion already posted. This reference documents the exact rules so scoring stays consistent across discovery runs.

## Freshness Windows

### Primary Window (Default)

For most personas, the primary freshness window is **72 hours**. Anything older than 3 days is treated as stale for news-type subjects.

| Persona | Primary Window | Rationale |
|---------|---------------|-----------|
| comms | 24 hours | Crisis + industry narratives age out fast |
| marketing | 48 hours | Competitor moves still relevant after 2 days |
| dev | 72 hours | Technical discussions compound slower |
| product | 7 days | User feedback doesn't age out |
| founder | 24 hours | Founder voice should be early on narratives |
| builder_indie | 48-72 hours | Builder-in-public allows slightly delayed takes |
| ops | 7 days | Infrastructure subjects evergreen |

### Extended Window (When Primary Is Empty)

If primary window returns fewer than 3 candidates, the skill automatically retries with an extended window:

- comms: extend to 48 hours
- marketing: extend to 7 days
- dev: extend to 7 days
- product: extend to 14 days
- founder: extend to 48 hours
- builder_indie: extend to 7 days
- ops: extend to 14 days

When extended window is used, mark subjects with `freshness.status: "extended"` in the output so downstream consumers know the signal is weaker.

### Evergreen Subjects

Some subjects don't age out and stay interesting indefinitely:

- Architecture patterns (e.g., "why I built X this way")
- Philosophical takes (e.g., "the question isn't X, it's Y")
- Retrospectives (e.g., "what I learned after 70 days of Y")

These get marked `freshness.status: "evergreen"` and skip the age filter entirely. Detection: look for specific linguistic patterns in the mention body:

```python
EVERGREEN_PATTERNS = [
    "why I built",
    "the question isn't",
    "what I learned after",
    "the real reason",
    "I stopped doing",
    "I started doing",
    "lessons from"
]
```

If the mention body matches any pattern, tag it evergreen regardless of age. Use this sparingly — most subjects aren't evergreen, and flagging them all as such defeats the filter.

## Deduplication Against Content History

### The Dedup Window

Check the last **30 days** of the champion's content-history. Anything the champion posted about in those 30 days is a potential duplicate.

Rationale: 30 days is long enough to avoid looking repetitive, short enough to allow revisiting genuine evergreen topics after a month.

Configurable per call via `--dedup-days=N` when invoked manually. Default is 30.

### Content History Indexing

Each delivery log in `content-history/YYYY-MM-DD-{slug}.md` has frontmatter with:

```yaml
---
date: 2026-04-13
topic: ai-agent-infrastructure
topic_source: octolens
---
```

Plus the full draft text in the body. The dedup check has two layers:

**Layer 1: Topic slug match (fast)**
Compare the candidate subject's topic slug against all `topic` fields from the last 30 days. Exact match = duplicate.

**Layer 2: Semantic similarity (thorough)**
For subjects that don't match any topic slug exactly, check keyword overlap between the candidate subject body and each historical draft body. If >60% of the candidate's keywords appear in a historical draft, flag as "similar-topic-older".

### Dedup Status Values

Each candidate gets one of these dedup status values:

- `clean` — No similar history in the last 30 days. Full originality score.
- `similar-topic-older` — Similar topic covered 30+ days ago. Can revisit with updated angle.
- `similar-topic-recent` — Similar topic covered in the last 30 days. Filter out unless angle is materially different.
- `exact-duplicate` — Identical subject already covered. Always filter out.
- `angle-adjacent` — Same topic, clearly different angle. Can proceed.

### Angle-Aware Dedup

A subject can share a topic with a recent post but still be valuable if the angle differs. The dedup check needs to consider angles, not just topics.

**Example:**
- Recent post (2 days ago): "I built a Voice Guardian for my internal tool" (personal-experience angle)
- Candidate subject: "The Voice Guardian turned out to be the whole product" (architecture-reframe angle)
- Dedup status: `angle-adjacent`, proceed with score adjustment

Detection: look at the `angle_template` field in historical content-history files. If the historical post had `angle_template: personal-experience` and the candidate suggests `angle_template: architecture-reframe`, that's a different angle — proceed.

```python
def dedup_check(candidate, history_entries):
    for entry in history_entries:
        topic_similarity = keyword_overlap(candidate.body, entry.topic)
        if topic_similarity > 0.6:
            if entry.angle_template == candidate.angle_template:
                return "similar-topic-recent"  # same topic AND angle
            else:
                return "angle-adjacent"  # same topic, different angle
    return "clean"
```

## Language Filtering

Subjects in languages the champion doesn't write in get filtered out. Check `profile.json.platforms` and `profile.json.uses_hebrew_on_linkedin` (or equivalent language flags):

```python
if champion.uses_hebrew_on_linkedin:
    allowed_languages = ["english", "hebrew"]
else:
    allowed_languages = ["english"]

filtered = [m for m in mentions if m.language in allowed_languages]
```

For bilingual champions, allow both but prefer the primary publication language. For English-only champions, filter out Hebrew/other mentions entirely — they can't write about a Hebrew-only source.

### Exception: Cross-Lingual Topics

If a Hebrew mention is about a topic the English-writing champion cares about (e.g., Maor posting in Hebrew about a Base44 feature), allow it but note `language_original: hebrew` in the candidate so the content-specialist knows to translate context.

## Quality Filters

Beyond freshness and dedup, filter out mentions that are structurally low-quality:

### Filter A: Promotional spam
- `tag: promotional_post` in OctoLens → drop
- Body contains only a link + "check it out" → drop
- More than 3 hashtags → drop (signals spam)

### Filter B: AI-generated content
- `tag: ai_generated` in OctoLens → drop
- Body opens with "In today's fast-paced..." → drop
- Body contains 3+ em dashes in first 100 words → drop (AI tell)

### Filter C: Noise
- Body under 20 words → drop (not substantive)
- Body is only a question → drop (not a subject, just a prompt)
- Body is a retweet/share with no original commentary → drop

### Filter D: Competitor amplification
Per the `inspiration-seeds.json` banned list:
- If mention author is on the banned list (Amjad Masad, Anton Osika, etc.) → drop
- If mention is a direct promotion of a banned competitor product → drop
- Mentions of competitors in analytical contexts (Aakash Gupta writing about all vibe-coding startups) are fine

## Filter Order and Efficiency

Apply filters in this order (cheapest first, expensive last):

1. Language filter (string comparison, instant)
2. Filter C: Noise (body length, structural check)
3. Filter A: Promotional spam (tag check)
4. Filter B: AI-generated (tag check)
5. Filter D: Competitor amplification (author lookup)
6. Topic match pre-filter (keyword check, drop if zero match)
7. Freshness filter (timestamp comparison)
8. Dedup check (requires reading content-history files, slowest)

Order matters because the dedup check (8) is the most expensive — it reads multiple files from disk. Applying the cheap filters first (1-7) reduces how many candidates hit the dedup check.

Expected reduction per filter (rough estimates):

| Filter | Typical Candidates Removed |
|--------|--------------------------|
| Language | 5-15% |
| Noise | 10-20% |
| Promotional spam | 15-25% |
| AI-generated | 5-10% |
| Competitor amplification | 2-5% |
| Topic pre-filter | 40-60% |
| Freshness | 10-30% |
| Dedup | 10-25% |

Starting from 50 raw mentions, expect to end with 5-15 candidates after full filtering. If you end with 0-2, widen the freshness window and retry.

## When Dedup Returns "All Duplicates"

If the champion has been posting frequently and every fresh mention is a duplicate of recent content, the skill should return:

```yaml
status: weak_signal
weak_signal_reason: |
  All fresh mentions are duplicates of content the champion posted in the last {N} days.
  This champion is posting faster than the signal pool refreshes.
recommendations:
  - "Slow the posting cadence for 2-3 days to let fresh subjects accumulate"
  - "Widen the freshness window to 14 days for less-recent subjects"
  - "Extend dedup window analysis to weekly — maybe the champion can revisit topics in month+2"
```

Don't force non-duplicate subjects. Better to skip a day than publish something boring.

## Configuration via Operator Commands

Operators can override defaults per-invocation:

- `/discover dor-blech --days=7` — override freshness to 7 days
- `/discover dor-blech --dedup-days=14` — allow re-posting topics older than 14 days
- `/discover dor-blech --include-evergreen` — always include evergreen subjects
- `/discover dor-blech --languages=en,he` — override language filter
- `/discover dor-blech --include-competitors` — temporarily allow banned competitor mentions (not recommended)

All overrides are logged in the output so downstream consumers know what filters were bypassed.
