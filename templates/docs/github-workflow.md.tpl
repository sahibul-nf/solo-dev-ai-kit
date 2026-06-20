# GitHub workflow ({{PROJECT_TITLE}})

Solo dev + AI: **Issues**, **Projects**, and agent rules stay in sync.

## Issues

- **One issue = one shippable outcome** with acceptance criteria.
- Labels: `bug`, `enhancement`, `priority:high|medium|low`, `client-facing` (optional).
- Templates: `.github/ISSUE_TEMPLATE/`
- Link PRs: `Fixes #NNN`

## Project board

Board: **{{PROJECT_TITLE}}** — {{PROJECT_BOARD_URL}}

### Kanban Status

**Backlog → In Progress → QA → Done**

Run once if QA column missing:

```bash
./scripts/gh-ensure-project-status-qa.sh
```

### Custom fields

| Field | Values |
|-------|--------|
| **Priority** | High · Medium · Low |
| **Focus** | This week · Backlog · Icebox |

Filter **Focus = This week** for your sprint.

## Daily workflow

1. Pick **This week** issue → **In Progress**.
2. Branch → PR `Fixes #N` → merge when ready.
3. **QA** on staging until verified.
4. Confirm *works* → AI runs `gh-close-verified-issue.sh` → **Done**.

## CI & deploy

{{CI_DEPLOY_SECTION}}

## Default AI behavior

**You:** describe a bug or feature.

**AI:** triage → issue → board → *"Review #N; which first?"*

**You:** *Implement #5.*

**AI:** code + PR (no new issue).

Setup scripts: `./scripts/gh-setup-all.sh`

## AI tools

Configured tools: **{{WORKFLOW_TOOLS_LIST}}**

See `AGENTS.md` for triage phases. Re-bootstrap from **solo-dev-ai-kit** (`MASTER_PROMPT.md`).
