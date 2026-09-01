# Troubleshooting ({{PROJECT_TITLE}})

Common issues when using solo-dev + AI workflow scripts.

## `gh` authentication

**Symptom:** `gh: authentication required` or missing `project` scope.

```bash
gh auth status
gh auth refresh -h github.com -s repo,project,read:project
```

## `GH_PROJECT_NUM` unset / issue not on board

**Symptom:** `Note: GH_PROJECT_NUM unset` or `gh-set-issue-status.sh` does nothing.

```bash
./scripts/gh-setup-project.sh {{GH_REPO}}
# or full setup:
./scripts/gh-setup-all.sh
```

Check `.workflow-kit.env` — `GH_PROJECT_NUM` should be a number. Re-run setup if empty.

## QA column missing on board

**Symptom:** Cannot set status to `qa`.

```bash
./scripts/gh-ensure-project-status-qa.sh
```

Reorder columns in GitHub: Project → … → Fields → Status if needed.

## Triage fails: acceptance criteria

**Symptom:** `body must include '## Acceptance criteria'`.

Issue body must match `docs/issue-body.example.md`:

```markdown
## Acceptance criteria

- [ ] First criterion
```

Use `./scripts/gh-validate-issue-body.sh --body-file /tmp/body.md` before create.

## UI verification

### Web — browser cannot reach app

1. Fill `docs/how-to-run.md` — **Local URL** and **Start command** (replace all `TBD`).
2. Start dev server before verify.
3. Run `./scripts/gh-check-ui-tools.sh`.

Kit **never** auto-installs Playwright. Cursor IDE browser is default in Cursor.

### Mobile — Flutter / native

1. Set `APP_STACK=mobile` in `.workflow-kit.env` (or bootstrap `--app-stack mobile`).
2. Fill emulator + test commands in `docs/how-to-run.md`.
3. **MobAI** (optional): install from [mobai.run](https://mobai.run), open simulator, run `npx mobai-mcp`. Not installed by kit.

### Agent verifies too much (token usage)

- Default: **AC scope only** — not full app.
- Say *max 2 rounds* for one issue, or set `VERIFY_MAX_ROUNDS` in `.workflow-kit.env`.
- Full E2E only when you explicitly ask.

## Re-bootstrap without losing custom docs

See **`docs/updating-workflow-kit.md`** for the full update flow when the kit repo has new releases.

```bash
/path/to/solo-dev-ai-kit/bootstrap.sh --target . --repo {{GH_REPO}} --tools cursor,antigravity
```

Without `--force`: keeps your `AGENTS.md` and `docs/how-to-run.md`. Use `--force` to overwrite.

## Board URL still placeholder in docs

Run GitHub setup, then re-render or edit `AGENTS.md` / `docs/github-workflow.md` so `{{PROJECT_BOARD_URL}}` is replaced — or run bootstrap with `--run-github-setup` once.

## Still stuck?

1. `cat .workflow-kit.env`
2. `./scripts/gh-check-ui-tools.sh`
3. `gh issue view N --repo {{GH_REPO}}`
4. See `scripts/README.md` for script flags
