---
name: scan-slack
description: |
  Scans Slack feature channels for announcements worth turning into personal social content.
  Uses Slack MCP to read channels, filters by champion interests.

  Triggers on: scan slack, check slack, feature announcements, what's new, slack features.
---

# Slack Scanner Skill

## Dependencies

- **Slack MCP**: Required for reading Slack channels

## Process

### Step 1: Load Champion Context

```
Read(file_path="champions/{champion_id}/profile.json")
```

Extract `topics[]` and `role` for relevance filtering.

### Step 2: Scan Relevant Channels

Read recent messages from feature/product channels:
- #product-marketing-sync
- #general (for major announcements)
- #feat-* channels (feature-specific)
- Any channel the champion specifies

Use Slack MCP tools to discover and read channels:

```
mcp__claude_ai_Slack__slack_list_channels()
```

Then for each relevant channel:

```
mcp__claude_ai_Slack__slack_read_channel(channel_id="{channel_id}", limit=50)
```

Search for feature-related content across public channels:

```
mcp__claude_ai_Slack__slack_search_public(query="shipped OR launched OR released OR new feature")
```

### Step 3: Filter by Relevance

For each message/announcement found:
- Score relevance to champion's topics (0-10)
- Only keep items scoring 7+
- Prioritize: shipped features > upcoming features > discussions

### Step 4: Generate Angles

For each relevant item, suggest 2-3 repurposing angles:

```
## Slack Finds for {Name}

### 1. {Feature/Announcement}
**Channel:** #{channel}
**Posted by:** {author}
**Summary:** {1-2 sentences}

**Content angles for you:**
- A: Personal reaction - "I just saw {feature} ship and {your take based on role}"
- B: Behind-the-scenes - "Our team built {feature} because {reason}"
- C: User value - "If you're a {persona}, {feature} means {benefit}"

### 2. {Feature/Announcement}
...

Want me to generate a post from any of these? Just pick one.
```

## Fallback (No Slack MCP)

If Slack MCP is not connected:
- Report: "Slack MCP not connected. Please connect it via Customize > Connect your tools > Slack."
- Offer alternative: "You can paste a Slack message or feature announcement directly and I'll help you write a post about it."
