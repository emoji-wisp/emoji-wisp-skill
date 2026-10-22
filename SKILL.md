---
name: emoji-wisp-skill
description: >
  Find, combine and generate emoji expressions via the emoji-wisp MCP service.
  Use whenever the user asks to find/search emojis by meaning ("find a cute emoji",
  "emoji for celebration"), combine/mashup two emojis ("combine 🐱 and 🐶",
  "merge two emojis into one"), pick emojis for an occasion ("emojis for a product
  launch"), or turn text into emoji expressions ("emojiize this sentence",
  "replace words with emojis by mood"). Also use when the user mentions
  emoji-wisp, emoji wish, or the i68 emoji service — even if they don't say "MCP".
license: MIT
compatibility: Requires Node.js 24+, internet access, and an MCP-capable agent
metadata:
  author: emoji-wisp
  version: "1.1.0"
  homepage: https://emoji.i68.ltd
---

# emoji-wisp

Search, combine and generate emoji expressions through the emoji-wisp remote
MCP service (https://emoji.i68.ltd). All emoji data (39+ keyword pages, 31k+
mashup combinations) and LLM features run server-side — the local CLI is just
a bridge.

## Setup (first use per machine)

1. Download the standalone CLI (single file, no npm install):

```bash
curl -L -o emoji-wisp-cli.mjs https://emoji.i68.ltd/downloads/emoji-wisp-cli.mjs
```

Requires Node.js 24+. The file runs as-is.

2. Connect from your MCP client:

```js
import { Client } from '@modelcontextprotocol/sdk/client/index.js';
import { StdioClientTransport } from '@modelcontextprotocol/sdk/client/stdio.js';

const client = new Client({ name: 'my-agent', version: '1.0.0' });
await client.connect(new StdioClientTransport({
  command: process.execPath,            // node
  args: ['emoji-wisp-cli.mjs'],         // path to the downloaded file
  env: { EMOJI_WISP_MCP_URL: 'https://emoji.i68.ltd/mcp' },
}));
```

For Claude Desktop / Cursor config JSON, see the service's
[CLI page](https://emoji.i68.ltd/cli/).

## Tools

| Tool | Use for |
|---|---|
| `search_emojis` | Find emojis/kaomoji/symbols by meaning. Args: `query` (required), `limit` (1-50, default 10). Returns `emoji (kind)` lines + related keywords. |
| `get_emoji` | Details for one emoji (codepoints, mashup count), or search by name/keyword. Arg: `emoji`. |
| `random_emojis` | Random picks. Args: `category` (`emoji`\|`kaomoji`\|`symbol`), `count` (1-20). |
| `combine_emojis` | Mashup two emojis → Emoji Kitchen illustration URL. Args: `a`, `b`. Returns the image URL — present it as markdown `![](url)` or a link. |
| `recommend_emojis` | LLM picks emojis for an occasion. Args: `purpose`, `count` (1-10, default 5). |
| `suggest_replacements` | LLM suggests word→emoji replacements by mood & style. Args: `text` (≤2000 chars), `tone` (`原味`\|`可爱`\|`火爆`\|`专业`\|`含蓄`, default 原味). |

Call pattern (all tools):

```js
const result = await client.callTool({ name: 'search_emojis', arguments: { query: 'cute', limit: 5 } });
console.log(result.content[0].text); // plain text result
```

## Usage guidance

- **Finding an emoji for a feeling**: prefer `search_emojis` with an English or
  Chinese meaning word (`cute`, `celebration`, `虎`, `可爱` all work). Present
  several options and let the user pick. Not every word has a page — "No
  results" means try a synonym.
- **Mashups**: `combine_emojis` only works for pairs that exist in Google Emoji
  Kitchen (~1000 popular emojis). If it returns "No mashup exists", try popular
  base emojis (faces, ❤️🔥✨) or fall back to `recommend_emojis`.
- **Emojiizing text**: `suggest_replacements` returns suggestions, not rewritten
  text. Apply each `original → emoji` to the input yourself (they are verbatim,
  non-overlapping), then show the result. Styles change density: 火爆 (fiery,
  dense) vs 含蓄 (subtle, one trailing emoji only).
- **Tone values are Chinese literals** (`原味/可爱/火爆/专业/含蓄`) — pass them
  as-is; they are LLM style parameters, not UI language.
- The service may fall back to a local dictionary under LLM outage (results are
  still valid, just simpler). No action needed.

## Troubleshooting

- **Connection refused / cannot reach service**: check `EMOJI_WISP_MCP_URL`
  (must be `https://emoji.i68.ltd/mcp`) and network reachability.
- **Empty suggestions from suggest/recommend**: transient LLM pressure — retry
  once before giving up.
- Docs & download page: https://emoji.i68.ltd/cli/
