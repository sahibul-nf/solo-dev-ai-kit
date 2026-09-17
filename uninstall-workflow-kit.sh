#!/usr/bin/env bash
# Remove solo-dev-ai-kit files from a target project (local files only).
#
# Uses .workflow-kit/manifest + solo-dev-ai-kit:managed markers when available.
# Falls back to legacy allowlist for projects installed before kit v12.
#
# Does NOT delete GitHub Issues, Project board, labels, or remote resources.
#
# Usage:
#   ./uninstall-workflow-kit.sh --target /path/to/my-app
#   ./uninstall-workflow-kit.sh --target . --dry-run
#   ./uninstall-workflow-kit.sh --target . --keep-agents
#   ./uninstall-workflow-kit.sh --target . --legacy-allowlist
set -euo pipefail

KIT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET=""
DRY_RUN=false
KEEP_AGENTS=false
KEEP_CHANGELOG=true
LEGACY_ALLOWLIST=false

PROTECTED_PATHS=(
  docs/how-to-run.md
)

usage() {
  sed -n '2,12p' "$0" | sed 's/^# \?//'
  echo "  --keep-agents         Leave AGENTS.md in place (no extract/remove)"
  echo "  --remove-changelog    Also remove CHANGELOG.md if present"
  echo "  --legacy-allowlist    Ignore markers; use path allowlist (pre-v12 installs)"
  exit "${1:-0}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target) TARGET="$2"; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    --keep-agents) KEEP_AGENTS=true; shift ;;
    --remove-changelog) KEEP_CHANGELOG=false; shift ;;
    --legacy-allowlist) LEGACY_ALLOWLIST=true; shift ;;
    -h|--help) usage 0 ;;
    *) echo "Unknown: $1" >&2; usage 1 ;;
  esac
done

[[ -n "$TARGET" ]] || TARGET="$(pwd)"
TARGET="$(cd "$TARGET" && pwd)"

MANIFEST="$TARGET/.workflow-kit/manifest"
declare -a MANIFEST_PATHS=()

is_protected() {
  local rel="$1"
  for p in "${PROTECTED_PATHS[@]}"; do
    [[ "$rel" == "$p" ]] && return 0
  done
  return 1
}

has_kit_marker() {
  local abs="$1"
  [[ -f "$abs" ]] || return 1
  python3 "$KIT_DIR/scripts/kit-managed.py" has-marker "$abs" 2>/dev/null
}

agents_has_kit_marker() {
  local abs="$1"
  has_kit_marker "$abs" && return 0
  grep -q 'solo-dev-ai-kit:partial-managed' "$abs" 2>/dev/null
}

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

remove_if_managed() {
  local rel="$1"
  local abs="$TARGET/$rel"

  if is_protected "$rel"; then
    echo "  kept (protected): $rel"
    return 0
  fi
  if [[ "$rel" == "CHANGELOG.md" && "$KEEP_CHANGELOG" == true ]]; then
    echo "  kept: CHANGELOG.md (default)"
    return 0
  fi
  if [[ ! -e "$abs" ]]; then
    return 0
  fi
  if has_kit_marker "$abs"; then
    remove_path "$rel"
    return 0
  fi
  if $LEGACY_ALLOWLIST; then
    echo "  legacy remove: $rel"
    remove_path "$rel"
    return 0
  fi
  echo "  skip (no kit marker — likely customized): $rel"
}

load_manifest() {
  MANIFEST_PATHS=()
  [[ -f "$MANIFEST" ]] || return 1
  while IFS= read -r line; do
    line="${line%%#*}"
    line="${line// /}"
    [[ "$line" == path=* ]] || continue
    MANIFEST_PATHS+=("${line#path=}")
  done <"$MANIFEST"
  [[ ${#MANIFEST_PATHS[@]} -gt 0 ]]
}

# Legacy allowlist (pre-v12, no manifest/markers)
LEGACY_PATHS=(
  .workflow-kit.env
  CLAUDE.md GEMINI.md
  docs/github-workflow.md docs/agent-platforms.md docs/troubleshooting.md
  docs/updating-workflow-kit.md docs/uninstalling-workflow-kit.md
  docs/orchestrator-integration.md docs/update-prompt.md docs/update-prompt.id.md
  docs/uninstall-prompt.md docs/uninstall-prompt.id.md
  docs/close-comment.example.md docs/issue-body.example.md
  scripts/_load-config.sh scripts/merge-agents-md.py scripts/kit-managed.py
  scripts/extract-agents-project-specific.py scripts/verify-kit-managed.sh
  scripts/gh-check-ui-tools.sh scripts/gh-close-verified-issue.sh
  scripts/gh-configure-project.sh scripts/gh-create-labels.sh
  scripts/gh-ensure-project-status.sh scripts/gh-ensure-project-status-qa.sh
  scripts/gh-set-issue-status.sh scripts/gh-setup-all.sh scripts/gh-setup-project.sh
  scripts/gh-triage-issue.sh scripts/gh-validate-issue-body.sh
  scripts/README.md scripts/project-readme.md
  .cursor/rules/github-issue-workflow.mdc .cursor/rules/code-principles.mdc
  .cursor/commands/triage.md .cursor/commands/implement.md .cursor/commands/verify.md
  .cursor/commands/close.md .cursor/commands/update.md .cursor/commands/uninstall.md
  .agents/rules/issue-workflow.md .agents/rules/code-principles.md
  .github/ISSUE_TEMPLATE/config.yml .github/ISSUE_TEMPLATE/bug.yml .github/ISSUE_TEMPLATE/feature.yml
  .gemini/settings.json
)

$DRY_RUN && echo "→ DRY RUN — no files will be modified"
echo "→ Uninstall workflow kit from: $TARGET"
echo "→ GitHub board/issues/labels: NOT touched"
echo ""

USE_MANIFEST=false
if load_manifest && [[ "$LEGACY_ALLOWLIST" != true ]]; then
  USE_MANIFEST=true
  echo "→ Using .workflow-kit/manifest (${#MANIFEST_PATHS[@]} paths) + kit markers"
else
  LEGACY_ALLOWLIST=true
  echo "→ Legacy allowlist mode (no manifest or --legacy-allowlist)"
fi
echo ""

# AGENTS.md — partial-managed marker or legacy
if [[ -f "$TARGET/AGENTS.md" && "$KEEP_AGENTS" != true ]]; then
  if agents_has_kit_marker "$TARGET/AGENTS.md" || $LEGACY_ALLOWLIST; then
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
    if agents_has_kit_marker "$TARGET/AGENTS.md" || $LEGACY_ALLOWLIST; then
      remove_path "AGENTS.md"
    else
      echo "  skip: AGENTS.md (no kit marker)"
    fi
  else
    echo "  skip: AGENTS.md (no solo-dev-ai-kit:partial-managed marker)"
  fi
elif [[ -f "$TARGET/AGENTS.md" ]]; then
  echo "  kept: AGENTS.md (--keep-agents)"
fi

if $USE_MANIFEST; then
  for rel in "${MANIFEST_PATHS[@]}"; do
    [[ "$rel" == "AGENTS.md" ]] && continue
    remove_if_managed "$rel"
  done
else
  for rel in "${LEGACY_PATHS[@]}"; do
    remove_if_managed "$rel"
  done
  if [[ "$KEEP_CHANGELOG" != true ]]; then
    remove_if_managed "CHANGELOG.md"
  fi
fi

# Empty directories after file removal
for dir in scripts .cursor/commands .cursor/rules .agents/rules .github/ISSUE_TEMPLATE .gemini; do
  if [[ -d "$TARGET/$dir" ]] && [[ -z "$(ls -A "$TARGET/$dir" 2>/dev/null)" ]]; then
    remove_path "$dir"
  elif [[ -d "$TARGET/$dir" ]] && ! $DRY_RUN; then
    echo "  kept: $dir/ (non-empty)"
  fi
done

remove_path ".workflow-kit"

echo ""
echo "  kept: docs/how-to-run.md (protected runbook)"
echo ""
if $DRY_RUN; then
  echo "Dry run complete — re-run without --dry-run to uninstall."
else
  echo "Uninstall complete. GitHub Project, issues, and labels were not modified."
  echo "Review git diff, then commit."
fi
