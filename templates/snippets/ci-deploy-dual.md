| Step | Branch | Action |
|------|--------|--------|
| Integration | `{{INTEGRATION_BRANCH}}` | `{{CI_TEST_COMMAND}}` on push |
| Production | `{{PRODUCTION_BRANCH}}` | Deploy on push |

**Always push `{{INTEGRATION_BRANCH}}` before `{{PRODUCTION_BRANCH}}`** when both exist. If `{{INTEGRATION_BRANCH}}` is missing, push **`{{PRODUCTION_BRANCH}}`** only.
