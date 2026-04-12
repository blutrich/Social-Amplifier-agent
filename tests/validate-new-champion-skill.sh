#!/bin/bash
# Structural validation for new-champion SKILL.md
# Checks: frontmatter, 8 steps, output files, champion_id derivation

SKILL_FILE="plugins/social-amplifier/skills/new-champion/SKILL.md"
ERRORS=0

# Check file exists
if [ ! -f "$SKILL_FILE" ]; then
  echo "FAIL: $SKILL_FILE does not exist"
  exit 1
fi

CONTENT=$(cat "$SKILL_FILE")

# Check frontmatter
if ! echo "$CONTENT" | head -1 | grep -q "^---"; then
  echo "FAIL: Missing frontmatter opening ---"
  ERRORS=$((ERRORS + 1))
fi

if ! echo "$CONTENT" | grep -q "^name:"; then
  echo "FAIL: Missing 'name:' in frontmatter"
  ERRORS=$((ERRORS + 1))
fi

if ! echo "$CONTENT" | grep -q "^description:"; then
  echo "FAIL: Missing 'description:' in frontmatter"
  ERRORS=$((ERRORS + 1))
fi

# Check all 8 steps exist
for step_num in 1 2 3 4 5 6 7 8; do
  if ! echo "$CONTENT" | grep -q "### Step $step_num"; then
    echo "FAIL: Missing Step $step_num"
    ERRORS=$((ERRORS + 1))
  fi
done

# Check step content keywords
declare -a STEP_KEYWORDS=("Name" "Role" "Interests" "Inspirations" "Writing Samples" "Content Preferences" "Confirmation" "Tone")
for i in "${!STEP_KEYWORDS[@]}"; do
  step=$((i + 1))
  keyword="${STEP_KEYWORDS[$i]}"
  if ! echo "$CONTENT" | grep -qi "Step $step.*$keyword\|Step $step\b.*\n.*$keyword"; then
    # Looser check - keyword anywhere near that step section
    if ! echo "$CONTENT" | grep -qi "$keyword"; then
      echo "FAIL: Step $step missing keyword '$keyword'"
      ERRORS=$((ERRORS + 1))
    fi
  fi
done

# Check output file references
for file in "profile.json" "tone-of-voice.md" "inspirations.md" "rules.md" "content-history"; do
  if ! echo "$CONTENT" | grep -q "$file"; then
    echo "FAIL: Missing output file reference: $file"
    ERRORS=$((ERRORS + 1))
  fi
done

# Check champion_id / kebab-case mention
if ! echo "$CONTENT" | grep -qi "champion.id\|kebab.case\|champion_id"; then
  echo "FAIL: Missing champion_id / kebab-case derivation"
  ERRORS=$((ERRORS + 1))
fi

# Check for interactive Q&A indicators (Ask/wait for user)
if ! echo "$CONTENT" | grep -qi "ask\|wait.*input\|wait.*response\|user.*input"; then
  echo "FAIL: Missing interactive Q&A indicators"
  ERRORS=$((ERRORS + 1))
fi

# Check profile.json schema fields
for field in "name" "role" "topics" "content_preferences" "platforms" "created" "version"; do
  if ! echo "$CONTENT" | grep -q "\"$field\""; then
    echo "FAIL: profile.json missing field: $field"
    ERRORS=$((ERRORS + 1))
  fi
done

# Check tone-of-voice sections
for section in "Voice in one sentence" "Sentence patterns" "Vocabulary" "Energy" "Humor" "Topics"; do
  if ! echo "$CONTENT" | grep -qi "$section"; then
    echo "FAIL: tone-of-voice.md missing section: $section"
    ERRORS=$((ERRORS + 1))
  fi
done

if [ $ERRORS -gt 0 ]; then
  echo "FAIL: $ERRORS errors found"
  exit 1
fi

echo "PASS: All structural checks passed"
exit 0
