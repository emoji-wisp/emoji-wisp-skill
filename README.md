# emoji-wisp-skill

Agent skill for the [emoji-wisp](https://emoji.i68.ltd) emoji expression service —
find emojis by meaning, mashup two emojis into an illustration, and emojiize text
by mood & style, over MCP.

[中文说明（README.zh-CN.md）](./README.zh-CN.md)

## What it gives your agent

Six MCP tools backed by emoji-wisp:

- **Search by meaning** — `search_emojis("celebration")` returns matching emojis,
  kaomoji and symbols with related keywords
- **Emoji details** — `get_emoji`
- **Random picks** — `random_emojis` (filter by category)
- **Mashup illustration** — `combine_emojis("🐱", "🐶")` → Google Emoji Kitchen image URL
- **Occasion recommendations** — `recommend_emojis("product launch")` (LLM)
- **Text emojiization** — `suggest_replacements("今天销量暴涨", tone="火爆")` (LLM)

## Install

Download the standalone CLI (single file, Node.js 24+, no npm install):

```bash
curl -L -o emoji-wisp-cli.mjs https://emoji.i68.ltd/downloads/emoji-wisp-cli.mjs
```

Then connect your MCP client over stdio to
`node emoji-wisp-cli.mjs` with `EMOJI_WISP_MCP_URL=https://emoji.i68.ltd/mcp`
(full snippet in [SKILL.md](./SKILL.md) § Setup).

## Files

- `SKILL.md` — the skill itself (setup, tool reference, usage guidance)
- `README.zh-CN.md` — 中文说明

## Service

- Production: https://emoji.i68.ltd (web) · https://emoji.i68.ltd/mcp (MCP)
- CLI download page: https://emoji.i68.ltd/cli/

## License

MIT (see [LICENSE](./LICENSE))
