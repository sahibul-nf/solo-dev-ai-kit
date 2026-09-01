#!/usr/bin/env bash
# Set GitHub Project board Status for an issue.
#
# Usage:
#   ./scripts/gh-set-issue-status.sh 14 progress
#   ./scripts/gh-set-issue-status.sh 14 qa
#
# Status: backlog | progress | qa | done
#
# If GH_PROJECT_NUM is unset: prints note and exits 0 (no-op).
# Exit: 0 success or no-op; 1 unknown status or gh failure
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=_load-config.sh
source "$(dirname "$0")/_load-config.sh"
_load_config "$ROOT"

REPO="${GH_REPO:?Set GH_REPO in .workflow-kit.env}"
OWNER="${GH_PROJECT_OWNER:-@me}"
PROJECT_NUM="${GH_PROJECT_NUM:-}"

ISSUE=""
STATUS=""

status_label() {
  case "$1" in
    backlog) echo "Backlog" ;;
    progress) echo "In Progress" ;;
    qa) echo "QA" ;;
    done) echo "Done" ;;
    *)
      echo "error: unknown status '$1' (use backlog|progress|qa|done)" >&2
      exit 1
      ;;
  esac
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -*) echo "Unknown arg: $1" >&2; exit 1 ;;
    *)
      if [[ -z "$ISSUE" ]]; then ISSUE="$1"; shift
      elif [[ -z "$STATUS" ]]; then STATUS="$1"; shift
      else echo "Unexpected arg: $1" >&2; exit 1
      fi
      ;;
  esac
done

[[ -n "$ISSUE" && -n "$STATUS" ]] || {
  echo "Usage: $0 <issue-number> backlog|progress|qa|done" >&2
  exit 1
}

[[ -n "$PROJECT_NUM" ]] || {
  echo "Note: GH_PROJECT_NUM unset — cannot update board status for #$ISSUE" >&2
  exit 0
}

LABEL="$(status_label "$STATUS")"
ISSUE_URL="$(gh issue view "$ISSUE" --repo "$REPO" --json url --jq .url)"

PROJECT_ID="$(gh project view "$PROJECT_NUM" --owner "$OWNER" --format json --jq .id)"
STATUS_FIELD="$(gh project field-list "$PROJECT_NUM" --owner "$OWNER" --format json \
  | jq -r '.fields[] | select(.name=="Status") | .id')"

[[ -n "$STATUS_FIELD" && "$STATUS_FIELD" != "null" ]] || {
  echo "error: no Status field on project $PROJECT_NUM" >&2
  exit 1
}

OPTION_ID="$(gh project field-list "$PROJECT_NUM" --owner "$OWNER" --format json \
  | jq -r --arg label "$LABEL" \
    '.fields[] | select(.name=="Status") | .options[]? | select(.name==$label) | .id')"

[[ -n "$OPTION_ID" && "$OPTION_ID" != "null" ]] || {
  echo "error: Status option '$LABEL' not found on project $PROJECT_NUM" >&2
  echo "Run ./scripts/gh-ensure-project-status-qa.sh if QA column is missing." >&2
  exit 1
}

ITEM_ID="$(gh project item-list "$PROJECT_NUM" --owner "$OWNER" --format json --limit 200 \
  | jq -r --arg url "$ISSUE_URL" '.items[] | select(.content.url==$url) | .id' | head -n1)"

if [[ -z "$ITEM_ID" || "$ITEM_ID" == "null" ]]; then
  gh project item-add "$PROJECT_NUM" --owner "$OWNER" --url "$ISSUE_URL" >/dev/null
  ITEM_ID="$(gh project item-list "$PROJECT_NUM" --owner "$OWNER" --format json --limit 200 \
    | jq -r --arg url "$ISSUE_URL" '.items[] | select(.content.url==$url) | .id' | head -n1)"
fi

[[ -n "$ITEM_ID" && "$ITEM_ID" != "null" ]] || {
  echo "error: could not find or add project item for #$ISSUE" >&2
  exit 1
}

gh project item-edit --id "$ITEM_ID" --project-id "$PROJECT_ID" \
  --field-id "$STATUS_FIELD" --single-select-option-id "$OPTION_ID" >/dev/null

echo "Set #$ISSUE board Status → $LABEL"
