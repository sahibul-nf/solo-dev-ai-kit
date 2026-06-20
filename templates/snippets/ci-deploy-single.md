| Step | Branch | Action |
|------|--------|--------|
| Production | `{{PRODUCTION_BRANCH}}` | CI + deploy on push (single branch) |

No separate integration branch. Do not reference `dev` unless it appears in `git branch -a`.
