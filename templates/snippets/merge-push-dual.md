1. Merge to **`{{INTEGRATION_BRANCH}}`** → **`git push origin {{INTEGRATION_BRANCH}}`** first (CI).
2. Then **`{{PRODUCTION_BRANCH}}`** → **`git push origin {{PRODUCTION_BRANCH}}`**.

If **`{{INTEGRATION_BRANCH}}`** is missing (`git branch -a`), use single branch **`{{PRODUCTION_BRANCH}}`** only.
