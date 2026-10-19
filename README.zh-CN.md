# emoji-wisp-skill（中文说明）

[emoji-wisp](https://emoji.i68.ltd) 表情服务的 Agent 技能——通过 MCP 实现按含义找 emoji、两个 emoji 合成插画、按情感与风格把文字变表情。

[English (README.md)](./README.md)

## 给你的 Agent 带来什么

六个 MCP 工具，由 emoji-wisp 服务支撑：

- **按含义搜索** —— `search_emojis("celebration")` 返回匹配的 emoji、颜文字、符号及相关关键词
- **emoji 详情** —— `get_emoji`
- **随机取材** —— `random_emojis`（可按类型过滤）
- **合成插画** —— `combine_emojis("🐱", "🐶")` → Google Emoji Kitchen 图片链接
- **场景推荐** —— `recommend_emojis("产品发布")`（LLM）
- **文字 Emoji 化** —— `suggest_replacements("今天销量暴涨", tone="火爆")`（LLM）

## 安装

下载独立 CLI（单文件，Node.js 24+，无需 npm install）：

```bash
curl -L -o emoji-wisp-cli.mjs https://emoji.i68.ltd/downloads/emoji-wisp-cli.mjs
```

然后让你的 MCP 客户端以 stdio 连接 `node emoji-wisp-cli.mjs`，环境变量
`EMOJI_WISP_MCP_URL=https://emoji.i68.ltd/mcp`（完整片段见 [SKILL.md](./SKILL.md) § Setup）。

## 文件

- `SKILL.md` —— 技能本体（安装、工具参考、使用指引）
- `README.md` —— English readme

## 服务

- 生产：https://emoji.i68.ltd（网页）· https://emoji.i68.ltd/mcp（MCP）
- CLI 下载页：https://emoji.i68.ltd/cli/

## License

MIT
