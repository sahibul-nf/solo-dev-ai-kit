# Workflow scripts

Shell helpers for GitHub Issues + Project board. All scripts load `.workflow-kit.env` from the repo root.

**Full workflow:** `AGENTS.md` · **Daily flow:** `docs/github-workflow.md` · **Problems:** `docs/troubleshooting.md`

## Quick reference

| Script | When to use |
|--------|-------------|
| `gh-triage-issue.sh` | Create issue + add to board (Phase 1 triage) |
| `gh-validate-issue-body.sh` | Check body has `## Acceptance criteria` + `- [ ]` (called by triage) |
| `gh-set-issue-status.sh` | Move issue on Kanban: `backlog` · `progress` · `qa` · `done` |
| `gh-close-verified-issue.sh` | After human QA: check AC, comment, close issue, set **Done** |
| `gh-check-ui-tools.sh` | Report web/mobile verify tools (check only — never installs) |
| `gh-setup-all.sh` | One-shot: labels + project board + QA column |
| `gh-setup-project.sh` | Create/link project; writes `GH_PROJECT_NUM` to `.workflow-kit.env` |
| `gh-configure-project.sh` | Board title, Priority/Focus fields, sync from labels |
| `gh-create-labels.sh` | Standard labels (`bug`, `enhancement`, `priority:*`) |
| `gh-ensure-project-status-qa.sh` | Add **QA** column before **Done** (run once if missing) |

## Examples

```bash
# Triage
./scripts/gh-triage-issue.sh \
  --title "[Bug]: Login redirect loop" \
  --body-file /tmp/issue-body.md \
  --labels "bug,priority:high"

# Board status (during implement / QA)
./scripts/gh-set-issue-status.sh 12 progress
./scripts/gh-set-issue-status.sh 12 qa

# Close after user says "sudah work #12"
./scripts/gh-close-verified-issue.sh 12 --comment-file /tmp/close-12.md

# Check UI tools (no install)
./scripts/gh-check-ui-tools.sh
```

## Flags & behavior

### `gh-close-verified-issue.sh`

| Flag | Effect |
|------|--------|
| `--comment-file PATH` | Closing comment from file (use `docs/close-comment.example.md` as template) |
| `--comment "text"` | Closing comment inline |
| `--no-check-ac` | Skip checking AC boxes in issue body |
| `--no-close` | Comment only — do not close issue or set board Done |

**Exit:** `0` on success; `1` on missing args or `gh` failure.

### `gh-set-issue-status.sh`

| Status | Kanban column |
|--------|----------------|
| `backlog` | Backlog |
| `progress` | In Progress |
| `qa` | QA |
| `done` | Done |

If `GH_PROJECT_NUM` is unset: prints a note and **exits 0** (no-op) — issue is not on a board yet. Run `./scripts/gh-setup-project.sh`.

### `gh-triage-issue.sh`

Runs `gh-validate-issue-body.sh` before create. Duplicate open issues with the same title return existing URL and exit `0`.

## Prerequisites

```bash
brew install gh jq
gh auth login
gh auth refresh -h github.com -s repo,project,read:project
```

See `docs/troubleshooting.md` if something fails.
