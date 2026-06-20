# Solo Dev + AI Workflow Kit

Portable bootstrap for **issue triage → implement on approval → close after QA**.

**Design:** one canonical `AGENTS.md` + platform-native files per [official docs](#platform-setup-official-standards).

## Platform setup (official standards)

| Platform | Official file | This kit installs |
|----------|---------------|-------------------|
| **Codex** | `AGENTS.md` | Uses root `AGENTS.md` only — no `CODEX.md` |
| **Cursor** | `AGENTS.md` + `.cursor/rules/*.mdc` | Both — triage rule with `alwaysApply: true` |
| **Antigravity** | `.agents/rules/*.md` | `trigger: always_on` rules → point to `AGENTS.md` |
| **Claude Code** | `CLAUDE.md` | Minimal stub: “follow `AGENTS.md`” |
| **Gemini CLI** | `GEMINI.md` / `AGENTS.md` | `.gemini/settings.json` + optional `GEMINI.md` stub |

Docs: [agents.md](https://agents.md/) · [Cursor rules](https://cursor.com/docs/context/rules) · [Claude memory](https://code.claude.com/docs/en/memory) · [Gemini GEMINI.md](https://github.com/google-gemini/gemini-cli/blob/main/docs/cli/gemini-md.md)

**Primary combo (recommended):** `--tools cursor,antigravity`  
**All platforms (future-proof):** default — `cursor,antigravity,codex,claude,gemini`

## Quick start

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
│   ├── github-workflow.md
│   └── agent-platforms.md    # Per-platform official setup
├── .cursor/rules/              # if cursor
├── .agents/rules/              # if antigravity
├── CLAUDE.md                   # if claude (stub only)
├── GEMINI.md + .gemini/        # if gemini
├── .workflow-kit.env
├── scripts/gh-*.sh
└── .github/ISSUE_TEMPLATE/
```

Codex needs **no extra file** — it reads `AGENTS.md` natively.

## Re-bootstrap / add a platform later

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

## Workflow (3 phases)

1. **Triage** — describe work → issue + board → stop
2. **Implement** — `Implement #N`
3. **Close-out** — `sudah work` → `gh-close-verified-issue.sh`

## Publish

Standalone repo — not inside any client app. `git init` → push → bootstrap on other devices.

## Origin

Workflow patterns from solo-dev production practice; maintained separately from client repos.

## Security

Templates and scripts only — **no secrets** in this repo. See [SECURITY.md](SECURITY.md).

- `.workflow-kit.env` = repo metadata (safe to commit); never put tokens there.
- `gh` auth stays on your device (`gh auth login`).
- Report issues: [Security Advisories](https://github.com/sahibul-nf/solo-dev-ai-kit/security/advisories/new).
