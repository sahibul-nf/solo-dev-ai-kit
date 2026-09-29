# Changelog

All notable changes to **solo-dev-ai-kit** (the kit repo) are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## How this relates to your app project

After bootstrap, your app records the installed version in `.workflow-kit/installed` (`kit_version=N`). When you update, compare that number to the sections below (or run `git pull` in your kit clone and read this file).

App projects also get a separate `CHANGELOG.md` (from the kit template) for **your product** — this file is only for **workflow kit** releases.

## [Unreleased]

### Added

### Changed

### Fixed

## [12] — 2026-09-17

### Added

- `solo-dev-ai-kit:managed` markers on kit-generated files (`partial-managed` on `AGENTS.md`).
- `.workflow-kit/manifest` written on bootstrap; uninstall removes paths only when markers are still present.
- `scripts/kit-managed.py` and `scripts/verify-kit-managed.sh` for stamping and auditing.
- Gemini `settings.json` `_solo_dev_ai_kit` metadata key.

### Changed

- `uninstall-workflow-kit.sh` prefers manifest + markers; `--legacy-allowlist` for pre-v12 installs.
- Bootstrap registers every installed path and copies `scripts/*.py` into app projects.

## [11] — 2026-09-17

### Added

- `uninstall-workflow-kit.sh` for safe **local** removal (no GitHub board/issues/labels).
- `UNINSTALL_PROMPT.md` / `.id`, `docs/uninstall-prompt.md`, `/uninstall` Cursor command.
- `scripts/extract-agents-project-specific.py` — preserve custom `AGENTS.md` blocks → `docs/project-guidelines.md`.

## [10] — 2026-09-17

### Added

- Orchestrator-friendly **Project Status** columns: Ready for AI, AI Working, AI Review, Human Review (additive; existing Todo / In Progress / QA kept).
- Extended `gh-set-issue-status.sh` keys and fallbacks; `gh-ensure-project-status.sh`.
- Labels `complexity:*`, `ai-blocked`, `ai-needs-human` (metadata only — not authorization).
- `docs/orchestrator-integration.md` and AGENTS.md contract (Status vs labels, autonomy, cost).

### Changed

- `/triage` and docs: **Ready for AI** is set via board Status only, not labels.

## [9] — 2026-09-02

### Added

- `scripts/merge-agents-md.py` — re-bootstrap refreshes kit sections in `AGENTS.md` while keeping project-specific `##` blocks.

### Changed

- Bootstrap merges `AGENTS.md` on update instead of skipping when the file exists.

## [8] — 2026-09-02

### Added

- Safe re-bootstrap: merge existing `.workflow-kit.env` (preserves `GH_PROJECT_NUM`, branches, tools).
- `--dry-run` on `bootstrap.sh`; `.workflow-kit/env.backup` before env rewrite.
- `UPDATE_PROMPT.md` / `.id`, `docs/update-prompt.md`, `/update` command, `docs/updating-workflow-kit.md`.

### Changed

- `docs/how-to-run.md` still preserved on update unless `--force`.

## [4] — 2026-08-31

### Added

- Self-verify loop (`VERIFY_MAX_ROUNDS`), `gh-check-ui-tools.sh`, stronger board automation.
- Install prompts (`INSTALL_PROMPT.md`), intent routing in `AGENTS.md`, expanded workflow docs.

### Changed

- `kit_version` tracking in `.workflow-kit/installed`.

## [3] — 2026-06-20

### Added

- Initial portable kit: `bootstrap.sh`, canonical `AGENTS.md`, multi-platform agents (Cursor, Antigravity, Codex, Claude, Gemini).
- GitHub scripts (`gh-triage-issue.sh`, project setup, labels, issue templates).
- Single vs dual branch detection; `SECURITY.md` and env-file guidance (no secrets in repo).
