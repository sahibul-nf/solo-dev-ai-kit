# Master prompt — bootstrap workflow on another device

**For the user:** open your **app project** in Agent mode, paste a prompt below. You do **not** run terminal commands — the agent does.

**Ready-made prompts:** [INSTALL_PROMPT.md](INSTALL_PROMPT.md) · [INSTALL_PROMPT.id.md](INSTALL_PROMPT.id.md)

---

Install **solo-dev-ai-kit** into this app project. I am not running terminal commands myself — you run everything.

Follow **official per-platform file conventions** (see kit `docs/agent-platforms.md` after bootstrap).

## Kit location

- Clone if missing: `https://github.com/sahibul-nf/solo-dev-ai-kit`
- Or existing path: `[path/to/solo-dev-ai-kit]`

## This app project

- **Target:** current workspace (the app — do not modify the kit repo itself)
- **GitHub repo:** `[owner/repo]` or auto-detect from `git remote`
- **Stack:** `[Flutter / Next.js / …]`
- **Branches:** auto-detect from `git branch -a` — `dev`→`main` if `dev` exists, else **single branch** (`main`/`master`). Or pass `--main-only`.
- **CI:** `[flutter test / npm test / pytest]`
- **AI tools:** `[cursor,antigravity]` (usual) or add `codex,claude,gemini`
- **Client reports:** `[yes / no]`
- **Run GitHub setup:** `[yes / no]`
- **Overwrite custom files:** only with `--force` if I explicitly ask

## Platform rules (official)

- **AGENTS.md** = single canonical workflow (always installed)
- **Cursor** → `.cursor/rules/*.mdc` thin router + `.cursor/commands/`
- **Antigravity** → `.agents/rules/*.md` with `trigger: always_on`
- **Codex** → reads `AGENTS.md` only (no CODEX.md)
- **Claude Code** → minimal `CLAUDE.md` stub pointing to AGENTS.md
- **Gemini CLI** → `.gemini/settings.json` + minimal `GEMINI.md` stub

## Do

1. Check prerequisites (`gh`, `jq`). Refresh scopes if needed: `gh auth refresh -h github.com -s repo,project,read:project`
2. Run `solo-dev-ai-kit/bootstrap.sh` with flags above.
3. Fill in `docs/how-to-run.md` (local URL, start command, tests, test accounts — no secrets).
4. Run `./scripts/gh-check-ui-tools.sh` — report only; never install browsers.
5. Summarize installed files per platform and project board URL.
6. Smoke test triage (no coding): *"Login redirect loop after token refresh"* → expect issue + AC + *which # first?*

Do **not** implement app features.

---

## Ultra-short (kit on disk)

```text
Install solo-dev-ai-kit into this project from [path/to/solo-dev-ai-kit]. Run bootstrap.sh with --tools cursor,antigravity --run-github-setup. Fill docs/how-to-run.md. I won't run terminal — you do. No app coding.
```

## Ultra-short (clone from GitHub)

```text
Clone https://github.com/sahibul-nf/solo-dev-ai-kit, bootstrap into this project (--tools cursor,antigravity --run-github-setup), fill docs/how-to-run.md, smoke-test triage. I won't run terminal — you do.
```

## All platforms at once

Add to bootstrap flags: `--tools cursor,antigravity,codex,claude,gemini`

## Smoke test

> Login redirect loop after token refresh

Expect: GitHub issue + AC + *which # first?* — no code changes.
