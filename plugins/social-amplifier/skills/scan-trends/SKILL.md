---
name: scan-trends
description: |
  Scans LinkedIn and X for trending topics filtered by champion interests.
  Uses Bright Data MCP for social scraping, falls back to WebFetch.

  Triggers on: trends, trending, what's hot, popular topics, scan trends.
---

# Trend Scanning Skill

## Dependencies

- **Bright Data MCP** (preferred): Social media scraping for LinkedIn/X trends
- **WebFetch** (fallback): General web scraping for tech news and trends

## Process

1. Load champion profile to get topics and inspirations
2. Query trending content matching those topics
3. Filter by recency (last 7 days) and engagement
4. Return top 5 trending topics with personalized angles

## Bright Data Queries

For LinkedIn:
- Search posts by keywords from champion's topics[]
- Filter by engagement (likes + comments > threshold)
- Prioritize posts from champion's inspirations list

For X:
- Search tweets by keywords from champion's topics[]
- Filter by retweets + likes
- Check trending hashtags in tech/startup space

## Fallback (No Bright Data)

Use WebFetch on:
- `https://news.ycombinator.com/` - Hacker News front page
- `https://techcrunch.com/` - Recent tech news
- Champion inspiration URLs from inspirations.md
