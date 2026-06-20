- **Branch model:** dual — integration **`{{INTEGRATION_BRANCH}}`** then production **`{{PRODUCTION_BRANCH}}`**
- **CI tests:** push to **`{{INTEGRATION_BRANCH}}`** runs `{{CI_TEST_COMMAND}}`
- **Production deploy:** push **`{{PRODUCTION_BRANCH}}`** when ready
- **Commits:** Only when the user explicitly asks

### Merge & push order (AI)

CI/tests run on **`git push origin {{INTEGRATION_BRANCH}}`**, not on **`{{PRODUCTION_BRANCH}}`** alone.

```text
1. merge feat/* → {{INTEGRATION_BRANCH}}
2. git push origin {{INTEGRATION_BRANCH}}   ← CI / tests
3. merge {{INTEGRATION_BRANCH}} → {{PRODUCTION_BRANCH}}
4. git push origin {{PRODUCTION_BRANCH}}    ← deploy
```

**Before merge/push:** run `git branch -a` — if **`{{INTEGRATION_BRANCH}}`** does not exist, use single-branch flow below instead of inventing the branch.
