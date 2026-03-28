#!/usr/bin/env bash
# =============================================================================
# project-discover.sh
# =============================================================================
# PURPOSE
#   Quick project analysis that detects project type, state, frameworks,
#   and existing docs. Returns structured info as JSON that can be used
#   by the SessionStart hook to inject context.
#
# USAGE
#   Called by session-start.sh to get project metadata.
#   Writes JSON to stdout.
#
# EXIT CODES
#   0 — always (best-effort discovery)
# =============================================================================

set -euo pipefail

WORKSPACE_ROOT="${1:-${VSCODE_WORKSPACE_FOLDER:-$(pwd)}}"

# ---------------------------------------------------------------------------
# Detect project type
# ---------------------------------------------------------------------------
PROJECT_TYPE="unknown"
if [ -f "$WORKSPACE_ROOT/Package.swift" ]; then
  PROJECT_TYPE="spm"
elif ls "$WORKSPACE_ROOT"/*.xcworkspace 1>/dev/null 2>&1; then
  PROJECT_TYPE="xcworkspace"
elif ls "$WORKSPACE_ROOT"/*.xcodeproj 1>/dev/null 2>&1; then
  PROJECT_TYPE="xcodeproj"
elif ls "$WORKSPACE_ROOT"/*.playground 1>/dev/null 2>&1; then
  PROJECT_TYPE="playground"
fi

# ---------------------------------------------------------------------------
# Count Swift files to determine project state
# ---------------------------------------------------------------------------
SWIFT_COUNT=$(find "$WORKSPACE_ROOT" -name "*.swift" -not -path "*/.*" -not -path "*/.build/*" -not -path "*/DerivedData/*" -not -path "*/Pods/*" 2>/dev/null | wc -l | tr -d ' ')

PROJECT_STATE="new"
if [ "$SWIFT_COUNT" -gt 50 ]; then
  PROJECT_STATE="mature"
elif [ "$SWIFT_COUNT" -gt 5 ]; then
  PROJECT_STATE="ongoing"
fi

# ---------------------------------------------------------------------------
# Detect UI framework
# ---------------------------------------------------------------------------
UI_FRAMEWORK="unknown"
HAS_SWIFTUI=$(grep -rl "import SwiftUI" "$WORKSPACE_ROOT" --include="*.swift" -l 2>/dev/null | head -1 || true)
HAS_UIKIT=$(grep -rl "import UIKit" "$WORKSPACE_ROOT" --include="*.swift" -l 2>/dev/null | head -1 || true)

if [ -n "$HAS_SWIFTUI" ] && [ -n "$HAS_UIKIT" ]; then
  UI_FRAMEWORK="mixed"
elif [ -n "$HAS_SWIFTUI" ]; then
  UI_FRAMEWORK="swiftui"
elif [ -n "$HAS_UIKIT" ]; then
  UI_FRAMEWORK="uikit"
fi

# ---------------------------------------------------------------------------
# Check for existing knowledge docs
# ---------------------------------------------------------------------------
HAS_AGENTS_MD="false"
HAS_CODEBASE_MAP="false"
HAS_DOCS_DIR="false"
HAS_ARCHITECTURE="false"
HAS_CONVENTIONS="false"
HAS_GLOSSARY="false"
MISSING_DOCS=""

[ -f "$WORKSPACE_ROOT/AGENTS.md" ] && HAS_AGENTS_MD="true"
[ -f "$WORKSPACE_ROOT/.github/instructions/codebase-map.instructions.md" ] && HAS_CODEBASE_MAP="true"
[ -d "$WORKSPACE_ROOT/docs/ai-agents" ] && HAS_DOCS_DIR="true"
[ -f "$WORKSPACE_ROOT/docs/architecture/ARCHITECTURE.md" ] && HAS_ARCHITECTURE="true"
[ -f "$WORKSPACE_ROOT/docs/development/CONVENTIONS.md" ] && HAS_CONVENTIONS="true"
[ -f "$WORKSPACE_ROOT/docs/ai-agents/GLOSSARY.md" ] && HAS_GLOSSARY="true"

# Build missing docs list
if [ "$HAS_AGENTS_MD" = "false" ]; then
  MISSING_DOCS="AGENTS.md"
fi
if [ "$HAS_DOCS_DIR" = "false" ]; then
  MISSING_DOCS="${MISSING_DOCS:+$MISSING_DOCS, }docs/ai-agents/"
fi
if [ "$HAS_ARCHITECTURE" = "false" ]; then
  MISSING_DOCS="${MISSING_DOCS:+$MISSING_DOCS, }ARCHITECTURE"
fi
if [ "$HAS_CONVENTIONS" = "false" ]; then
  MISSING_DOCS="${MISSING_DOCS:+$MISSING_DOCS, }CONVENTIONS"
fi
if [ "$HAS_GLOSSARY" = "false" ]; then
  MISSING_DOCS="${MISSING_DOCS:+$MISSING_DOCS, }GLOSSARY"
fi

# ---------------------------------------------------------------------------
# Detect dependencies
# ---------------------------------------------------------------------------
HAS_COCOAPODS="false"
HAS_CARTHAGE="false"
HAS_SPM_DEPS="false"

[ -f "$WORKSPACE_ROOT/Podfile" ] && HAS_COCOAPODS="true"
[ -f "$WORKSPACE_ROOT/Cartfile" ] && HAS_CARTHAGE="true"
[ -f "$WORKSPACE_ROOT/Package.resolved" ] && HAS_SPM_DEPS="true"

# ---------------------------------------------------------------------------
# Check for .swiftlint.yml / .swift-format
# ---------------------------------------------------------------------------
HAS_LINTER="false"
HAS_FORMATTER="false"
[ -f "$WORKSPACE_ROOT/.swiftlint.yml" ] && HAS_LINTER="true"
[ -f "$WORKSPACE_ROOT/.swift-format" ] && HAS_FORMATTER="true"

# ---------------------------------------------------------------------------
# Output structured JSON
# ---------------------------------------------------------------------------
cat <<JSONEOF
{
  "project_type": "$PROJECT_TYPE",
  "project_state": "$PROJECT_STATE",
  "swift_file_count": $SWIFT_COUNT,
  "ui_framework": "$UI_FRAMEWORK",
  "has_agents_md": $HAS_AGENTS_MD,
  "has_codebase_map": $HAS_CODEBASE_MAP,
  "has_docs_dir": $HAS_DOCS_DIR,
  "has_architecture": $HAS_ARCHITECTURE,
  "has_conventions": $HAS_CONVENTIONS,
  "has_glossary": $HAS_GLOSSARY,
  "missing_docs": "$MISSING_DOCS",
  "has_cocoapods": $HAS_COCOAPODS,
  "has_carthage": $HAS_CARTHAGE,
  "has_spm_deps": $HAS_SPM_DEPS,
  "has_linter": $HAS_LINTER,
  "has_formatter": $HAS_FORMATTER
}
JSONEOF
