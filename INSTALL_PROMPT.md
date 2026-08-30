# Install prompt — paste to your AI agent

Open your **app project** in Cursor (Agent mode). Paste the block below. **You do not need to run terminal commands yourself** — the agent runs them.

Adjust `[brackets]` once, then send.

---

Install **solo-dev-ai-kit** into this project. I am not running terminal commands myself — you run everything.

## Kit source

- Clone if missing: `https://github.com/sahibul-nf/solo-dev-ai-kit` → use `~/solo-dev-ai-kit` or `/tmp/solo-dev-ai-kit`
- Or use existing path: `[path/to/solo-dev-ai-kit]`

## This project

| Setting | Value |
|---------|--------|
| **Target** | current workspace (the app — do **not** modify the kit repo) |
| **GitHub repo** | `[owner/repo]` or auto-detect from `git remote` |
| **Stack** | `[Next.js / Flutter / …]` |
| **AI tools** | `[cursor,antigravity]` (recommended) or `cursor,antigravity,codex,claude,gemini` |
| **CI test command** | `[npm test / flutter test / pytest]` |
| **Branches** | auto-detect (`dev`→`main` if `dev` exists; else single branch). Or `--main-only` |
| **GitHub setup** | `[yes / no]` — labels, project board, QA column |
| **Client reports** | `[yes / no]` — `client-facing` label |

## What you must do

1. **Prerequisites** — check `gh` and `jq`; if missing, tell me what to install. If `gh` lacks scopes, run `gh auth refresh -h github.com -s repo,project,read:project`.
2. **Bootstrap** — run `bootstrap.sh` from the kit with flags above. Example:

   ```bash
   /path/to/solo-dev-ai-kit/bootstrap.sh \
     --target . \
     --repo OWNER/REPO \
     --tools cursor,antigravity \
     --ci-test "npm test" \
     --run-github-setup
   ```

3. **Do not overwrite** my custom `AGENTS.md` or `docs/how-to-run.md` unless I say `--force`.
4. **Fill in** `docs/how-to-run.md` — local dev URL, start command, test command, test accounts (no secrets in git).
5. **Report** `./scripts/gh-check-ui-tools.sh` output (check only — never install Playwright/Chromium).
6. **Summarize** what was installed per platform and where the project board URL is.
7. **Smoke test** — triage only (no code): *"Login redirect loop after token refresh"*. Expect: issue + acceptance criteria + *which # first?*

Do **not** implement app features. Stop after install + smoke test summary.

---

## Ultra-short (kit already on disk)

```text
Install solo-dev-ai-kit into this project. Run bootstrap.sh from [path/to/solo-dev-ai-kit] with --tools cursor,antigravity --run-github-setup. Fill docs/how-to-run.md. Do not code app features.
```

## Ultra-short (clone from GitHub)

```text
Clone https://github.com/sahibul-nf/solo-dev-ai-kit, bootstrap into this project (--tools cursor,antigravity --run-github-setup), fill docs/how-to-run.md, smoke-test triage only. I won't run terminal commands — you do.
```

## After install

| I say | AI does |
|-------|---------|
| Describe a bug/feature | Triage → issue → board |
| `Implement #N` | Code → self-verify → QA |
| `sudah work #N` | Close issue → Done |

See `AGENTS.md` in the project for full workflow.
