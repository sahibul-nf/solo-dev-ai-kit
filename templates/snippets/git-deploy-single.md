- **Branch model:** single — **`{{PRODUCTION_BRANCH}}`** only (no separate integration branch in this repo)
- **CI / deploy:** follow `.github/workflows/` if present; otherwise push **`{{PRODUCTION_BRANCH}}`** when ready
- **Commits:** Only when the user explicitly asks

### Merge & push (AI)

```text
1. merge feat/* → {{PRODUCTION_BRANCH}}
2. git push origin {{PRODUCTION_BRANCH}}
```

**Do not** tell the user to push a `dev` or integration branch unless `git branch -a` shows it exists. If they later add **`{{INTEGRATION_BRANCH}}`**, re-run bootstrap or update `.workflow-kit.env`.
