#!/usr/bin/env bash
# Report UI verification tool availability (check only — never installs).
set -euo pipefail

echo "UI verification tools (check only — kit does not install browsers):"
echo ""

if [[ -n "${CURSOR_AGENT:-}" || -n "${CURSOR_TRACE_ID:-}" ]]; then
  echo "  Cursor IDE browser: available (native MCP in Cursor)"
else
  echo "  Cursor IDE browser: use when working in Cursor (native MCP)"
fi

if command -v npx >/dev/null 2>&1; then
  echo "  Node/npx: yes ($(npx --version 2>/dev/null || echo unknown))"
  if npx --yes @playwright/cli@latest --version >/dev/null 2>&1; then
    echo "  Playwright CLI: yes (optional fallback)"
  else
    echo "  Playwright CLI: not detected (optional — install manually if needed)"
  fi
else
  echo "  Node/npx: no (Playwright fallback unavailable)"
fi

if [[ -f "docs/how-to-run.md" ]]; then
  if grep -q 'localhost' docs/how-to-run.md 2>/dev/null || grep -q 'http' docs/how-to-run.md 2>/dev/null; then
    echo "  docs/how-to-run.md: present (check local URL is filled in)"
  else
    echo "  docs/how-to-run.md: present — fill in local URL for UI verify"
  fi
else
  echo "  docs/how-to-run.md: missing — bootstrap will create template"
fi

echo ""
echo "Default: Cursor IDE browser. Playwright/Puppeteer only if already in project."
