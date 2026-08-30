# AI agent platforms — official setup

This project uses **one canonical file** (`AGENTS.md`) plus **platform-native** config files where each tool expects them. Stubs do not duplicate rules — they point to `AGENTS.md`.

**Installed for this repo:** {{WORKFLOW_TOOLS_LIST}}

## Summary

| Platform | Official file(s) | What bootstrap installs |
|----------|------------------|-------------------------|
| **Codex** | `AGENTS.md` | Nothing extra — Codex reads `AGENTS.md` natively |
| **Cursor** | `AGENTS.md`, `.cursor/rules/*.mdc`, `.cursor/commands/` | Thin router rule + slash commands |
| **Antigravity** | `.agents/rules/*.md` | Thin pointer (`trigger: always_on`) |
| **Claude Code** | `CLAUDE.md` or `.claude/CLAUDE.md` | Minimal `CLAUDE.md` → `AGENTS.md` |
| **Gemini CLI** | `GEMINI.md`, `AGENTS.md` | `.gemini/settings.json` + optional `GEMINI.md` stub |

## Official documentation

| Platform | Docs |
|----------|------|
| **AGENTS.md** (cross-tool) | [agents.md](https://agents.md/) |
| **Cursor** | [cursor.com/docs/context/rules](https://cursor.com/docs/context/rules) — `AGENTS.md` and `.cursor/rules` |
| **Antigravity** | `.agents/rules/` with YAML frontmatter (`trigger: always_on`) |
| **OpenAI Codex** | Reads `AGENTS.md` from project root ([Codex AGENTS.md](https://github.com/openai/codex)) |
| **Claude Code** | [code.claude.com/docs/en/memory](https://code.claude.com/docs/en/memory) — `CLAUDE.md` |
| **Gemini CLI** | [gemini-cli GEMINI.md](https://github.com/google-gemini/gemini-cli/blob/main/docs/cli/gemini-md.md) — also discovers `AGENTS.md` |

## Add or remove a platform later

Re-run bootstrap from `solo-dev-ai-kit`:

```bash
/path/to/solo-dev-ai-kit/bootstrap.sh --target . --repo {{GH_REPO}} --tools cursor,antigravity,claude
```

Use `--force` to overwrite `AGENTS.md` if you customized it. Without `--force`, local edits are preserved.

**Install on a new machine:** paste [INSTALL_PROMPT.md](https://github.com/sahibul-nf/solo-dev-ai-kit/blob/main/INSTALL_PROMPT.md) to your AI agent — no manual terminal required.

## Why both `AGENTS.md` and `.cursor/rules`?

- **`AGENTS.md`** — canonical content; read by Codex, Cursor, and Gemini CLI.
- **`.cursor/rules/*.mdc`** — thin always-on router so Cursor classifies intent every session without `@AGENTS.md`.

Antigravity uses the same pattern: `.agents/rules/` pointer with `trigger: always_on`.

## UI verification tools

Bootstrap reports availability (does not install browsers):

1. **Cursor IDE browser** — default in Cursor; no project install.
2. **Playwright CLI** — optional fallback if already on device/project.
3. Fill in `docs/how-to-run.md` with local dev URL so browser tools can reach the app.
