# Solo Dev + AI Workflow Kit

Portable bootstrap for **issue triage → implement on approval → close after QA**.

**Kit releases:** see **[CHANGELOG.md](CHANGELOG.md)** (`kit_version` in `.workflow-kit/installed` after bootstrap).

**Design:** one canonical `AGENTS.md` + platform-native files per [official docs](#platform-setup-official-standards).

## Platform setup (official standards)

| Platform | Official file | This kit installs |
|----------|---------------|-------------------|
| **Codex** | `AGENTS.md` | Uses root `AGENTS.md` only — no `CODEX.md` |
| **Cursor** | `AGENTS.md` + `.cursor/rules/*.mdc` | Thin router rule + slash commands |
| **Antigravity** | `.agents/rules/*.md` | `trigger: always_on` rules → point to `AGENTS.md` |
| **Claude Code** | `CLAUDE.md` | Minimal stub: “follow `AGENTS.md`” |
| **Gemini CLI** | `GEMINI.md` / `AGENTS.md` | `.gemini/settings.json` + optional `GEMINI.md` stub |

Docs: [agents.md](https://agents.md/) · [Cursor rules](https://cursor.com/docs/context/rules) · [Claude memory](https://code.claude.com/docs/en/memory) · [Gemini GEMINI.md](https://github.com/google-gemini/gemini-cli/blob/main/docs/cli/gemini-md.md)

**Primary combo (recommended):** `--tools cursor,antigravity`  
**All platforms (future-proof):** default — `cursor,antigravity,codex,claude,gemini`

## Quick start

### Option A — Install via AI prompt (recommended)

You do **not** need to run terminal commands yourself. Open your **app project** in Cursor Agent mode and paste a prompt from:

- **[INSTALL_PROMPT.md](INSTALL_PROMPT.md)** (English)
- **[INSTALL_PROMPT.id.md](INSTALL_PROMPT.id.md)** (Bahasa Indonesia)

Or paste this one-liner:

```text
Clone https://github.com/sahibul-nf/solo-dev-ai-kit, bootstrap solo-dev-ai-kit into this project (--tools cursor,antigravity --run-github-setup), fill docs/how-to-run.md, smoke-test triage only. I won't run terminal commands — you do.
```

The agent clones the kit (if needed), runs `bootstrap.sh`, fills `docs/how-to-run.md`, and reports what was installed.

See also [MASTER_PROMPT.md](MASTER_PROMPT.md) for a customizable template.

### Option B — Install via terminal

```bash
git clone https://github.com/sahibul-nf/solo-dev-ai-kit.git
cd solo-dev-ai-kit

# Personal project — Cursor + Antigravity only
./bootstrap.sh \
  --target /path/to/my-app \
  --repo you/my-app \
  --tools cursor,antigravity \
  --ci-test "npm test" \
  --run-github-setup

# Or install all platform configs at once (default --tools)
./bootstrap.sh --target /path/to/my-app --repo you/my-app
```

### Prerequisites (once per device)

```bash
brew install gh jq
gh auth login
gh auth refresh -h github.com -s repo,project,read:project
```

## What gets installed

```
your-project/
├── AGENTS.md                 # Canonical (all agents)
├── docs/
│   ├── github-workflow.md    # Cheatsheet + daily flow
│   ├── agent-platforms.md
│   ├── how-to-run.md         # Replace TBD — dev URL / emulator / tests
│   ├── troubleshooting.md
│   ├── updating-workflow-kit.md
│   ├── orchestrator-integration.md  # Optional Paperclip-style board polling
│   ├── update-prompt.md      # Agent checklist for kit refresh (/update)
│   ├── uninstalling-workflow-kit.md
│   ├── uninstall-prompt.md   # Agent checklist for uninstall
│   └── close-comment.example.md
├── .cursor/rules/            # if cursor
├── .cursor/commands/         # if cursor (/triage, /implement, /verify, /close, /update, /uninstall)
├── .agents/rules/            # if antigravity
├── CLAUDE.md                 # if claude (stub)
├── GEMINI.md + .gemini/      # if gemini
├── .workflow-kit.env
├── scripts/
│   ├── README.md             # All gh-*.sh — flags & examples
│   └── gh-*.sh
└── .github/ISSUE_TEMPLATE/
```

Codex needs **no extra file** — it reads `AGENTS.md` natively.

## Managed files & safe uninstall (v12+)

Bootstrap stamps kit-generated files with `solo-dev-ai-kit:managed` (or `partial-managed` on `AGENTS.md`) and writes `.workflow-kit/manifest`. Uninstall uses the manifest + markers so customized files are not deleted. Run `./scripts/verify-kit-managed.sh` in the app project to audit.

## Uninstall (local files only)

Does **not** delete GitHub Issues, Project board, or labels.

```bash
/path/to/solo-dev-ai-kit/uninstall-workflow-kit.sh --target /path/to/your-app --dry-run
/path/to/solo-dev-ai-kit/uninstall-workflow-kit.sh --target /path/to/your-app
```

Or paste **[UNINSTALL_PROMPT.md](UNINSTALL_PROMPT.md)** (or [.id](UNINSTALL_PROMPT.id.md)) into Cursor Agent mode.

## Re-bootstrap / add a platform later

See **[UPDATE_PROMPT.md](UPDATE_PROMPT.md)** (or [.id](UPDATE_PROMPT.id.md)) to pull kit updates into an existing project. After bootstrap, the app project also has `docs/update-prompt.md` and `docs/updating-workflow-kit.md`.

**Via AI:** open the app project and say:

```text
Update workflow kit to the latest version
```

Or use Cursor slash command **`/update`**. The agent follows `AGENTS.md` → dry-run bootstrap, then apply without `--force`.

**Via terminal:**

```bash
/path/to/solo-dev-ai-kit/bootstrap.sh \
  --target . \
  --repo you/my-app \
  --tools cursor,antigravity,claude
```

## Flags

| Flag | Default | Description |
|------|---------|-------------|
| `--target` | cwd | Project directory |
| `--repo` | from `git remote` | `owner/name` |
| `--tools` | all five | `cursor,antigravity,codex,claude,gemini` |
| `--main-only` | off | Single branch — auto-detect `main` or `master` |
| `--integration-branch` | auto | Uses `dev` if it exists, else production branch |
| `--production-branch` | `main` | Deploy branch |
| `--ci-test` | `run tests` | CI command label in docs |
| `--project-title` | `{repo} delivery` | GitHub Project name |
| `--client-reports` | off | `client-facing` label |
| `--run-github-setup` | off | Run `gh-setup-all.sh` |
| `--force` | off | Overwrite `AGENTS.md` (drops project-specific sections) and `docs/how-to-run.md` |
| `--app-stack` | auto | `web` · `mobile` · `both` — auto: `pubspec.yaml` → mobile, else web |
| `--verify-max-rounds` | `3` | Max self-verify loops per task (override per issue in chat) |

## Workflow (3 phases + board Status)

1. **Triage** — describe work → issue + **Backlog** → stop (never **Ready for AI** automatically)
2. **Implement** — `Implement #N` or orchestrator picks **Ready for AI** → **AI Working** → self-verify → **AI Review**
3. **Close-out** — human reviews PR → `sudah work` → `gh-close-verified-issue.sh` → **Done**

**Authorization:** GitHub Project **Status** (not labels). See `docs/orchestrator-integration.md` for optional Paperclip-style polling.

**Intent router:** tiny fixes skip issue; real work gets AC checklist. See `AGENTS.md`.

**UI verify:** AC scope only (not full app unless you ask). Web → Cursor browser; mobile → tests + optional [MobAI](https://mobai.run). Kit checks, never auto-installs.

## Publish

Standalone repo — not inside any client app. `git init` → push → bootstrap on other devices.

## Origin

Workflow patterns from solo-dev production practice; maintained separately from client repos.

## Security

Templates and scripts only — **no secrets** in this repo. See [SECURITY.md](SECURITY.md).

- `.workflow-kit.env` = repo metadata (safe to commit); never put tokens there.
- `gh` auth stays on your device (`gh auth login`).
- Report issues: [Security Advisories](https://github.com/sahibul-nf/solo-dev-ai-kit/security/advisories/new).
