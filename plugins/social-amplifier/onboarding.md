# Social Amplifier - Getting Started

> Set up in 5 minutes. Works in Claude Code or Claude Cowork.

## Step 1: Install the Plugin

**Claude Cowork:**
1. Go to Customize > Browse Plugins
2. Click + next to "Personal"
3. Select "Add marketplace from URL"
4. Paste: `https://github.com/blutrich/Social-Amplifier-agent`
5. Click Install

**Claude Code (terminal):**
The plugin is auto-detected when you open this repo in Claude Code.

## Step 2: Connect Slack (Recommended)

1. Go to Customize > Connect your tools
2. Find Slack and click Connect
3. Authorize the Base44 workspace

Slack connection lets the agent scan for feature announcements. Without it, you can still generate content by providing topics manually.

## Step 3: Create Your Champion Profile

Run: `/new-champion`

The agent will walk you through 8 questions to build your personal content profile:
1. Your name
2. Your role at Base44
3. Topics that interest you
4. People you follow on LinkedIn/X
5. Your own writing samples (posts, Slack messages, anything)
6. What kind of content you want to create
7. Review and confirm
8. Agent generates your tone-of-voice guide

This takes about 5-10 minutes. Do it once, use it forever.

## Step 4: Generate Your First Post

Run: `/generate {your-id}` (e.g., `/generate dor-blech`)

The agent will:
1. Ask what platform (LinkedIn or X)
2. Ask what topic (or offer to scan Slack/trends)
3. Generate 3 variations with different angles
4. Run quality check (Voice Guardian)
5. Present ready-to-post options

## Other Commands

| Command | What it does |
|---------|-------------|
| `/scan-trends {id}` | Find trending topics matching your interests |
| `/scan-slack {id}` | Find feature announcements worth posting about |

## Tips

- **Paste Slack messages** directly into the chat for instant repurposing
- **Give feedback** on generated content - the agent learns your preferences
- **Update your profile** anytime by running `/new-champion` again
- **Be specific** about topics - "write about the new auth feature I built" beats "write a post"

## Getting Help

- Slack: #claude-code-for-marketing-team
- Ofer: DM for plugin issues
