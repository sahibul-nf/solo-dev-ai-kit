#!/usr/bin/env bash
# Bootstrap solo-dev + AI workflow into a target project.
#
# Usage:
#   ./bootstrap.sh --target /path/to/my-app --repo owner/my-app --tools cursor,antigravity
#   ./bootstrap.sh --target . --main-only          # single branch (main/master)
#   ./bootstrap.sh --target . --integration-branch dev --production-branch main
#   ./bootstrap.sh --target . --app-stack mobile   # Flutter; MobAI optional for UI verify
#   ./bootstrap.sh --target . --dry-run            # show changes without writing
#   ./bootstrap.sh --target .                      # re-run on existing project merges .workflow-kit.env
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
CLIENT_REPORTS_CLI=false
RUN_GITHUB=false
MAIN_ONLY=false
FORCE=false
PROJECT_BOARD_URL="(set after ./scripts/gh-setup-project.sh)"
EXTRA_LABELS=""
SINGLE_BRANCH=false
APP_STACK=""
APP_STACK_CLI=""
VERIFY_MAX_ROUNDS=3
VERIFY_MAX_ROUNDS_CLI=""
DRY_RUN=false
REPO_CLI=""
TOOLS_CLI=""
CI_TEST_CLI=""
PROJECT_TITLE_CLI=""
EXTRA_LABELS_CLI=""
PRESERVED_GH_PROJECT_NUM=""
PRESERVED_GH_PROJECT_OWNER="@me"
PRESERVE_BRANCHES=false
IS_UPDATE=false

usage() {
  sed -n '2,9p' "$0" | sed 's/^# \?//'
  exit "${1:-0}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target) TARGET="$2"; shift 2 ;;
    --repo) GH_REPO="$2"; REPO_CLI="$2"; shift 2 ;;
    --tools) TOOLS="$2"; TOOLS_CLI="$2"; shift 2 ;;
    --integration-branch) INTEGRATION_BRANCH="$2"; INTEGRATION_BRANCH_CLI="$2"; shift 2 ;;
    --production-branch) PRODUCTION_BRANCH="$2"; PRODUCTION_BRANCH_CLI="$2"; shift 2 ;;
    --ci-test) CI_TEST_COMMAND="$2"; CI_TEST_CLI="$2"; shift 2 ;;
    --project-title) PROJECT_TITLE="$2"; PROJECT_TITLE_CLI="$2"; shift 2 ;;
    --extra-labels) EXTRA_LABELS="$2"; EXTRA_LABELS_CLI="$2"; shift 2 ;;
    --client-reports) CLIENT_REPORTS=true; CLIENT_REPORTS_CLI=true; shift ;;
    --run-github-setup) RUN_GITHUB=true; shift ;;
    --main-only) MAIN_ONLY=true; shift ;;
    --force) FORCE=true; shift ;;
    --app-stack) APP_STACK_CLI="$2"; shift 2 ;;
    --verify-max-rounds) VERIFY_MAX_ROUNDS_CLI="$2"; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    -h|--help) usage 0 ;;
    *) echo "Unknown: $1" >&2; usage 1 ;;
  esac
done

[[ -n "$TARGET" ]] || TARGET="$(pwd)"
TARGET="$(cd "$TARGET" && pwd)"

env_get() {
  local key="$1" file="$2"
  [[ -f "$file" ]] || return 0
  local line
  line="$(grep -E "^${key}=" "$file" 2>/dev/null | head -1 || true)"
  [[ -n "$line" ]] || return 0
  line="${line#*=}"
  line="${line%%#*}"
  line="${line%"${line##*[![:space:]]}"}"
  line="${line#"${line%%[![:space:]]*}"}"
  line="${line%\"}"
  line="${line#\"}"
  printf '%s' "$line"
}

merge_existing_config() {
  local env_file="$TARGET/.workflow-kit.env"
  [[ -f "$env_file" ]] || return 0
  IS_UPDATE=true

  local v
  if [[ -z "$REPO_CLI" ]]; then v="$(env_get GH_REPO "$env_file")"; [[ -n "$v" ]] && GH_REPO="$v"; fi
  if [[ -z "$TOOLS_CLI" ]]; then v="$(env_get WORKFLOW_TOOLS "$env_file")"; [[ -n "$v" ]] && TOOLS="$v"; fi
  if [[ -z "$CI_TEST_CLI" ]]; then v="$(env_get CI_TEST_COMMAND "$env_file")"; [[ -n "$v" ]] && CI_TEST_COMMAND="$v"; fi
  if [[ -z "$APP_STACK_CLI" ]]; then v="$(env_get APP_STACK "$env_file")"; [[ -n "$v" ]] && APP_STACK="$v"; fi
  if [[ -z "$VERIFY_MAX_ROUNDS_CLI" ]]; then v="$(env_get VERIFY_MAX_ROUNDS "$env_file")"; [[ -n "$v" ]] && VERIFY_MAX_ROUNDS="$v"; fi
  if [[ -z "$PROJECT_TITLE_CLI" ]]; then v="$(env_get GH_PROJECT_TITLE "$env_file")"; [[ -n "$v" ]] && PROJECT_TITLE="$v"; fi
  if [[ -z "$EXTRA_LABELS_CLI" ]]; then v="$(env_get EXTRA_LABELS "$env_file")"; [[ -n "$v" ]] && EXTRA_LABELS="$v"; fi

  v="$(env_get GH_PROJECT_NUM "$env_file")"
  PRESERVED_GH_PROJECT_NUM="${v:-}"
  v="$(env_get GH_PROJECT_OWNER "$env_file")"
  [[ -n "$v" ]] && PRESERVED_GH_PROJECT_OWNER="$v"

  v="$(env_get HAS_CLIENT_REPORTS "$env_file")"
  if [[ "$CLIENT_REPORTS_CLI" != true && "$v" == "true" ]]; then CLIENT_REPORTS=true; fi

  if [[ -z "$INTEGRATION_BRANCH_CLI" && -z "$PRODUCTION_BRANCH_CLI" && "$MAIN_ONLY" != true ]]; then
    local ib pb sb
    ib="$(env_get INTEGRATION_BRANCH "$env_file")"
    pb="$(env_get PRODUCTION_BRANCH "$env_file")"
    sb="$(env_get SINGLE_BRANCH "$env_file")"
    if [[ -n "$ib" && -n "$pb" ]]; then
      INTEGRATION_BRANCH="$ib"
      PRODUCTION_BRANCH="$pb"
      SINGLE_BRANCH="${sb:-false}"
      PRESERVE_BRANCHES=true
    fi
  fi

  if ! $DRY_RUN; then
    mkdir -p "$TARGET/.workflow-kit"
    cp "$env_file" "$TARGET/.workflow-kit/env.backup"
    echo "→ Update mode: merged settings from existing .workflow-kit.env (backup: .workflow-kit/env.backup)"
  else
    echo "→ Update mode: would merge from existing .workflow-kit.env"
  fi
}

merge_existing_config

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
  if ! $PRESERVE_BRANCHES; then detect_branches; fi
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
export CI_TEST_COMMAND WORKFLOW_TOOLS_LIST PROJECT_BOARD_URL SINGLE_BRANCH APP_STACK VERIFY_MAX_ROUNDS

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

render_if_allowed() {
  local src="$1" dst="$2"
  if [[ -f "$dst" && "$FORCE" != true ]]; then
    echo "  skip (exists): $(basename "$dst") — use --force to overwrite"
    return 0
  fi
  if $DRY_RUN; then
    echo "  [dry-run] would write: $dst"
    return 0
  fi
  render_tpl "$src" "$dst"
}

write_file() {
  local dst="$1"
  shift
  if $DRY_RUN; then
    echo "  [dry-run] would write: $dst"
    return 0
  fi
  mkdir -p "$(dirname "$dst")"
  cat >"$dst"
}

copy_file() {
  local src="$1" dst="$2"
  if $DRY_RUN; then
    echo "  [dry-run] would copy: $src → $dst"
    return 0
  fi
  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
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

detect_app_stack() {
  if [[ -n "$APP_STACK_CLI" ]]; then
    APP_STACK="$APP_STACK_CLI"
    return
  fi
  if [[ -n "$APP_STACK" ]]; then
    return
  fi
  if [[ -f "$TARGET/pubspec.yaml" ]]; then
    APP_STACK=mobile
  elif [[ -f "$TARGET/package.json" ]]; then
    APP_STACK=web
  else
    APP_STACK=web
  fi
}

detect_app_stack

case "$APP_STACK" in
  web|mobile|both) ;;
  *)
    echo "Unknown --app-stack: $APP_STACK (use web|mobile|both)" >&2
    exit 1
    ;;
esac

export APP_STACK

if [[ -n "$VERIFY_MAX_ROUNDS_CLI" ]]; then
  VERIFY_MAX_ROUNDS="$VERIFY_MAX_ROUNDS_CLI"
fi
if ! [[ "$VERIFY_MAX_ROUNDS" =~ ^[0-9]+$ ]] || [[ "$VERIFY_MAX_ROUNDS" -lt 1 ]]; then
  echo "error: VERIFY_MAX_ROUNDS must be a positive integer (got: $VERIFY_MAX_ROUNDS)" >&2
  exit 1
fi
export VERIFY_MAX_ROUNDS

$DRY_RUN && echo "→ DRY RUN — no files will be modified"
$IS_UPDATE && ! $DRY_RUN && echo "→ Preserving GH_PROJECT_NUM=${PRESERVED_GH_PROJECT_NUM:-(empty)}"

echo "→ Target: $TARGET"
echo "→ Repo: $GH_REPO"
echo "→ Tools: $WORKFLOW_TOOLS_LIST"
echo "→ App stack: $APP_STACK"
echo "→ Verify max rounds: $VERIFY_MAX_ROUNDS"
if [[ "$SINGLE_BRANCH" == true ]]; then
  echo "→ Branches: single ($PRODUCTION_BRANCH)"
else
  echo "→ Branches: $INTEGRATION_BRANCH → $PRODUCTION_BRANCH"
fi

write_file "$TARGET/.workflow-kit.env" <<EOF
# Generated by solo-dev-ai-kit/bootstrap.sh — safe to commit (metadata only, no tokens).
GH_REPO=$GH_REPO
GH_PROJECT_NUM=${PRESERVED_GH_PROJECT_NUM:-}
GH_PROJECT_OWNER=${PRESERVED_GH_PROJECT_OWNER:-@me}
GH_PROJECT_TITLE="$PROJECT_TITLE"
INTEGRATION_BRANCH=$INTEGRATION_BRANCH
PRODUCTION_BRANCH=$PRODUCTION_BRANCH
SINGLE_BRANCH=$SINGLE_BRANCH
CI_TEST_COMMAND="$CI_TEST_COMMAND"
WORKFLOW_TOOLS=$TOOLS
HAS_CLIENT_REPORTS=$CLIENT_REPORTS
EXTRA_LABELS=$EXTRA_LABELS
APP_STACK=$APP_STACK
VERIFY_MAX_ROUNDS=$VERIFY_MAX_ROUNDS
EOF

render_if_allowed "$KIT_DIR/templates/AGENTS.md.tpl" "$TARGET/AGENTS.md"
render_tpl "$KIT_DIR/templates/docs/github-workflow.md.tpl" "$TARGET/docs/github-workflow.md"
render_tpl "$KIT_DIR/templates/docs/agent-platforms.md.tpl" "$TARGET/docs/agent-platforms.md"
render_if_allowed "$KIT_DIR/templates/docs/how-to-run.md.tpl" "$TARGET/docs/how-to-run.md"
copy_file "$KIT_DIR/templates/issue-body.example.md" "$TARGET/docs/issue-body.example.md"
copy_file "$KIT_DIR/templates/docs/close-comment.example.md" "$TARGET/docs/close-comment.example.md"
render_tpl "$KIT_DIR/templates/docs/troubleshooting.md.tpl" "$TARGET/docs/troubleshooting.md"
render_tpl "$KIT_DIR/templates/docs/updating-workflow-kit.md.tpl" "$TARGET/docs/updating-workflow-kit.md"
copy_file "$KIT_DIR/UPDATE_PROMPT.md" "$TARGET/docs/update-prompt.md"
copy_file "$KIT_DIR/UPDATE_PROMPT.id.md" "$TARGET/docs/update-prompt.id.md"

[[ -f "$TARGET/CHANGELOG.md" ]] || copy_file "$KIT_DIR/templates/CHANGELOG.md.tpl" "$TARGET/CHANGELOG.md"

mkdir -p "$TARGET/scripts"
if ! $DRY_RUN; then
  for f in "$KIT_DIR/scripts/"*.sh; do
    cp "$f" "$TARGET/scripts/"
    chmod +x "$TARGET/scripts/$(basename "$f")"
  done
else
  echo "  [dry-run] would copy scripts/*.sh → $TARGET/scripts/"
fi
render_tpl "$KIT_DIR/templates/scripts/project-readme.md.tpl" "$TARGET/scripts/project-readme.md"
render_tpl "$KIT_DIR/templates/scripts/README.md.tpl" "$TARGET/scripts/README.md"

mkdir -p "$TARGET/.github/ISSUE_TEMPLATE"
if $DRY_RUN; then
  echo "  [dry-run] would copy ISSUE_TEMPLATE/* → $TARGET/.github/ISSUE_TEMPLATE/"
else
  cp "$KIT_DIR/.github/ISSUE_TEMPLATE/"* "$TARGET/.github/ISSUE_TEMPLATE/"
fi

[[ -f "$TARGET/CODEX.md" ]] && rm -f "$TARGET/CODEX.md" && echo "  Removed obsolete CODEX.md"

if has_tool cursor; then
  if $DRY_RUN; then
    echo "  [dry-run] would install Cursor rules + commands"
  else
    mkdir -p "$TARGET/.cursor/rules"
    render_tpl "$KIT_DIR/agents/cursor/github-issue-workflow.mdc.tpl" "$TARGET/.cursor/rules/github-issue-workflow.mdc"
    cp "$KIT_DIR/agents/cursor/code-principles.mdc" "$TARGET/.cursor/rules/"
    mkdir -p "$TARGET/.cursor/commands"
    cp "$KIT_DIR/agents/cursor/commands/"*.md "$TARGET/.cursor/commands/"
  fi
  echo "  ✓ Cursor (rules + commands)"
else
  if ! $DRY_RUN; then
    rm -f "$TARGET/.cursor/rules/github-issue-workflow.mdc" "$TARGET/.cursor/rules/code-principles.mdc"
    rm -rf "$TARGET/.cursor/commands"
  fi
fi

if has_tool antigravity; then
  if $DRY_RUN; then
    echo "  [dry-run] would install Antigravity rules"
  else
    mkdir -p "$TARGET/.agents/rules"
    render_tpl "$KIT_DIR/agents/antigravity/issue-workflow.md.tpl" "$TARGET/.agents/rules/issue-workflow.md"
    cp "$KIT_DIR/agents/antigravity/code-principles.md" "$TARGET/.agents/rules/"
  fi
  echo "  ✓ Antigravity"
else
  if ! $DRY_RUN; then
    rm -f "$TARGET/.agents/rules/issue-workflow.md" "$TARGET/.agents/rules/code-principles.md"
  fi
fi

has_tool codex && echo "  ✓ Codex (AGENTS.md native)"

if has_tool claude; then
  if $DRY_RUN; then
    echo "  [dry-run] would write CLAUDE.md"
  else
    render_tpl "$KIT_DIR/agents/claude/CLAUDE.md.tpl" "$TARGET/CLAUDE.md"
  fi
  echo "  ✓ Claude Code"
else
  if ! $DRY_RUN; then rm -f "$TARGET/CLAUDE.md"; fi
fi

if has_tool gemini; then
  if $DRY_RUN; then
    echo "  [dry-run] would install Gemini CLI config"
  else
    mkdir -p "$TARGET/.gemini"
    cp "$KIT_DIR/agents/gemini/settings.json.tpl" "$TARGET/.gemini/settings.json"
    render_tpl "$KIT_DIR/agents/gemini/GEMINI.md.tpl" "$TARGET/GEMINI.md"
  fi
  echo "  ✓ Gemini CLI"
else
  if ! $DRY_RUN; then
    rm -f "$TARGET/GEMINI.md"
    rm -rf "$TARGET/.gemini"
  fi
fi

mkdir -p "$TARGET/.workflow-kit"
if $DRY_RUN; then
  echo "  [dry-run] would write .workflow-kit/installed"
else
{
  echo "kit_version=8"
  echo "tools=$TOOLS"
  echo "app_stack=$APP_STACK"
  echo "single_branch=$SINGLE_BRANCH"
  echo "installed_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
} >"$TARGET/.workflow-kit/installed"
fi

echo ""
if $DRY_RUN; then
  echo "Dry run complete — re-run without --dry-run to apply."
  exit 0
fi

echo "Bootstrap complete → $TARGET/AGENTS.md"

echo ""
if [[ -x "$TARGET/scripts/gh-check-ui-tools.sh" ]]; then
  (cd "$TARGET" && ./scripts/gh-check-ui-tools.sh) || true
fi

if $RUN_GITHUB; then
  echo ""
  echo "Running GitHub setup …"
  if (cd "$TARGET" && ./scripts/gh-setup-all.sh "$GH_REPO"); then
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
      else
        echo "warning: GH_PROJECT_NUM not set after setup — board URLs in docs may be placeholders" >&2
      fi
    fi
  else
    echo "error: GitHub setup failed. Fix auth/scopes and re-run:" >&2
    echo "  cd \"$TARGET\" && ./scripts/gh-setup-all.sh $GH_REPO" >&2
    exit 1
  fi
fi
