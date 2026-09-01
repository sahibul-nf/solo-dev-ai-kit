# Updating the workflow kit ({{PROJECT_TITLE}})

When [solo-dev-ai-kit](https://github.com/sahibul-nf/solo-dev-ai-kit) releases updates, refresh this project with **re-bootstrap** — there is no separate updater binary.

## Check your version

```bash
cat .workflow-kit/installed
# kit_version=8
# tools=cursor,antigravity
# app_stack=mobile
```

Compare with the latest kit repo after `git pull`.

## Safe update (recommended)

```bash
cd /path/to/solo-dev-ai-kit && git pull

cd /path/to/your-app

# Preview changes (no writes):
/path/to/solo-dev-ai-kit/bootstrap.sh --target . --dry-run

# Apply:
/path/to/solo-dev-ai-kit/bootstrap.sh --target .
```

If `.workflow-kit.env` exists, bootstrap **merges** your settings automatically (`GH_PROJECT_NUM`, branches, tools, `CI_TEST_COMMAND`, `APP_STACK`, `VERIFY_MAX_ROUNDS`, etc.). Pass CLI flags only when you want to **override** a value.

A backup is saved to `.workflow-kit/env.backup` before the env file is rewritten.

**Without `--force`:**

| Always refreshed | Preserved if you customized |
|------------------|----------------------------|
| `scripts/*.sh`, `scripts/README.md` | `AGENTS.md` |
| `.cursor/rules`, `.cursor/commands` | `docs/how-to-run.md` |
| `docs/github-workflow.md`, `docs/troubleshooting.md` | |
| `docs/updating-workflow-kit.md`, `docs/update-prompt.md` | |
| `docs/close-comment.example.md`, issue templates | |
| `.workflow-kit/installed` (`kit_version`) | |

After update: review `git diff`. If `AGENTS.md` was skipped, read what changed in the kit's `templates/AGENTS.md.tpl` and merge important rules manually.

## Full overwrite

Only if you want the latest kanon and are OK losing local edits to workflow docs:

```bash
./bootstrap.sh --target . --force
```

## Via AI (no terminal yourself)

Any of these work in Cursor Agent mode:

- Say **update workflow kit** or **perbarui workflow kit** (routed in `AGENTS.md`).
- Run slash command **`/update`** (if Cursor commands installed).
- Paste **`docs/update-prompt.md`** (English) or **`docs/update-prompt.id.md`** (Bahasa Indonesia).

The agent reads this file + `docs/update-prompt.md`, dry-runs bootstrap, then applies without `--force`.

## What re-bootstrap does **not** do

- Does **not** reset `GH_PROJECT_NUM` or `GH_PROJECT_OWNER` (merged from existing env).
- Does not re-detect git branches if they were already configured (unless you pass branch flags or `--main-only`).
- Does not run GitHub setup unless you pass `--run-github-setup`.
- Does not change your app source code.

## After updating

```bash
grep GH_PROJECT_NUM .workflow-kit.env
./scripts/gh-check-ui-tools.sh
git diff AGENTS.md docs/ scripts/
```

See also `docs/troubleshooting.md`.
