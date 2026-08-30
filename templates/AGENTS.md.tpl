# Agent & maintainer guide ({{PROJECT_TITLE}})

**Single source of truth** for humans and AI agents. Platform-specific files only point here — they do not duplicate rules.

**Active tools (this repo):** {{WORKFLOW_TOOLS_LIST}}

| Platform | Official instruction file | Role in this repo |
|----------|---------------------------|-------------------|
| **All / Codex** | `AGENTS.md` | **Canonical** — full workflow (this file) |
| **Cursor** | `AGENTS.md` + `.cursor/rules/*.mdc` | Thin router rule (`alwaysApply: true`) |
| **Antigravity** | `.agents/rules/*.md` | Thin pointer (`trigger: always_on`) |
| **Claude Code** | `CLAUDE.md` | Stub → read `AGENTS.md` |
| **Gemini CLI** | `AGENTS.md` (+ optional `GEMINI.md`) | Auto-discovered; stub optional |

See `docs/agent-platforms.md` for official doc links.

## Git & deploy

{{GIT_DEPLOY_SECTION}}

## Changelog (`CHANGELOG.md`)

- **`## [Unreleased]`** — user-relevant changes on integration branch.
- Version blocks — what shipped on **`{{PRODUCTION_BRANCH}}`**.
- Use `### Added` / `### Changed` / `### Fixed` / `### Removed`.

## Intent router (default)

Classify every user message before acting:

| Intent | Action |
|--------|--------|
| Question / exploration | Answer only — no issue, no code |
| **Tiny** (typo, copy, one-file CSS, obvious fix) | Implement + self-verify; say *skipped issue* |
| Feature / bug / improvement (no `#N`) | **Phase 1 Triage** → stop |
| `Implement #N` / `kerjakan #N` / `LGTM #N` | **Phase 2 Implement** |
| *works* / *ok* / *sudah work* for `#N` | **Phase 3 Close-out** (human QA) |

**Tiny** = one clear outcome, ≤1–2 files, no new behavior contract. When unsure, triage instead.

**Skip triage:** user names `#N`, says *skip issue* / *just fix*, or asks a question only.

## Phase 1 — Triage (no coding)

1. Investigate codebase (read-only).
2. `gh issue list --repo {{GH_REPO}} --state open --search "…"`
3. If duplicate → link it; do not create another.
4. New issue via `./scripts/gh-triage-issue.sh`:
   - Title: `[Bug]:` / `[Feature]:`
   - Body: follow `docs/issue-body.example.md` — must include `## Acceptance criteria` with `- [ ]` lines
   - Labels: `bug` / `enhancement`; `priority:high|medium|low`; `client-facing` if user-visible
5. Board: script adds to project; `./scripts/gh-set-issue-status.sh N backlog` if needed.
6. Reply with issue URL; **stop**.

End with: *"Review the issue; tell me which # to implement first."*

## Phase 2 — Implement

Triggers: *Implement #N*, *kerjakan #N*, *LGTM #N*.

1. Read acceptance criteria from issue `#N`.
2. **Plan before code** if >1 file or new user-facing behavior — short plan (files, risks, tests); ask LGTM unless user already said implement.
3. Branch: `feat/#N-slug` or `fix/#N-slug`.
4. Focused diff; update `CHANGELOG.md` if user-facing.
5. `./scripts/gh-set-issue-status.sh N progress`
6. **Self-verify** (required before claiming done) — see below.
7. `./scripts/gh-set-issue-status.sh N qa` when self-verify passes or stops at gate.
8. PR: `Fixes #N`. Commits only when user asks (or user says *commit* / *PR*).

Do **not** close the issue after self-verify. Human QA (`sudah work`) closes it.

## Phase 3 — Close-out (human QA)

Triggers: user confirms *works* / *ok* / *sudah work* for **#N**.

1. Verify AC against code/commits (read-only).
2. `./scripts/gh-close-verified-issue.sh N --comment-file …` (checks AC, comments, closes issue, sets board **Done**).

Use `--no-close` only if user explicitly wants comment-only.

## Self-verify (agent definition of done)

Required before saying *siap QA* / *implemented*. Two QA layers:

- **Agent DoD** — evidence against AC (this section).
- **Human QA** — user says *sudah work* → Phase 3.

### Classify work

- **UI / UX** — layout, routing, forms, visible state.
- **Non-UI** — API, scripts, data, CI.
- **Mixed** — run tests first, then UI flows touched.

### UI evidence

Screenshot alone is **not** verification. You must:

1. Open app using `docs/how-to-run.md` (local URL + start command).
2. Run the **changed flow** end-to-end (click, type, submit, navigate).
3. Check **related routes/pages** for regressions.
4. Cover AC edge cases (empty, error, flags; mobile if layout changed).

**Browser tools (priority):**

1. **Cursor IDE browser** (native MCP) — no extra install.
2. **Playwright CLI/MCP** — only if already in project/device; never auto-install.
3. **Existing project tests** (Puppeteer, component tests) — use if present.
4. If none available: nearest substitute + **state what was not verified**.

**Non-web apps (Flutter, etc.):** use project test/emulator commands; do not force Playwright.

### Non-UI evidence

- Run relevant tests (`{{CI_TEST_COMMAND}}` or focused subset).
- Typecheck/lint when contracts change.
- API: real requests (curl/script) including error paths in AC.

### Loop gate (max 3 rounds)

One round = implement/patch → verify → pass or fail.

- **Max 3 rounds** per task.
- Stop early if: AC met; **same failure twice**; blocker (login, env, server down); remaining gap is **taste** (spacing, tone) — human decides.
- Each round needs a new hypothesis, not random tweaks.
- After stop: report what was proven, gaps vs AC, last evidence, what you need from the user.

## Merge & push (when user asks)

{{MERGE_PUSH_SECTION}}

Before merge/push: run `git branch -a`. Use `.workflow-kit.env` (`SINGLE_BRANCH`, `INTEGRATION_BRANCH`, `PRODUCTION_BRANCH`). Never invent branches.

## Session start (optional)

If the user has not given a task, briefly list open issues with **Focus = This week** or **In Progress** on the board.

## Project constants

| Key | Value |
|-----|--------|
| Repo | `{{GH_REPO}}` |
| Project | `{{PROJECT_TITLE}}` — {{PROJECT_BOARD_URL}} |
| CI test | `{{CI_TEST_COMMAND}}` |
| Scripts | `gh-triage-issue.sh`, `gh-close-verified-issue.sh`, `gh-set-issue-status.sh`, `gh-validate-issue-body.sh` |

## Related

- `docs/github-workflow.md` — board & daily flow
- `docs/agent-platforms.md` — per-platform official setup
- `docs/how-to-run.md` — dev server URL, tests, test accounts (fill in for this app)
- `.workflow-kit.env` — repo config (generated by bootstrap)
