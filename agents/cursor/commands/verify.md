Re-run verification against acceptance criteria for issue `#N` (user must specify).

Follow `AGENTS.md` self-verify section:

1. Classify UI / non-UI / mixed.
2. Gather evidence (browser flow, tests, curl) — not screenshot-only.
3. Report pass/fail per AC item with evidence.
4. If gaps remain and under loop gate (max 3 rounds), fix and re-verify.
5. If passed → `./scripts/gh-set-issue-status.sh N qa`.

Do not close the issue unless user confirms *sudah work*.
