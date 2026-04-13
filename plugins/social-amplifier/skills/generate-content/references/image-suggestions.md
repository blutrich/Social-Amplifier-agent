# Image Suggestions (Phase 6)

How to decide whether the top approved variation should have an image, what kind, and where it should come from.

## Default: No Image

The default recommendation is **no image**. Most LinkedIn posts perform better as text-only. Looking at real champion data:

- Ofer's 9 LinkedIn posts: **all text-only**, zero images, zero diagrams, zero videos
- Dor's 5 LinkedIn posts: **all text-only**
- Maor's posts: occasional product screenshots, mostly text-only

Adding images is a deliberate decision for specific post types, not a default behavior. When in doubt, suggest no image.

## When An Image Helps

Images add value in 4 specific cases:

### Case 1: Specific Shipped Feature

If the variation is about a specific Base44 feature that just shipped, a screenshot of the feature in action is the gold standard:

```yaml
image_suggestion:
  needed: true
  type: feature_screenshot
  description: "Screenshot of the New Builder v3 interface showing the regenerate-design feature"
  source_hint: |
    Take screenshot from app.base44.com after loading the new builder.
    Crop to show only the regenerate-design control + a sample design.
    Include 1 second of context (don't crop too tight).
  source_url: "https://app.base44.com"
  generator_skill: none
  generator_prompt: null
  alternatives:
    - "If product UI isn't ready: ask Liron Monitz for a Figma export"
    - "If no screenshot available: use the Base44 logo on a colored background as fallback"
```

### Case 2: Single Compelling Number

If the variation centers on a single big number (revenue milestone, user count, deployment count), a stat visual works:

```yaml
image_suggestion:
  needed: true
  type: stat_visual
  description: "Single-stat visual: '$100M ARR' in Base44 brand orange on a white background"
  source_hint: "Use Base44 brand template with STK Miso Light font"
  generator_skill: nano-banana
  generator_prompt: |
    Generate a single-stat social card.
    Stat: $100M ARR
    Subtitle: "Definitely the fastest without VC backing"
    Brand: Base44 (orange #FF6B35, STK Miso font)
    Format: 1200x675 (LinkedIn / X share card)
    Style: clean, minimal, single number dominates
```

### Case 3: Architecture Diagram

If the variation explains how something works (separation of concerns, agent flow, system design), a diagram clarifies fast:

```yaml
image_suggestion:
  needed: true
  type: diagram
  description: "Simple flow diagram showing how the Voice Guardian sits between content-specialist and delivery"
  source_hint: "Hand-drawn style works better than corporate flowchart"
  generator_skill: excalidraw
  generator_prompt: |
    Create a simple flow diagram with 4 boxes connected by arrows:
    1. discover-subjects (left)
    2. generate-content (middle-left)  
    3. voice-guardian (middle-right)
    4. deliver-content (right)
    Annotate each box with 1-line description.
    Use Excalidraw hand-drawn style with the Base44 orange accent color.
```

### Case 4: Quoted Source Material

If the variation reacts to a specific tweet or post, a screenshot of the original (with attribution) sets the context:

```yaml
image_suggestion:
  needed: true
  type: source_screenshot
  description: "Screenshot of Aakash Gupta's tweet about Anthropic ship button"
  source_hint: "Use Twitter's native screenshot or screenshot the post URL directly"
  source_url: "https://twitter.com/aakashgupta/status/2043509529342873703"
  generator_skill: none
  generator_prompt: null
  attribution_required: true
```

## When An Image Hurts

Images can hurt the post in these cases:

### Generic stock photos
A generic AI-generated "people working at laptops" image makes the post look like marketing spam. Always say no to stock-style images.

### Decorative emoji-as-image
Some posts use emojis arranged as headers (🚀 🔥 ✨). This is a strong AI tell. Never recommend.

### Watermarked or low-quality screenshots
A screenshot with a watermark, blur, or compression artifacts makes the post look low-effort. If the only available screenshot is bad, suggest no image instead of a bad image.

### Images that compete with the text
A bold image with text overlaid pulls attention away from the post body. The post body is the product — the image is supporting context. Keep images quiet.

### Champion has zero historical images
If the champion has never used images in their last 10 posts, don't introduce them now. It would feel out of character. Voice Guardian will likely flag it on the Champion Test.

## The Decision Tree

For each top approved variation, ask:

```
1. Does the variation reference a specific shipped feature?
   YES → suggest feature_screenshot
   NO → continue

2. Does the variation hinge on a single big number?
   YES → suggest stat_visual
   NO → continue

3. Does the variation explain how something works (architecture/flow)?
   YES → suggest diagram
   NO → continue

4. Does the variation react to a specific named tweet/post?
   YES → suggest source_screenshot
   NO → continue

5. Has this champion historically used images in their posts?
   NO → suggest none (text-only fits their pattern)
   YES → re-evaluate previous cases more loosely

6. Default: suggest none
```

The decision tree weights toward "no image" — that's correct because most posts shouldn't have one.

## Generator Skill Routing

When an image IS needed, route to the right generator:

| Image type | Generator | Why |
|------------|-----------|-----|
| feature_screenshot | none (manual) | Real screenshots beat generated ones |
| stat_visual | nano-banana | Imagen 3 produces clean single-stat cards |
| diagram | excalidraw or pencil | Hand-drawn diagrams feel authentic |
| source_screenshot | none (manual) | Native screenshot of the actual source |
| brand_creative | nano-banana | For polished brand cards |
| product_photo | none (manual) | Use real product photography |

For generator-driven images, include a complete prompt the operator can pass directly to the generator skill. Don't make them write the prompt themselves.

## Cost Awareness

Image generation costs API calls and time. Don't auto-generate images during the waterfall. Always SUGGEST first, let the operator approve, and only then trigger generation in a separate step.

The waterfall outputs `image_suggestion` with everything needed to generate later if approved. Generation happens via the operator running:

```
/generate-image dor-blech --variation=1 --type=stat_visual
```

This is a separate flow, not part of the per-generation waterfall. Keeps the waterfall fast and cheap.

## Output Schema

The Phase 6 output added to the waterfall result:

```yaml
image_suggestion:
  variation_rank: 1
  needed: true | false
  type: feature_screenshot | stat_visual | diagram | source_screenshot | brand_creative | product_photo | none
  description: "1-2 sentence description"
  source_hint: "Where to get it (URL, app page, channel reference)"
  source_url: "https://..." or null
  generator_skill: nano-banana | excalidraw | pencil | none
  generator_prompt: "Full prompt for the generator skill" or null
  alternatives:
    - "Backup option 1"
    - "Backup option 2"
  attribution_required: true | false
  reasoning: "1 sentence explaining why this image type fits this variation"
```

If `needed: false`, all other fields except `reasoning` can be null:

```yaml
image_suggestion:
  variation_rank: 1
  needed: false
  type: none
  reasoning: "Champion's posts are consistently text-only; this variation works on its writing alone"
```

## When Champions Want To Override

If a champion later says "always include images" or "never include images", that's a feedback signal. The feedback skill should add a preference to `style-preferences.md`:

```yaml
images:
  default: never | always | auto
  preferred_types:
    - feature_screenshot
    - diagram
  blocked_types:
    - stock_photo
    - emoji_arrangement
```

The image suggestion phase respects these preferences. If a champion has `images.default: never`, always output `needed: false` regardless of the decision tree result.

## Default Behavior For New Champions

For champions onboarded today with no historical posting data:

1. First 5 posts: suggest no image (let them establish their own pattern)
2. After 5 posts: analyze their pattern, set `images.default` based on what they actually use
3. Continue refining via feedback

This avoids forcing images on champions who don't want them.
