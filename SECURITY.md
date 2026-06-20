# Security

## This repository

`solo-dev-ai-kit` is a **public template** — workflow scripts, agent rules, and documentation only.

- **No API keys, tokens, or credentials** belong in this repo.
- **No client or production app code** — bootstrap targets are separate repositories.
- Scripts use the local **`gh` CLI** with credentials stored on your machine (`gh auth login`), not in the repo.

If you find a security issue in this kit, open a [private security advisory](https://github.com/sahibul-nf/solo-dev-ai-kit/security/advisories/new) or email the repo owner. Do not post exploit details in public issues.

## After you bootstrap a project

Files written into **your app repo** by `bootstrap.sh`:

| File | Safe to commit? | Notes |
|------|-----------------|--------|
| `AGENTS.md`, rules, `docs/` | Yes | Instructions only |
| `.workflow-kit.env` | Yes* | Repo name, branch names, project title — **no tokens** |
| `.workflow-kit/installed` | Yes | Metadata only |
| `scripts/gh-*.sh` | Yes | Shell scripts; no embedded secrets |

\*If you add custom secrets to `.workflow-kit.env`, **do not commit** — use `.workflow-kit.local.env` (gitignored) or environment variables instead.

### Never commit to any repo

- `.env` with API keys, database URLs with passwords, `GH_TOKEN`, `SUPABASE_*` secrets
- `credentials.json`, `*.pem`, `*.key`
- `.cursor/` or IDE files containing auth tokens (if your editor stores them locally, keep them gitignored)

### `gh` authentication

- Tokens live in the **system keyring** / `gh` config on your device — not in this kit.
- Required scopes for board scripts: `repo`, `project`, `read:project`
- Use `gh auth status` to verify; never paste tokens into chat or commit them.

## Dependency surface

This kit is **bash + templates** only (no `npm`, `pub`, or lockfiles). There are no third-party runtime dependencies to audit in the kit itself. Your **target app** keeps its own dependency security practices.
