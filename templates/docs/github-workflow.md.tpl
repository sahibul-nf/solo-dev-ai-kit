# GitHub workflow ({{PROJECT_TITLE}})

Solo dev + AI: **Issues**, **Projects**, and agent rules stay in sync.

## Issues

- **One issue = one shippable outcome** with acceptance criteria.
- Labels: `bug`, `enhancement`, `priority:high|medium|low`, `client-facing` (optional).
- Templates: `.github/ISSUE_TEMPLATE/`
- Body template for AI: `docs/issue-body.example.md`
- Link PRs: `Fixes #NNN`

## Project board

Board: **{{PROJECT_TITLE}}** — {{PROJECT_BOARD_URL}}

### Kanban Status

**Backlog → In Progress → QA → Done**

```bash
./scripts/gh-set-issue-status.sh <N> backlog|progress|qa|done
```

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

1. Pick **This week** issue → **In Progress** (`gh-set-issue-status.sh N progress`).
2. Branch `feat/#N-slug` → implement → self-verify → **QA** on board.
3. PR `Fixes #N` → merge when ready.
4. You confirm *works* → AI runs `gh-close-verified-issue.sh` → issue closed + **Done**.

## CI & deploy

{{CI_DEPLOY_SECTION}}

## Default AI behavior

| You say | AI does |
|---------|---------|
| Describe bug/feature | Triage → issue → board → *which # first?* |
| *Implement #5* | Code → self-verify → board **QA** |
| *sudah work #5* | Close issue → board **Done** |
| Tiny fix / *skip issue* | Fix + verify (no issue) |

Setup scripts: `./scripts/gh-setup-all.sh`

## AI tools

Configured tools: **{{WORKFLOW_TOOLS_LIST}}**

Re-run bootstrap from **solo-dev-ai-kit** (`MASTER_PROMPT.md` or `INSTALL_PROMPT.md` — paste to AI; no terminal needed from you).
