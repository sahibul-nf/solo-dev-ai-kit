Phase 2 — implement issue `#N` (user must specify number in chat).

Follow `AGENTS.md` Phase 2:

1. Read acceptance criteria for the issue.
2. Plan if non-trivial (>1 file or new user-facing behavior).
3. Branch `feat/#N-slug` or `fix/#N-slug`.
4. Implement focused diff.
5. `./scripts/gh-set-issue-status.sh N progress`
6. **Self-verify** per `AGENTS.md` (max 3 rounds) before claiming done.
7. `./scripts/gh-set-issue-status.sh N qa` when ready for human QA.
8. PR `Fixes #N`. Commit only when user asks.

Do not close the issue — wait for human *sudah work*.
