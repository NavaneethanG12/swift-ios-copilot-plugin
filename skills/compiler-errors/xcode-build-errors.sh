#!/usr/bin/env bash
# =============================================================================
# xcode-build-errors.sh
# =============================================================================
# PURPOSE
#   Runs xcodebuild on the user's project and extracts compiler errors in a
#   structured, agent-parseable format. Designed to be called by the app-builder
#   agent during Phase 0.75 (Compiler Error Resolution).
#
# USAGE
#   ./xcode-build-errors.sh [project-dir] [scheme] [extra-args...]
#
#   project-dir  — path to the directory containing .xcodeproj or .xcworkspace
#                  (default: current directory)
#   scheme       — Xcode scheme to build (default: auto-detected)
#   extra-args   — additional xcodebuild flags (e.g. -sdk iphonesimulator)
#
# OUTPUT
#   Prints a structured error report to stdout:
#   - Project/workspace detected
#   - Build command used
#   - Each error with file path, line number, column, and message
#   - Summary count
#
# EXIT CODES
#   0 — script completed (even if build has errors — errors are the output)
#   1 — no Xcode project found
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Arguments
# ---------------------------------------------------------------------------
PROJECT_DIR="${1:-.}"
SCHEME="${2:-}"

# Shift only the args that were actually provided
if [[ $# -ge 2 ]]; then
  shift 2
elif [[ $# -ge 1 ]]; then
  shift 1
fi
EXTRA_ARGS=()
if [[ $# -gt 0 ]]; then
  EXTRA_ARGS=("$@")
fi

# Resolve to absolute path
PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"

# ---------------------------------------------------------------------------
# Detect project type (.xcworkspace takes priority over .xcodeproj)
# ---------------------------------------------------------------------------
WORKSPACE=""
PROJECT=""

if ls "$PROJECT_DIR"/*.xcworkspace 1>/dev/null 2>&1; then
  WORKSPACE="$(ls -d "$PROJECT_DIR"/*.xcworkspace | head -1)"
elif ls "$PROJECT_DIR"/*.xcodeproj 1>/dev/null 2>&1; then
  PROJECT="$(ls -d "$PROJECT_DIR"/*.xcodeproj | head -1)"
else
  echo "ERROR: No .xcworkspace or .xcodeproj found in $PROJECT_DIR"
  echo "Provide the path to the project directory as the first argument."
  exit 1
fi

# ---------------------------------------------------------------------------
# Auto-detect scheme if not provided
# ---------------------------------------------------------------------------
if [[ -z "$SCHEME" ]]; then
  if [[ -n "$WORKSPACE" ]]; then
    SCHEME="$(xcodebuild -workspace "$WORKSPACE" -list 2>/dev/null \
      | sed -n '/Schemes:/,/^$/p' | grep -v 'Schemes:' | head -1 | xargs)" || true
  elif [[ -n "$PROJECT" ]]; then
    SCHEME="$(xcodebuild -project "$PROJECT" -list 2>/dev/null \
      | sed -n '/Schemes:/,/^$/p' | grep -v 'Schemes:' | head -1 | xargs)" || true
  fi
fi

if [[ -z "$SCHEME" ]]; then
  echo "ERROR: Could not auto-detect scheme. Provide it as the second argument."
  exit 1
fi

# ---------------------------------------------------------------------------
# Build the xcodebuild command
# ---------------------------------------------------------------------------
BUILD_CMD=(xcodebuild)

if [[ -n "$WORKSPACE" ]]; then
  BUILD_CMD+=(-workspace "$WORKSPACE")
  echo "=== Workspace: $WORKSPACE ==="
elif [[ -n "$PROJECT" ]]; then
  BUILD_CMD+=(-project "$PROJECT")
  echo "=== Project: $PROJECT ==="
fi

BUILD_CMD+=(-scheme "$SCHEME")
BUILD_CMD+=(-destination "generic/platform=iOS Simulator")
BUILD_CMD+=(build)
if [[ ${#EXTRA_ARGS[@]} -gt 0 ]]; then
  BUILD_CMD+=("${EXTRA_ARGS[@]}")
fi

echo "=== Scheme: $SCHEME ==="
echo "=== Command: ${BUILD_CMD[*]} ==="
echo ""

# ---------------------------------------------------------------------------
# Run xcodebuild, capture output (allow failure — errors are our output)
# ---------------------------------------------------------------------------
BUILD_OUTPUT="$("${BUILD_CMD[@]}" 2>&1)" || true

# ---------------------------------------------------------------------------
# Extract errors and warnings
# ---------------------------------------------------------------------------
echo "=== COMPILER ERRORS ==="
echo ""

# Pattern: /path/to/file.swift:LINE:COL: error: message
ERROR_LINES="$(echo "$BUILD_OUTPUT" | grep -E ':\d+:\d+: error:' || true)"
WARNING_LINES="$(echo "$BUILD_OUTPUT" | grep -E ':\d+:\d+: warning:' || true)"

# Also capture linker errors
LINKER_ERRORS="$(echo "$BUILD_OUTPUT" | grep -E 'ld: |Undefined symbol|linker command failed' || true)"

# Module-level errors (no such module, etc.)
MODULE_ERRORS="$(echo "$BUILD_OUTPUT" | grep -E "error: no such module|error: missing required module" || true)"

# Project-level warnings (no file:line:col — e.g. deployment target, signing, build settings)
PROJECT_WARNINGS="$(echo "$BUILD_OUTPUT" | grep -E '^warning: ' || true)"

ERROR_COUNT=0
WARNING_COUNT=0

if [[ -n "$ERROR_LINES" ]]; then
  while IFS= read -r line; do
    ERROR_COUNT=$((ERROR_COUNT + 1))
    # Parse components
    FILE_PATH="$(echo "$line" | cut -d: -f1)"
    LINE_NUM="$(echo "$line" | cut -d: -f2)"
    COL_NUM="$(echo "$line" | cut -d: -f3)"
    MESSAGE="$(echo "$line" | sed 's/^[^:]*:[0-9]*:[0-9]*: error: //')"

    echo "ERROR #${ERROR_COUNT}:"
    echo "  File: $FILE_PATH"
    echo "  Line: $LINE_NUM, Column: $COL_NUM"
    echo "  Message: $MESSAGE"
    echo ""
  done <<< "$ERROR_LINES"
fi

if [[ -n "$MODULE_ERRORS" ]]; then
  while IFS= read -r line; do
    ERROR_COUNT=$((ERROR_COUNT + 1))
    echo "ERROR #${ERROR_COUNT} (Module):"
    echo "  Message: $line"
    echo ""
  done <<< "$MODULE_ERRORS"
fi

if [[ -n "$LINKER_ERRORS" ]]; then
  while IFS= read -r line; do
    ERROR_COUNT=$((ERROR_COUNT + 1))
    echo "ERROR #${ERROR_COUNT} (Linker):"
    echo "  Message: $line"
    echo ""
  done <<< "$LINKER_ERRORS"
fi

echo "=== COMPILER WARNINGS ==="
echo ""

if [[ -n "$WARNING_LINES" ]]; then
  while IFS= read -r line; do
    WARNING_COUNT=$((WARNING_COUNT + 1))
    FILE_PATH="$(echo "$line" | cut -d: -f1)"
    LINE_NUM="$(echo "$line" | cut -d: -f2)"
    COL_NUM="$(echo "$line" | cut -d: -f3)"
    MESSAGE="$(echo "$line" | sed 's/^[^:]*:[0-9]*:[0-9]*: warning: //')"

    echo "WARNING #${WARNING_COUNT}:"
    echo "  File: $FILE_PATH"
    echo "  Line: $LINE_NUM, Column: $COL_NUM"
    echo "  Message: $MESSAGE"
    echo ""
  done <<< "$WARNING_LINES"
fi

if [[ -n "$PROJECT_WARNINGS" ]]; then
  while IFS= read -r line; do
    WARNING_COUNT=$((WARNING_COUNT + 1))
    MESSAGE="$(echo "$line" | sed 's/^warning: //')"
    echo "WARNING #${WARNING_COUNT} (Project):"
    echo "  Message: $MESSAGE"
    echo ""
  done <<< "$PROJECT_WARNINGS"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo "=== SUMMARY ==="
echo "  Errors:   $ERROR_COUNT"
echo "  Warnings: $WARNING_COUNT"

if [[ "$ERROR_COUNT" -eq 0 ]]; then
  echo "  Status: BUILD SUCCEEDED"
else
  echo "  Status: BUILD FAILED"
fi

# Also capture the last few lines for any high-level build system errors
TAIL_LINES="$(echo "$BUILD_OUTPUT" | tail -5)"
echo ""
echo "=== BUILD SYSTEM OUTPUT (last 5 lines) ==="
echo "$TAIL_LINES"
