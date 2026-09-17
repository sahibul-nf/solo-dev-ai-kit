#!/usr/bin/env bash
# Remove solo-dev-ai-kit files from a target project (local files only).
#
# Does NOT delete GitHub Issues, Project board, labels, or remote resources.
#
# Usage:
#   ./uninstall-workflow-kit.sh --target /path/to/my-app
#   ./uninstall-workflow-kit.sh --target . --dry-run
#   ./uninstall-workflow-kit.sh --target . --keep-agents
set -euo pipefail

KIT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET=""
DRY_RUN=false
KEEP_AGENTS=false
KEEP_CHANGELOG=true

usage() {
  sed -n '2,10p' "$0" | sed 's/^# \?//'
  echo "  --keep-agents       Leave AGENTS.md in place (no extract/remove)"
  echo "  --remove-changelog  Also remove CHANGELOG.md if present"
  exit "${1:-0}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target) TARGET="$2"; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    --keep-agents) KEEP_AGENTS=true; shift ;;
    --remove-changelog) KEEP_CHANGELOG=false; shift ;;
    -h|--help) usage 0 ;;
    *) echo "Unknown: $1" >&2; usage 1 ;;
  esac
done

[[ -n "$TARGET" ]] || TARGET="$(pwd)"
TARGET="$(cd "$TARGET" && pwd)"

if [[ ! -f "$TARGET/.workflow-kit.env" && ! -f "$TARGET/.workflow-kit/installed" && ! -f "$TARGET/AGENTS.md" ]]; then
  echo "warning: no workflow kit markers found in $TARGET — proceeding with file list anyway" >&2
fi

CURSOR_COMMANDS=(
  triage.md implement.md verify.md close.md update.md
)

KIT_SCRIPTS=(
  _load-config.sh
  merge-agents-md.py
  gh-check-ui-tools.sh
  gh-close-verified-issue.sh
  gh-configure-project.sh
  gh-create-labels.sh
  gh-ensure-project-status.sh
  gh-ensure-project-status-qa.sh
  gh-set-issue-status.sh
  gh-setup-all.sh
  gh-setup-project.sh
  gh-triage-issue.sh
  gh-validate-issue-body.sh
)

KIT_DOCS=(
  docs/github-workflow.md
  docs/agent-platforms.md
  docs/troubleshooting.md
  docs/updating-workflow-kit.md
  docs/uninstalling-workflow-kit.md
  docs/orchestrator-integration.md
  docs/update-prompt.md
  docs/update-prompt.id.md
  docs/close-comment.example.md
  docs/issue-body.example.md
)

remove_path() {
  local rel="$1"
  local abs="$TARGET/$rel"
  if [[ ! -e "$abs" ]]; then
    return 0
  fi
  if $DRY_RUN; then
    echo "  [dry-run] would remove: $rel"
  else
    rm -rf "$abs"
    echo "  removed: $rel"
  fi
}

$DRY_RUN && echo "→ DRY RUN — no files will be modified"
echo "→ Uninstall workflow kit from: $TARGET"
echo "→ GitHub board/issues/labels: NOT touched"
echo ""

# Preserve project-specific AGENTS.md content
if [[ -f "$TARGET/AGENTS.md" && "$KEEP_AGENTS" != true ]]; then
  extracted=""
  extracted="$(python3 "$KIT_DIR/scripts/extract-agents-project-specific.py" \
    "$TARGET/AGENTS.md" "$KIT_DIR/templates/AGENTS.md.tpl" 2>/dev/null || true)"
  if [[ -n "$extracted" ]]; then
    dest="docs/project-guidelines.md"
    if [[ -f "$TARGET/$dest" && "$DRY_RUN" != true ]]; then
      echo "  note: $dest already exists — appending extracted project-specific content"
      {
        echo ""
        echo "## From former AGENTS.md (workflow kit uninstall)"
        echo ""
        printf '%s\n' "$extracted"
      } >>"$TARGET/$dest"
    elif $DRY_RUN; then
      echo "  [dry-run] would write extracted project-specific content → $dest"
    else
      mkdir -p "$TARGET/docs"
      cat >"$TARGET/$dest" <<EOF
# Project guidelines

Preserved from \`AGENTS.md\` when solo-dev-ai-kit was uninstalled. Add agent instructions here or in your own rules.

$extracted
EOF
      echo "  preserved project-specific content → $dest"
    fi
  fi
  remove_path "AGENTS.md"
elif [[ -f "$TARGET/AGENTS.md" ]]; then
  echo "  kept: AGENTS.md (--keep-agents)"
fi

remove_path ".workflow-kit.env"
remove_path ".workflow-kit"
remove_path "CLAUDE.md"
remove_path "GEMINI.md"
remove_path ".gemini"

for f in "${KIT_DOCS[@]}"; do
  remove_path "$f"
done

echo "  kept: docs/how-to-run.md (project runbook — not removed)"

for f in "${KIT_SCRIPTS[@]}"; do
  remove_path "scripts/$f"
done
remove_path "scripts/README.md"
remove_path "scripts/project-readme.md"

# Remove scripts/ only if empty
if [[ -d "$TARGET/scripts" ]]; then
  if [[ -z "$(ls -A "$TARGET/scripts" 2>/dev/null)" ]]; then
    remove_path "scripts"
  elif ! $DRY_RUN; then
    echo "  kept: scripts/ (contains non-kit files)"
  fi
fi

remove_path ".cursor/rules/github-issue-workflow.mdc"
remove_path ".cursor/rules/code-principles.mdc"
for f in "${CURSOR_COMMANDS[@]}"; do
  remove_path ".cursor/commands/$f"
done
if [[ -d "$TARGET/.cursor/commands" ]]; then
  if [[ -z "$(ls -A "$TARGET/.cursor/commands" 2>/dev/null)" ]]; then
    remove_path ".cursor/commands"
  elif ! $DRY_RUN; then
    echo "  kept: .cursor/commands/ (contains non-kit files)"
  fi
fi
if [[ -d "$TARGET/.cursor/rules" ]]; then
  if [[ -z "$(ls -A "$TARGET/.cursor/rules" 2>/dev/null)" ]]; then
    remove_path ".cursor/rules"
  fi
fi

remove_path ".agents/rules/issue-workflow.md"
remove_path ".agents/rules/code-principles.md"
if [[ -d "$TARGET/.agents/rules" ]]; then
  if [[ -z "$(ls -A "$TARGET/.agents/rules" 2>/dev/null)" ]]; then
    remove_path ".agents/rules"
  fi
fi

if [[ -d "$TARGET/.github/ISSUE_TEMPLATE" ]]; then
  for f in config.yml bug.yml feature.yml; do
    remove_path ".github/ISSUE_TEMPLATE/$f"
  done
  if [[ -d "$TARGET/.github/ISSUE_TEMPLATE" ]]; then
    if [[ -z "$(ls -A "$TARGET/.github/ISSUE_TEMPLATE" 2>/dev/null)" ]]; then
      remove_path ".github/ISSUE_TEMPLATE"
    elif ! $DRY_RUN; then
      echo "  kept: .github/ISSUE_TEMPLATE/ (contains non-kit files)"
    fi
  fi
fi

if [[ "$KEEP_CHANGELOG" != true ]]; then
  remove_path "CHANGELOG.md"
fi

echo ""
if $DRY_RUN; then
  echo "Dry run complete — re-run without --dry-run to uninstall."
else
  echo "Uninstall complete. GitHub Project, issues, and labels were not modified."
  echo "Review git diff, then commit. See docs/uninstalling-workflow-kit.md in the kit repo."
fi
