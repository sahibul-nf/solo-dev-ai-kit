Phase 3 — close-out after human QA for issue `#N` (user must confirm *works* / *ok* / *sudah work*).

1. Verify AC against code/commits (read-only).
2. Write closing comment summarizing what was verified.
3. Run:

```bash
./scripts/gh-close-verified-issue.sh N --comment-file /tmp/close-N.md
```

This checks AC boxes, posts comment, closes issue, and sets board **Done**.

Use `--no-close` only if user explicitly wants comment-only.
