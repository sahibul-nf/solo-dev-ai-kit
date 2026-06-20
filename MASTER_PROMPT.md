# Master prompt — bootstrap workflow on another device

Paste into **Agent mode** with your **app project** open (not the kit repo). Adjust `[brackets]`.

---

Bootstrap **solo-dev-ai-kit** into this app project. Follow **official per-platform file conventions** (see kit `docs/agent-platforms.md`).

## Kit location

- `[path/to/solo-dev-ai-kit]` OR `[https://github.com/YOU/solo-dev-ai-kit]`

## This app project

- **Target:** current workspace (the app — do not modify the kit repo itself)
- **GitHub repo:** `[owner/repo]`
- **Stack:** `[Flutter / Next.js / …]`
- **Branches:** auto-detect from `git branch -a` — `dev`→`main` if `dev` exists, else **single branch** (`main`/`master`). Or pass `--main-only`.
- **CI:** `[flutter test / npm test / pytest]`
- **AI tools:** pick any — `[cursor,antigravity]` (usual) or add `codex,claude,gemini`
- **Client reports:** `[yes / no]`
- **Run GitHub setup:** `[yes / no]`

## Platform rules (official)

- **AGENTS.md** = single canonical workflow (always installed)
- **Cursor** → `.cursor/rules/*.mdc` with `alwaysApply: true`
- **Antigravity** → `.agents/rules/*.md` with `trigger: always_on`
- **Codex** → reads `AGENTS.md` only (no CODEX.md)
- **Claude Code** → minimal `CLAUDE.md` stub pointing to AGENTS.md
- **Gemini CLI** → `.gemini/settings.json` + minimal `GEMINI.md` stub

## Do

1. Run `solo-dev-ai-kit/bootstrap.sh` with flags above.
2. If needed: `gh auth refresh -h github.com -s repo,project,read:project`
3. Summarize installed files per platform.
4. Confirm triage smoke test (no coding on fake bug).

Do **not** implement app features.

---

## Ultra-short (kit on disk)

```text
/path/to/solo-dev-ai-kit/bootstrap.sh --target . --repo OWNER/REPO --tools cursor,antigravity --run-github-setup
```

## All platforms at once

```text
--tools cursor,antigravity,codex,claude,gemini
```

## Smoke test

> Login redirect loop after token refresh

Expect: GitHub issue + AC + *which # first?* — no code changes.
