---
description: Route to AGENTS.md — classify intent; do not code unless tiny, #N, or skip issue.
alwaysApply: true
---

# Workflow router

**Canonical rules:** read `AGENTS.md` in full. Do not duplicate workflow here.

## Before you act

1. **Classify intent** (question · tiny fix · triage · implement `#N` · close-out · **kit update** · merge/push).
2. **Questions** → answer only.
3. **Tiny** (≤1–2 files, obvious) → implement + self-verify per `AGENTS.md`; say *skipped issue*.
4. **Feature/bug/improvement** without `#N` → Phase 1 triage only; **no code**.
5. **`Implement #N` / `kerjakan #N`** → Phase 2; self-verify before claiming done; board → QA.
6. **`sudah work` / `ok` for `#N`** → Phase 3 close-out script.
7. **`update workflow kit` / `/update`** → read `docs/update-prompt.md` + `docs/updating-workflow-kit.md`; dry-run bootstrap, then apply without `--force`.

Repo: `{{GH_REPO}}` · Board: {{PROJECT_BOARD_URL}}
