# {{PROJECT_TITLE}} — dev board

Solo dev + AI workflow for **{{GH_REPO}}**.

## Daily rhythm

1. Open **Kanban** — pick **Focus = This week** (or move one from Backlog).
2. Drag **Status** to *In Progress* → branch `feat/#N-slug` → implement → self-verify → **QA**.
3. PR with `Fixes #N` → merge when ready.
4. Confirm *works* → AI runs `./scripts/gh-close-verified-issue.sh` → issue closed + **Done**.
5. **Push `{{INTEGRATION_BRANCH}}` before `{{PRODUCTION_BRANCH}}`** when CI tests only run on integration branch.
6. User-visible work → `CHANGELOG.md` when it matters.

## Status (Kanban)

| Status | When | Script |
|--------|------|--------|
| **Backlog** | Not started | `gh-set-issue-status.sh N backlog` |
| **In Progress** | Active branch | `gh-set-issue-status.sh N progress` |
| **QA** | Self-verify done — human checks | `gh-set-issue-status.sh N qa` |
| **Done** | Human confirmed *works* | `gh-close-verified-issue.sh N …` |

If **QA** is missing: `./scripts/gh-ensure-project-status-qa.sh`

## Custom fields

| Field | Values |
|-------|--------|
| **Priority** | High · Medium · Low |
| **Focus** | This week · Backlog · Icebox |

## Links

- [Repo issues](https://github.com/{{GH_REPO}}/issues)
- [github-workflow.md](https://github.com/{{GH_REPO}}/blob/{{PRODUCTION_BRANCH}}/docs/github-workflow.md)
- [how-to-run.md](https://github.com/{{GH_REPO}}/blob/{{PRODUCTION_BRANCH}}/docs/how-to-run.md)

## AI prompts

- Triage: describe bug/feature (or `/triage` in Cursor)
- `Implement #N` — code + self-verify → QA
- `sudah work #N` — close-out
