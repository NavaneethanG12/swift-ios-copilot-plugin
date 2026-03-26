#!/usr/bin/env bash
# =============================================================================
# post-edit.sh
# =============================================================================
# PURPOSE
#   Runs automatically after the Copilot agent writes or edits a file
#   (triggered by the PostToolUse hook defined in hooks/hooks.json).
#   For Swift source files, it applies swift-format to keep code style
#   consistent without requiring developers to run a formatter manually.
#
# HOOK EVENT
#   PostToolUse (matcher: Write|Edit)
#   The hook fires once per file write/edit operation.
#
# INPUT
#   VS Code (following the Claude Code hook protocol) delivers the tool-use
#   event as a JSON object on stdin. The shape is:
#     { "tool_input": { "path": "/abs/path/to/file.swift", ... }, ... }
#   We extract the file path with `python3 -c` since python3 ships with
#   every macOS version that supports VS Code and requires no extra tools.
#
# ENVIRONMENT
#   CLAUDE_PLUGIN_ROOT — absolute path to this plugin's directory, injected
#     by VS Code when the hook command is expanded in hooks.json.
#
# DEPENDENCIES
#   python3   — pre-installed on macOS (used to parse JSON from stdin)
#   swift-format (optional) — https://github.com/apple/swift-format
#     Install via Homebrew:  brew install swift-format
#     Or build from source:  https://github.com/apple/swift-format#getting-started
#
# EXIT CODES
#   0 — success (file formatted, skipped because non-Swift, or no path given)
#   Non-zero — swift-format itself failed (set -e propagates the error)
# =============================================================================

# Treat unset variables as errors, propagate pipeline failures, and exit
# immediately if any command returns a non-zero status.
set -euo pipefail

# ---------------------------------------------------------------------------
# Parse the file path from the JSON payload delivered on stdin.
#
# The hook runtime sends JSON to stdin; we read it all at once into STDIN_JSON
# and then use python3 to extract tool_input.path.  If the key is absent (e.g.
# the tool had no path field) python3 prints nothing and FILE stays empty.
# We use `|| true` so a malformed JSON payload does not abort the script.
# ---------------------------------------------------------------------------
STDIN_JSON="$(cat)"  # consume stdin before any other reads

FILE="$(echo "$STDIN_JSON" \
  | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    # tool_input.path is where VS Code / Claude Code puts the edited file path
    print(data.get('tool_input', {}).get('path', ''))
except Exception:
    pass
" 2>/dev/null)" || true

# Nothing to do if we couldn't determine the file path.
if [[ -z "$FILE" ]]; then
  exit 0
fi

# ---------------------------------------------------------------------------
# Guard: only process Swift source files.
# The glob pattern *.swift matches the extension case-sensitively on macOS.
# Objective-C, header, markdown, JSON, and other files are left untouched.
# ---------------------------------------------------------------------------
if [[ "$FILE" != *.swift ]]; then
  exit 0
fi

# ---------------------------------------------------------------------------
# Format the file if swift-format is available.
# `command -v` is POSIX-portable and returns 0 only when the binary exists
# on PATH; it does not execute the binary.
# ---------------------------------------------------------------------------
if command -v swift-format &>/dev/null; then
  # --in-place rewrites the file directly; no temp-file dance needed.
  swift-format format --in-place "$FILE"
  echo "[swift-ios-dev] Formatted: $FILE"
else
  # Emit a one-time advisory so the developer knows formatting was skipped.
  # This message appears in the Copilot Chat output panel.
  echo "[swift-ios-dev] swift-format not found — skipping auto-format for: $FILE"
  echo "[swift-ios-dev] Install it with:  brew install swift-format"
  echo "[swift-ios-dev] Or see: https://github.com/apple/swift-format"
fi
