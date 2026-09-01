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
| `update workflow kit` / `update solo-dev-ai-kit` / `/update` / *perbarui workflow kit* | **Kit update** — follow `docs/updating-workflow-kit.md` + `docs/update-prompt.md` |

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
2. Write closing comment using `docs/close-comment.example.md` as template.
3. `./scripts/gh-close-verified-issue.sh N --comment-file …` (checks AC, comments, closes issue, sets board **Done**).

Use `--no-close` only if user explicitly wants comment-only.

## Kit update (solo-dev-ai-kit refresh)

Triggers: *update workflow kit*, *update solo-dev-ai-kit*, `/update`, *perbarui workflow kit*.

**Read first:** `docs/updating-workflow-kit.md` and `docs/update-prompt.md` (step-by-step). Target is **this app project** — not the kit repo.

1. Read `.workflow-kit/installed` and `.workflow-kit.env` — report `kit_version` jump and preserved `GH_PROJECT_NUM`.
2. Pull latest kit repo (`git pull` on local clone, or clone to `/tmp/solo-dev-ai-kit`).
3. **Dry-run:** `/path/to/solo-dev-ai-kit/bootstrap.sh --target . --dry-run` — show `[dry-run]` output; no writes.
4. **Apply:** `bootstrap.sh --target .` — **no `--force`** unless user explicitly asks. Env merges automatically; backup → `.workflow-kit/env.backup`.
5. Run `./scripts/gh-check-ui-tools.sh`.
6. Report: `git diff --stat`, confirm `GH_PROJECT_NUM` unchanged, new `kit_version`, any new docs.
7. If `AGENTS.md` was skipped (no `--force`), diff against kit `templates/AGENTS.md.tpl` and summarize kanon changes for manual merge.
8. **Do not** change app feature code. **Do not** run `--run-github-setup` unless user asks.

## Self-verify (agent definition of done)

Required before saying *siap QA* / *implemented*. Two QA layers:

- **Agent DoD** — evidence against AC (this section).
- **Human QA** — user says *sudah work* → Phase 3.

### Scope lock (default)

Verify **only what the issue acceptance criteria require** — one evidence item per `- [ ]` line.

- Do **not** explore the full app, every screen, or unrelated flows unless AC or the user asks.
- Regression checks only when AC explicitly mentions them (e.g. “checkout still works”).
- **Full E2E / regression audit** — only when the user explicitly says e.g. *test end-to-end full*, *regression all flows*, *audit the app*.

Before verifying, list AC items and state: *Scope: AC #N only — not full app.*

### Token-conscious verification

Prefer **automated tests** (text output) over screenshots. Use visual/browser/MobAI evidence **only for AC that need UI interaction** — minimal steps, one proof per AC when possible.

### Classify work

- **UI / UX** — layout, routing, forms, visible state.
- **Non-UI** — API, scripts, data, CI.
- **Mixed** — run tests first, then minimal UI flows for AC that need it.

### Web UI evidence

Screenshot alone is **not** verification. For each AC that needs UI:

1. Open app using `docs/how-to-run.md` (local URL + start command).
2. Run the **minimal flow** that proves that AC (click, type, submit, navigate).
3. Cover edge cases **named in AC** only (empty, error, flags).

**Web tools (priority):**

1. **Cursor IDE browser** (native MCP) — no extra install.
2. **Playwright CLI/MCP** — only if already on device/project; never auto-install.
3. **Existing project tests** — use if present.
4. If none available: nearest substitute + **state what was not verified**.

### Mobile UI evidence (Flutter, RN, native)

Do **not** use Playwright or Cursor browser for native mobile apps.

1. **Automated tests first** — `flutter test`, widget/integration tests per `docs/how-to-run.md`.
2. **MobAI** (optional, recommended for native UI flows) — [mobai.run](https://mobai.run); MCP: `npx mobai-mcp` with MobAI desktop + simulator/device. **Never auto-install**; user installs manually.
3. Use existing Puppeteer/Detox/Maestro only if already in the project.
4. If MobAI unavailable: report test evidence + **what UI was not verified**; board **QA** for human device check.

### Non-UI evidence

- Run relevant tests (`{{CI_TEST_COMMAND}}` or focused subset tied to changed files).
- Typecheck/lint when contracts change.
- API: real requests (curl/script) including error paths in AC.

### Loop gate (max {{VERIFY_MAX_ROUNDS}} rounds)

Default: **{{VERIFY_MAX_ROUNDS}}** rounds per task (set `VERIFY_MAX_ROUNDS` in `.workflow-kit.env` or bootstrap `--verify-max-rounds N`).

**Override for one task** — when the user says e.g. *max 2 rounds*, *5 putaran untuk #12*, use that number for **this issue only**; do not edit `.workflow-kit.env` unless they ask to change the project default.

**Change project default** — edit `VERIFY_MAX_ROUNDS` in `.workflow-kit.env`, or re-bootstrap with `--verify-max-rounds N`.

One round = implement/patch → verify → pass or fail.

- **Max rounds** = default or per-task override above.
- **Scope lock** — each round only fixes gaps vs AC; no scope creep.
- Stop early if: all AC met; **same failure twice**; blocker (login, env, server/emulator down); remaining gap is **taste** (spacing, tone) — human decides.
- Each round needs a new hypothesis, not random tweaks.
- After stop: report what was proven per AC, gaps vs AC, last evidence, what you need from the user.

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
| App stack | `{{APP_STACK}}` (`web` · `mobile` · `both`) |
| Verify max rounds | `{{VERIFY_MAX_ROUNDS}}` (override per task in chat) |
| Scripts | See `scripts/README.md` — triage, status, close, validate, UI check |

## Related

- `docs/github-workflow.md` — cheatsheet & daily flow
- `docs/agent-platforms.md` — per-platform official setup
- `docs/how-to-run.md` — dev URL, emulator, tests (replace all `TBD`)
- `docs/troubleshooting.md` — common script & verify issues
- `docs/updating-workflow-kit.md` — refresh when solo-dev-ai-kit repo updates
- `docs/update-prompt.md` — agent checklist for kit update (`/update`)
- `docs/update-prompt.id.md` — same, Bahasa Indonesia
- `docs/close-comment.example.md` — template for Phase 3 close-out
- `scripts/README.md` — all `gh-*.sh` scripts, flags, examples
- `.workflow-kit.env` — repo config (generated by bootstrap)
