# Subject Output Schema

The structured output format that `discover-subjects` produces. This is the contract between this skill and its consumers (generate-content, scheduled-pipeline, operator-facing commands).

## Primary Output: Subjects Array

The skill returns exactly 5 subjects in a sorted array (highest score first). If fewer than 5 candidates survive filtering, return what's available and flag the weak signal.

### YAML Format

```yaml
status: ok | weak_signal | no_signal | error
champion_id: {kebab-case-id}
discovered_at: {ISO 8601 timestamp}
window_used: primary | extended
sources_queried:
  - octolens_brand_monitoring
  - octolens_industry_insights
  - slack_feature_channels
  - bright_data_inspiration_activity
total_candidates_before_filter: 47
candidates_after_dedup: 18
top_score: 42
subjects:
  - rank: 1
    subject: "One-sentence headline of the subject"
    total_score: 42
    factors:
      topic_match: 9
      recency: 10
      engagement: 8
      inspiration: 7
      originality: 8
    source:
      mention_id: 162839764
      url: "https://..."
      platform: twitter | linkedin | reddit | dev | youtube | podcasts | other
      author: "@handle"
      sentiment: positive | neutral | negative
      engagement_metric: "650 reactions, 42 comments"
      published_at: "2026-04-13T03:47:21Z"
    topic_match_details:
      matched_champion_topics: ["AI agent infrastructure"]
      match_strength: exact | adjacent | tangential
    freshness:
      age_hours: 6
      status: primary | extended | evergreen
    dedup:
      status: clean | similar-topic-older | angle-adjacent
      matched_history_files: []
    inspiration_signal:
      resonance_score: 7
      inspirations_posting: ["Aakash Gupta", "Jack Clark"]
      overlap_warning: null
    suggested_angle: |
      One or two sentences describing how the champion should approach this subject.
      Should play to their voice patterns (news-trigger hook, N-days anchor, etc.).
    angle_template: news-trigger | personal-action | reader-question | hot-take | how-to | story
    draft_prompt: |
      A full prompt for the content-specialist skill that captures everything it needs
      to generate the post without re-querying the source.
  
  - rank: 2
    subject: "..."
    ...
```

### Field Definitions

**Top-level:**

- `status`: Overall result state
  - `ok`: Top subject scored 25+, confident recommendation
  - `weak_signal`: Top scored below 25, present with caveat
  - `no_signal`: Zero candidates after filtering, recommend skipping or widening
  - `error`: Something failed (MCP down, permissions, etc.)
- `window_used`: Whether primary or extended freshness window was applied
- `sources_queried`: List of data sources actually hit during this discovery call
- `total_candidates_before_filter`: Raw count from OctoLens before any filtering
- `candidates_after_dedup`: Count after Phase 3 filters applied
- `top_score`: Highest total score across all candidates
- `subjects`: Array of top N (default 5)

**Per subject:**

- `rank`: Integer 1-N, lower is better
- `subject`: One-sentence headline — this becomes the subject line of the delivered content
- `total_score`: Sum of all 5 factors (0-50 range)
- `factors`: Per-factor breakdown for transparency
- `source`: Where the signal came from (mention_id for OctoLens traceability)
- `topic_match_details`: Which champion topics matched and how strongly
- `freshness`: Age and status classification
- `dedup`: Duplicate detection result
- `inspiration_signal`: Resonance score and which inspirations are posting
- `suggested_angle`: Human-readable angle guidance for the content-specialist
- `angle_template`: Categorical tag for which hook style to use
- `draft_prompt`: Full prompt the content-specialist can use directly without re-querying

## Weak Signal Format

When top score is below 25:

```yaml
status: weak_signal
champion_id: dor-blech
top_score: 22
weak_signal_reason: |
  Top candidate only matched 3/10 on topic relevance and 6/10 on engagement.
  All high-scoring candidates were filtered out by the 30-day dedup rule.
recommendations:
  - "Wait 24h for fresh signals"
  - "Widen time window: /discover dor-blech --days=7"
  - "Pick manually: /generate dor-blech with explicit topic"
subjects: [...top 3 if any exist]
```

The downstream consumer should decide whether to still generate content from weak subjects or escalate to the operator.

## No Signal Format

When zero candidates survive filtering:

```yaml
status: no_signal
champion_id: dor-blech
total_candidates_before_filter: 12
candidates_after_dedup: 0
reason: |
  12 fresh mentions found in OctoLens matching Dor's persona, but all 12 are duplicates
  of topics he's already covered in the last 30 days.
recommendations:
  - "Skip today - no fresh subjects"
  - "Extend dedup window: /discover dor-blech --dedup-days=14"
  - "Scan secondary sources: /discover dor-blech --include-slack"
subjects: []
```

## Error Format

When MCP or tool failures prevent discovery:

```yaml
status: error
champion_id: dor-blech
error_type: mcp_unavailable | permission_denied | rate_limit | malformed_data
error_message: "OctoLens MCP returned 429 rate limit"
recoverable: true | false
retry_after_seconds: 300
subjects: []
```

## Consumer Contract

### generate-content Skill

When generate-content receives no explicit topic, it calls discover-subjects and picks the top-ranked subject if:

- `status == "ok"`
- `top_score >= 30`

Otherwise it escalates to the operator:

```
No strong subjects for {champion_name} today (top score: {N}/50).
Would you like to:
1. Pick a topic manually
2. Widen the search window
3. Skip delivery today
```

### scheduled-pipeline Skill

The daily pipeline calls discover-subjects for every active champion. If `status == "ok"` and `top_score >= 30`, it auto-proceeds to generation. If `status == "weak_signal"`, it logs the weak signal to the pipeline report but still proceeds (automation must tolerate weak days). If `status == "no_signal"`, it skips the champion for today and logs the skip.

### Operator Commands

`/discover {champion_id}` returns the full YAML for operator review. The operator can:

- Pick a rank to send to generate-content: `/generate dor-blech --subject-rank=1`
- Extend the window: `/discover dor-blech --days=7`
- Include inspirations: `/discover dor-blech --check-inspirations`

## Caching Considerations

Subject discovery is expensive (multiple OctoLens calls, optional Bright Data scrapes, content-history reads). Cache the full output for 1 hour per champion so repeated calls within the same session don't re-query everything.

Cache key: `discover:{champion_id}:{window}:{sources}`.
Cache location: `.claude/social-amplifier/discover-cache/{champion_id}.yaml` with expiration metadata.

The scheduled-pipeline runs once a day, so cache never helps in production — but for operator debugging and manual discovery, caching saves real time.

## Example Output (ofer-blutrich, 2026-04-13)

```yaml
status: ok
champion_id: ofer-blutrich
discovered_at: 2026-04-13T11:00:00+03:00
window_used: primary
sources_queried:
  - octolens_industry_insights
  - octolens_news_triggers
total_candidates_before_filter: 58
candidates_after_dedup: 14
top_score: 44

subjects:
  - rank: 1
    subject: "Anthropic's 'ship button' in Claude sparks 'vibe coding dead' viral narrative"
    total_score: 44
    factors:
      topic_match: 10
      recency: 10
      engagement: 9
      inspiration: 8
      originality: 7
    source:
      mention_id: 162839768
      url: "https://twitter.com/jbuilderx/status/2043540905760809139"
      platform: twitter
      author: "@jbuilderx"
      sentiment: neutral
      engagement_metric: "85 reactions, 12 comments"
      published_at: "2026-04-13T04:04:53Z"
    topic_match_details:
      matched_champion_topics: ["AI agent infrastructure", "Ship-in-public builder journey"]
      match_strength: exact
    freshness:
      age_hours: 7
      status: primary
    dedup:
      status: clean
      matched_history_files: []
    inspiration_signal:
      resonance_score: 8
      inspirations_posting: ["Aakash Gupta", "Jack Clark"]
      overlap_warning: null
    suggested_angle: |
      News-trigger hook ("Anthropic added a ship button. My timeline decided vibe coding is dead.") 
      followed by personal-anchor ("I build at one of those startups. Here's what the narrative misses.") 
      and a specific list of what's actually hard about shipping AI apps (the 95% after the prompt).
      End with aphoristic close.
    angle_template: news-trigger
    draft_prompt: |
      Generate a LinkedIn post for ofer-blutrich responding to the viral "Anthropic ship button kills 
      vibe coding" narrative. Use news-trigger hook, builder-inside-the-category perspective, list 
      4-5 concrete technical challenges that a ship button doesn't solve (SSO, rollbacks, migrations, 
      cost forecasting), close with "Most of these startups survive. The ones that don't were always 
      wrappers around a model they didn't control." Target 200-250 words. Zero hashtags. Max 1 emoji.
```

The `draft_prompt` field is the key output — generate-content can use it directly to produce the post without re-reading OctoLens.
