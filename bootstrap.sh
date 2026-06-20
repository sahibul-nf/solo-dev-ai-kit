#!/usr/bin/env bash
# Bootstrap solo-dev + AI workflow into a target project.
#
# Usage:
#   ./bootstrap.sh --target /path/to/my-app --repo owner/my-app --tools cursor,antigravity
#   ./bootstrap.sh --target . --main-only          # single branch (main/master)
#   ./bootstrap.sh --target . --integration-branch dev --production-branch main
set -euo pipefail

KIT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET=""
GH_REPO=""
TOOLS="cursor,antigravity,codex,claude,gemini"
INTEGRATION_BRANCH=""
PRODUCTION_BRANCH=""
INTEGRATION_BRANCH_CLI=""
PRODUCTION_BRANCH_CLI=""
CI_TEST_COMMAND="run tests"
PROJECT_TITLE=""
CLIENT_REPORTS=false
RUN_GITHUB=false
MAIN_ONLY=false
PROJECT_BOARD_URL="(set after ./scripts/gh-setup-project.sh)"
EXTRA_LABELS=""
SINGLE_BRANCH=false

usage() {
  sed -n '2,8p' "$0" | sed 's/^# \?//'
  exit "${1:-0}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target) TARGET="$2"; shift 2 ;;
    --repo) GH_REPO="$2"; shift 2 ;;
    --tools) TOOLS="$2"; shift 2 ;;
    --integration-branch) INTEGRATION_BRANCH="$2"; INTEGRATION_BRANCH_CLI="$2"; shift 2 ;;
    --production-branch) PRODUCTION_BRANCH="$2"; PRODUCTION_BRANCH_CLI="$2"; shift 2 ;;
    --ci-test) CI_TEST_COMMAND="$2"; shift 2 ;;
    --project-title) PROJECT_TITLE="$2"; shift 2 ;;
    --extra-labels) EXTRA_LABELS="$2"; shift 2 ;;
    --client-reports) CLIENT_REPORTS=true; shift ;;
    --run-github-setup) RUN_GITHUB=true; shift ;;
    --main-only) MAIN_ONLY=true; shift ;;
    -h|--help) usage 0 ;;
    *) echo "Unknown: $1" >&2; usage 1 ;;
  esac
done

[[ -n "$TARGET" ]] || TARGET="$(pwd)"
TARGET="$(cd "$TARGET" && pwd)"

if [[ -z "$GH_REPO" ]]; then
  if git -C "$TARGET" remote get-url origin &>/dev/null; then
    origin="$(git -C "$TARGET" remote get-url origin)"
    if [[ "$origin" =~ github\.com[:/]([^/]+)/([^/.]+) ]]; then
      GH_REPO="${BASH_REMATCH[1]}/${BASH_REMATCH[2]%.git}"
      echo "Detected repo: $GH_REPO"
    fi
  fi
fi

[[ -n "$GH_REPO" ]] || read -r -p "GitHub repo (owner/name): " GH_REPO
[[ -n "$PROJECT_TITLE" ]] || PROJECT_TITLE="${GH_REPO##*/} delivery"

branch_exists() {
  local name="$1"
  git -C "$TARGET" show-ref --verify --quiet "refs/heads/$name" 2>/dev/null && return 0
  git -C "$TARGET" show-ref --verify --quiet "refs/remotes/origin/$name" 2>/dev/null
}

detect_branches() {
  if $MAIN_ONLY; then
    if branch_exists main; then PRODUCTION_BRANCH=main
    elif branch_exists master; then PRODUCTION_BRANCH=master
    else PRODUCTION_BRANCH="${PRODUCTION_BRANCH_CLI:-main}"
    fi
    INTEGRATION_BRANCH="$PRODUCTION_BRANCH"
    SINGLE_BRANCH=true
    return
  fi

  [[ -n "$PRODUCTION_BRANCH" ]] || {
    if branch_exists main; then PRODUCTION_BRANCH=main
    elif branch_exists master; then PRODUCTION_BRANCH=master
    else PRODUCTION_BRANCH=main
    fi
  }

  [[ -n "$INTEGRATION_BRANCH" ]] || {
    if branch_exists dev; then INTEGRATION_BRANCH=dev
    elif branch_exists develop; then INTEGRATION_BRANCH=develop
    else
      INTEGRATION_BRANCH="$PRODUCTION_BRANCH"
      SINGLE_BRANCH=true
    fi
  }

  if [[ "$INTEGRATION_BRANCH" == "$PRODUCTION_BRANCH" ]]; then
    SINGLE_BRANCH=true
  elif ! branch_exists "$INTEGRATION_BRANCH"; then
    echo "Note: branch '$INTEGRATION_BRANCH' not found — single-branch mode ($PRODUCTION_BRANCH)"
    INTEGRATION_BRANCH="$PRODUCTION_BRANCH"
    SINGLE_BRANCH=true
  else
    SINGLE_BRANCH=false
  fi
}

if git -C "$TARGET" rev-parse --git-dir &>/dev/null; then
  detect_branches
else
  PRODUCTION_BRANCH="${PRODUCTION_BRANCH:-main}"
  INTEGRATION_BRANCH="${INTEGRATION_BRANCH:-dev}"
  if [[ "$INTEGRATION_BRANCH" == "$PRODUCTION_BRANCH" ]] || $MAIN_ONLY; then
    SINGLE_BRANCH=true
    INTEGRATION_BRANCH="$PRODUCTION_BRANCH"
  fi
fi

IFS=',' read -ra TOOL_ARR <<<"$TOOLS"
WORKFLOW_TOOLS_LIST=""
for t in "${TOOL_ARR[@]}"; do
  t="${t// /}"
  case "$t" in
    cursor) WORKFLOW_TOOLS_LIST="${WORKFLOW_TOOLS_LIST}, Cursor" ;;
    antigravity) WORKFLOW_TOOLS_LIST="${WORKFLOW_TOOLS_LIST}, Antigravity" ;;
    codex) WORKFLOW_TOOLS_LIST="${WORKFLOW_TOOLS_LIST}, Codex" ;;
    claude) WORKFLOW_TOOLS_LIST="${WORKFLOW_TOOLS_LIST}, Claude Code" ;;
    gemini) WORKFLOW_TOOLS_LIST="${WORKFLOW_TOOLS_LIST}, Gemini CLI" ;;
    *) echo "Unknown tool: $t" >&2; exit 1 ;;
  esac
done
WORKFLOW_TOOLS_LIST="${WORKFLOW_TOOLS_LIST#, }"

export GH_REPO PROJECT_TITLE INTEGRATION_BRANCH PRODUCTION_BRANCH
export CI_TEST_COMMAND WORKFLOW_TOOLS_LIST PROJECT_BOARD_URL SINGLE_BRANCH

render_tpl() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  python3 - "$src" "$dst" <<'PY'
import re, sys, os
from pathlib import Path
text = Path(sys.argv[1]).read_text()
def repl(m):
    return os.environ.get(m.group(1), m.group(0))
Path(sys.argv[2]).write_text(re.sub(r"\{\{(\w+)\}\}", repl, text))
PY
}

export_snippet() {
  local snippet="$1" var="$2"
  local tmp
  tmp="$(mktemp)"
  render_tpl "$KIT_DIR/templates/snippets/$snippet" "$tmp"
  # shellcheck disable=SC2163
  export "$var"="$(cat "$tmp")"
  rm -f "$tmp"
}

if [[ "$SINGLE_BRANCH" == true ]]; then
  export_snippet git-deploy-single.md GIT_DEPLOY_SECTION
  export_snippet ci-deploy-single.md CI_DEPLOY_SECTION
  export_snippet merge-push-single.md MERGE_PUSH_SECTION
else
  export_snippet git-deploy-dual.md GIT_DEPLOY_SECTION
  export_snippet ci-deploy-dual.md CI_DEPLOY_SECTION
  export_snippet merge-push-dual.md MERGE_PUSH_SECTION
fi

has_tool() {
  local want="$1"
  for t in "${TOOL_ARR[@]}"; do
    [[ "${t// /}" == "$want" ]] && return 0
  done
  return 1
}

echo "→ Target: $TARGET"
echo "→ Repo: $GH_REPO"
echo "→ Tools: $WORKFLOW_TOOLS_LIST"
if [[ "$SINGLE_BRANCH" == true ]]; then
  echo "→ Branches: single ($PRODUCTION_BRANCH)"
else
  echo "→ Branches: $INTEGRATION_BRANCH → $PRODUCTION_BRANCH"
fi

cat >"$TARGET/.workflow-kit.env" <<EOF
# Generated by solo-dev-ai-kit/bootstrap.sh — edit as needed.
GH_REPO=$GH_REPO
GH_PROJECT_NUM=
GH_PROJECT_OWNER=@me
GH_PROJECT_TITLE=$PROJECT_TITLE
INTEGRATION_BRANCH=$INTEGRATION_BRANCH
PRODUCTION_BRANCH=$PRODUCTION_BRANCH
SINGLE_BRANCH=$SINGLE_BRANCH
CI_TEST_COMMAND=$CI_TEST_COMMAND
WORKFLOW_TOOLS=$TOOLS
HAS_CLIENT_REPORTS=$CLIENT_REPORTS
EXTRA_LABELS=$EXTRA_LABELS
EOF

render_tpl "$KIT_DIR/templates/AGENTS.md.tpl" "$TARGET/AGENTS.md"
render_tpl "$KIT_DIR/templates/docs/github-workflow.md.tpl" "$TARGET/docs/github-workflow.md"
render_tpl "$KIT_DIR/templates/docs/agent-platforms.md.tpl" "$TARGET/docs/agent-platforms.md"
cp "$KIT_DIR/templates/issue-body.example.md" "$TARGET/docs/issue-body.example.md"

[[ -f "$TARGET/CHANGELOG.md" ]] || cp "$KIT_DIR/templates/CHANGELOG.md.tpl" "$TARGET/CHANGELOG.md"

mkdir -p "$TARGET/scripts"
for f in "$KIT_DIR/scripts/"*.sh; do
  cp "$f" "$TARGET/scripts/"
  chmod +x "$TARGET/scripts/$(basename "$f")"
done
render_tpl "$KIT_DIR/templates/scripts/project-readme.md.tpl" "$TARGET/scripts/project-readme.md"

mkdir -p "$TARGET/.github/ISSUE_TEMPLATE"
cp "$KIT_DIR/.github/ISSUE_TEMPLATE/"* "$TARGET/.github/ISSUE_TEMPLATE/"

[[ -f "$TARGET/CODEX.md" ]] && rm -f "$TARGET/CODEX.md" && echo "  Removed obsolete CODEX.md"

if has_tool cursor; then
  mkdir -p "$TARGET/.cursor/rules"
  render_tpl "$KIT_DIR/agents/cursor/github-issue-workflow.mdc.tpl" "$TARGET/.cursor/rules/github-issue-workflow.mdc"
  cp "$KIT_DIR/agents/cursor/code-principles.mdc" "$TARGET/.cursor/rules/"
  echo "  ✓ Cursor"
else
  rm -f "$TARGET/.cursor/rules/github-issue-workflow.mdc" "$TARGET/.cursor/rules/code-principles.mdc"
fi

if has_tool antigravity; then
  mkdir -p "$TARGET/.agents/rules"
  render_tpl "$KIT_DIR/agents/antigravity/issue-workflow.md.tpl" "$TARGET/.agents/rules/issue-workflow.md"
  cp "$KIT_DIR/agents/antigravity/code-principles.md" "$TARGET/.agents/rules/"
  echo "  ✓ Antigravity"
else
  rm -f "$TARGET/.agents/rules/issue-workflow.md" "$TARGET/.agents/rules/code-principles.md"
fi

has_tool codex && echo "  ✓ Codex (AGENTS.md native)"

if has_tool claude; then
  render_tpl "$KIT_DIR/agents/claude/CLAUDE.md.tpl" "$TARGET/CLAUDE.md"
  echo "  ✓ Claude Code"
else
  rm -f "$TARGET/CLAUDE.md"
fi

if has_tool gemini; then
  mkdir -p "$TARGET/.gemini"
  cp "$KIT_DIR/agents/gemini/settings.json.tpl" "$TARGET/.gemini/settings.json"
  render_tpl "$KIT_DIR/agents/gemini/GEMINI.md.tpl" "$TARGET/GEMINI.md"
  echo "  ✓ Gemini CLI"
else
  rm -f "$TARGET/GEMINI.md"
  rm -rf "$TARGET/.gemini"
fi

mkdir -p "$TARGET/.workflow-kit"
{
  echo "kit_version=3"
  echo "tools=$TOOLS"
  echo "single_branch=$SINGLE_BRANCH"
  echo "installed_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
} >"$TARGET/.workflow-kit/installed"

echo ""
echo "Bootstrap complete → $TARGET/AGENTS.md"

if $RUN_GITHUB; then
  echo "Running GitHub setup …"
  (cd "$TARGET" && ./scripts/gh-setup-all.sh "$GH_REPO") || true
  if [[ -f "$TARGET/.workflow-kit.env" ]]; then
    # shellcheck disable=SC1090
    source "$TARGET/.workflow-kit.env"
    if [[ -n "${GH_PROJECT_NUM:-}" ]] && command -v gh &>/dev/null; then
      PROJECT_BOARD_URL="$(gh project view "$GH_PROJECT_NUM" --owner "${GH_PROJECT_OWNER:-@me}" --format json --jq .url 2>/dev/null || echo "$PROJECT_BOARD_URL")"
      export PROJECT_BOARD_URL
      export_snippet "$([[ "$SINGLE_BRANCH" == true ]] && echo git-deploy-single.md || echo git-deploy-dual.md)" GIT_DEPLOY_SECTION
      export_snippet "$([[ "$SINGLE_BRANCH" == true ]] && echo ci-deploy-single.md || echo ci-deploy-dual.md)" CI_DEPLOY_SECTION
      export_snippet "$([[ "$SINGLE_BRANCH" == true ]] && echo merge-push-single.md || echo merge-push-dual.md)" MERGE_PUSH_SECTION
      render_tpl "$KIT_DIR/templates/AGENTS.md.tpl" "$TARGET/AGENTS.md"
      render_tpl "$KIT_DIR/templates/docs/github-workflow.md.tpl" "$TARGET/docs/github-workflow.md"
      render_tpl "$KIT_DIR/templates/docs/agent-platforms.md.tpl" "$TARGET/docs/agent-platforms.md"
    fi
  fi
fi
