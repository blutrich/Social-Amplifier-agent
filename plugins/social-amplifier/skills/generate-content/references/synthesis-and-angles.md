# Synthesis and Angles (Phase 4 of the Generate-Content Waterfall)

How to combine Slack signals (Phase 1) + inspiration activity (Phase 2) + champion voice (Phase 3) into 2-3 distinct content variations.

## The Synthesis Question

By Phase 4, you have:

- 3-10 Slack signals (recent feature ships, champion's own messages, threads they're in)
- 1-5 inspiration activity entries (what people they follow are posting about this week)
- Complete champion voice profile (tone, style, banned words, structural rules)
- 30 days of content history (what they've already posted)

The synthesis question: **Given all of this, what's the strongest single subject the champion should write about today, and what 2-3 angles best ground that subject in their voice?**

## Strongest Signal Selection

Rank the available signals by leverage:

| Signal | Leverage | Why |
|--------|---------|-----|
| Champion's own Slack message about a topic | Highest | They already cared enough to write about it. Easy to expand into a LinkedIn post. |
| Inspiration is currently posting about a topic | High | Built-in audience overlap, pre-validated relevance, network effects |
| Slack feature ship in champion's topic area | High | Real concrete artifact to ground in, internal credibility |
| OctoLens trending topic (from discover-subjects) | Medium-high | External signal, current narrative, but no internal anchor |
| Generic topic prompt from operator | Medium | Operator picked it for a reason but lacks specific grounding |
| No signal (cold start) | Low | Falls back to evergreen topics from champion profile |

Rank the available signals and pick the top 1 as the primary subject. The other signals can become input to alternate variation angles.

## Picking the Subject

```python
def pick_primary_subject(slack_signals, inspiration_activity, discover_subjects_output, operator_topic):
    candidates = []
    
    # Highest priority: champion's own recent statement
    for signal in slack_signals:
        if signal.signal_type == "champion_message" and signal.score >= 8:
            candidates.append({
                "subject": signal.body_excerpt,
                "source": "champion_slack",
                "leverage": 10,
                "angle_hint": "expand_own_thought"
            })
    
    # High priority: inspiration is hot on a topic
    for inspiration in inspiration_activity.active_inspirations:
        if inspiration.relevance_score >= 7:
            for post in inspiration.recent_posts:
                if post.age_hours < 48:
                    candidates.append({
                        "subject": extract_topic(post.body_excerpt),
                        "source": "inspiration_echo",
                        "leverage": 9,
                        "angle_hint": "respond_to_inspiration",
                        "inspiration_name": inspiration.name
                    })
    
    # High priority: Slack feature ship in topic area
    for signal in slack_signals:
        if signal.signal_type == "feature_ship" and signal.champion_involved:
            candidates.append({
                "subject": extract_feature_name(signal.body_excerpt),
                "source": "internal_feature",
                "leverage": 9,
                "angle_hint": "ship_in_public"
            })
    
    # Medium-high: external trending topic
    if discover_subjects_output and discover_subjects_output.top_score >= 35:
        candidates.append({
            "subject": discover_subjects_output.subjects[0].subject,
            "source": "external_trend",
            "leverage": 7,
            "angle_hint": discover_subjects_output.subjects[0].angle_template
        })
    
    # Fallback: operator-provided topic
    if operator_topic:
        candidates.append({
            "subject": operator_topic,
            "source": "operator",
            "leverage": 5,
            "angle_hint": "freeform"
        })
    
    # Sort by leverage, return top
    candidates.sort(key=lambda c: c.leverage, reverse=True)
    return candidates[0] if candidates else None
```

If no candidate has leverage >= 5, return `null` and skip generation. This champion has nothing strong to write about today — silence is better than noise.

## The 3 Standard Variation Angles

Once a subject is picked, generate 3 variations using DIFFERENT angles. The angles depend on what signals were available:

### Angle 1: Personal Experience / Internal Anchor

**Best when:** Slack signals provide a specific recent feature, project, or personal moment

**Template:**
```
[Hook: news-trigger or personal action - what happened recently]
[Concrete specific detail from Slack or work]
[The math or numbers showing it matters]
[Aphoristic close]
```

**Example for Ofer:**
> Shipped a Voice Guardian for our internal content tool this week.
> 
> The 10-point checklist turned out to be the whole product. Banned word list, em dash detection, per-champion overrides.
> 
> First version without it generated text that looked fine. Nobody would have posted it. Turns out "fine" is exactly what AI text sounds like.
> 
> Building AI into production means writing the rules that stop the model from being itself.

### Angle 2: Industry Insight / Echo Response

**Best when:** Inspiration activity (Phase 2) shows someone writing about the same topic with a stance worth responding to

**Template:**
```
[Hook: respond to or build on what an inspiration said]
[Quote or paraphrase the inspiration's point]
[Champion's specific add — what the inspiration missed or got right]
[Grounded in champion's actual work]
[Aphoristic close]
```

**Example for Ofer (responding to Aakash Gupta):**
> Aakash Gupta wrote that Anthropic's ship button is going to mass-extinction event vibe coding startups.
> 
> I work at one of those startups. Here's what the narrative misses.
> 
> The ship button is the last 5%. The first 95% is database migrations, SSO, RBAC, rollbacks at 2am, cost forecasting when LLM calls become 40% of burn.
> 
> Most of these startups survive. The ones that don't were always wrappers around a model they didn't control.

### Angle 3: Reflection / Connecting Threads

**Best when:** Multiple signals point to the same theme, and the champion can synthesize across them

**Template:**
```
[Hook: observation across multiple recent things]
[Specific examples - reference 2-3 concrete things that connect]
[The pattern that connects them]
[What this means going forward]
```

**Example for Ofer:**
> Three things this week that all point in the same direction:
> 
> Anthropic dropped Claude Code with managed agents. Karpathy posted his pattern for LLM knowledge bases. I shipped a Voice Guardian for our team's content workflow.
> 
> What I notice across all three: the value isn't in the model. It's in the rules wrapped around the model. The opinions baked into the system that decide what good output looks like.
> 
> The next year of AI app building isn't a model arms race. It's a rules race.

## Variation Selection Per Champion

Different champions favor different angles. Look at the champion's content history to see which angles have worked for them:

| Champion type | Favored angles | Avoid |
|--------------|---------------|-------|
| Builder (Ofer) | Personal experience > Echo response > Reflection | Pure abstract theory |
| Comms (Dor) | Personal experience > Reflection > Echo response | Pure technical explainer |
| Founder (Maor) | Numbers/milestones > Personal experience > Echo | Long industry analysis |
| Dev/Engineer | Personal experience > Reflection > Echo | Marketing announcement |
| Marketing | Echo response > Industry insight > Personal experience | Pure technical detail |

If the champion's content history shows 80% personal experience posts and 20% reflection, lean heavier on personal experience for the new variations.

## Avoiding Recent Repetition

Before generating, check the last 30 days of content-history. Avoid:

1. **Same exact subject** — if the champion just posted about Voice Guardian 5 days ago, don't make Voice Guardian the subject again
2. **Same angle template** — if the last 3 posts were all "personal experience" angle, force variation 1 to be a different angle this time
3. **Same opening hook structure** — if the last post opened "Shipped X this week..." don't open this one the same way

The synthesis writer should look at the most recent 5 entries in content-history and check for these patterns. If detected, weight away from them in this generation.

## Generating The Variations

For each variation, the writer needs:

1. The picked subject (from `pick_primary_subject`)
2. The angle template (1, 2, or 3 above)
3. The full champion voice context (Phase 3)
4. The specific source material to ground in (Slack signal, inspiration post, or both)
5. Banned patterns from style-preferences (em dashes, emojis, hashtags, etc.)
6. Length and format constraints

The actual prompt to the LLM (Sonnet or Opus depending on champion config):

```
You are generating a LinkedIn post for {champion_name} ({champion_persona}).

CONTEXT:
- Champion voice: {tone-of-voice.md content}
- Style preferences: {style-preferences.md content}
- Recent content (avoid repeating): {last 5 posts from content-history}

TODAY'S SUBJECT:
{picked subject from synthesis}

GROUND IN:
- Slack signal: {if used} - {body_excerpt}
- Inspiration post: {if used} - {inspiration_name}: "{post body}"

ANGLE TO USE:
{angle 1, 2, or 3}

FORMAT REQUIREMENTS:
- Length: {champion's word_count_min}-{champion's word_count_max} words
- {if em_dashes: deny} No em dashes
- Max {emoji_max} emojis
- Zero hashtags
- {champion-specific banned words: never use any of these}
- Match the sentence-length pattern observed in champion's real writing

OUTPUT FORMAT:
Just the post text. No preamble, no explanation, no meta-commentary.
```

Generate one variation per angle. The Voice Guardian (Phase 5) will score them and reject any that fail.

## When Generation Returns Garbage

Sometimes the LLM produces something that's clearly wrong (full of banned words, ignores the format, hallucinates details not in the source). The Voice Guardian catches this in Phase 5, but the writer can also self-check before passing variations downstream:

```python
def quick_self_check(variation, style_preferences):
    # Detect obvious failures before sending to Voice Guardian
    if any(banned_word in variation.lower() for banned_word in style_preferences.banned_words_add):
        return False
    if "thrilled to announce" in variation.lower():
        return False
    if variation.count('#') > style_preferences.hashtag_max:
        return False
    if variation.count('—') > 2 and not style_preferences.em_dashes_allowed:
        return False
    if len(variation.split()) < style_preferences.linkedin.word_count_min:
        return False
    return True
```

If a variation fails the quick check, regenerate it with explicit feedback ("the previous attempt used 'thrilled to announce' which is banned, try again without that phrase"). Max 2 regeneration attempts per variation, then drop it.

## Output

Phase 4 returns a list of 2-3 candidate variations:

```yaml
variations:
  - rank: 1
    angle: personal-experience
    primary_signal_source: slack
    grounded_in:
      - "Slack message: 'Shipped Voice Guardian this week'"
      - "Inspiration: Aakash Gupta posted similar this morning"
    text: |
      [Full draft text]
    estimated_voice_match: 9 (pre-Voice Guardian self-estimate)
    word_count: 220
  
  - rank: 2
    angle: echo-response
    primary_signal_source: inspiration
    grounded_in:
      - "Inspiration: Aakash Gupta on Anthropic ship button (6h ago)"
    text: |
      [Full draft text]
    estimated_voice_match: 8
    word_count: 240
  
  - rank: 3
    angle: reflection
    primary_signal_source: synthesis_across_signals
    grounded_in:
      - "Slack: Voice Guardian ship"
      - "External: Karpathy LLM knowledge base post"
      - "External: Anthropic Claude Code release"
    text: |
      [Full draft text]
    estimated_voice_match: 7
    word_count: 260
```

These 3 variations get passed to Phase 5 (Voice Guardian) for scoring. Only the ones that pass 9+ become the final output.
