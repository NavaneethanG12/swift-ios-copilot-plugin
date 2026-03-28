#!/usr/bin/env bash
# =============================================================================
# session-start.sh
# =============================================================================
# PURPOSE
#   Runs once at the beginning of every Copilot agent session (triggered by
#   the SessionStart hook defined in hooks/hooks.json). Prints a compact
#   welcome banner so developers immediately know which skills and agents are
#   available from the swift-ios-dev plugin without having to open docs.
#
# HOOK EVENT
#   SessionStart — fires when a new agent session is initialised.
#   This script has no side effects on the file system; it only writes
#   to stdout, which is captured and shown in the Copilot Chat output panel.
#
# ENVIRONMENT
#   CLAUDE_PLUGIN_ROOT — absolute path to this plugin's directory,
#     injected by VS Code when the hook command is expanded.
#   Version is read dynamically from plugin.json via python3.
#
# EXIT CODES
#   0 — always (cat cannot meaningfully fail on a heredoc)
# =============================================================================

# Exit immediately on any error and treat unset variables as errors.
set -euo pipefail

# ---------------------------------------------------------------------------
# Read version from plugin.json so the banner stays in sync automatically.
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(dirname "$SCRIPT_DIR")"
VERSION=$(python3 -c "import json; print(json.load(open('${PLUGIN_ROOT}/plugin.json'))['version'])" 2>/dev/null || echo "unknown")

# ---------------------------------------------------------------------------
# Print the welcome banner.
# ---------------------------------------------------------------------------
cat <<EOF
╔══════════════════════════════════════════════════════════════╗
║           Swift & iOS Developer Plugin  v${VERSION}              ║
╠══════════════════════════════════════════════════════════════╣
║                                                              ║
║  ★ Select "ios-copilot" from the agent picker ★             ║
║    It's the root orchestrator — just type your prompt        ║
║    and it will restructure it and route to the right agent.  ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
EOF

# ---------------------------------------------------------------------------
# Run project discovery to detect project state and existing docs
# ---------------------------------------------------------------------------
WORKSPACE_ROOT="${VSCODE_WORKSPACE_FOLDER:-$(pwd)}"
DISCOVER_RESULT=$("$SCRIPT_DIR/project-discover.sh" "$WORKSPACE_ROOT" 2>/dev/null || echo '{}')

# Parse key fields from discovery JSON
HAS_AGENTS_MD=$(echo "$DISCOVER_RESULT" | python3 -c "import json,sys; print(json.load(sys.stdin).get('has_agents_md', False))" 2>/dev/null || echo "False")
HAS_DOCS_DIR=$(echo "$DISCOVER_RESULT" | python3 -c "import json,sys; print(json.load(sys.stdin).get('has_docs_dir', False))" 2>/dev/null || echo "False")
MISSING_DOCS=$(echo "$DISCOVER_RESULT" | python3 -c "import json,sys; print(json.load(sys.stdin).get('missing_docs', ''))" 2>/dev/null || echo "")
PROJECT_STATE=$(echo "$DISCOVER_RESULT" | python3 -c "import json,sys; print(json.load(sys.stdin).get('project_state', 'unknown'))" 2>/dev/null || echo "unknown")
SWIFT_COUNT=$(echo "$DISCOVER_RESULT" | python3 -c "import json,sys; print(json.load(sys.stdin).get('swift_file_count', 0))" 2>/dev/null || echo "0")
UI_FRAMEWORK=$(echo "$DISCOVER_RESULT" | python3 -c "import json,sys; print(json.load(sys.stdin).get('ui_framework', 'unknown'))" 2>/dev/null || echo "unknown")

# ---------------------------------------------------------------------------
# Show project knowledge status
# ---------------------------------------------------------------------------
if [ "$HAS_AGENTS_MD" = "True" ] && [ "$HAS_DOCS_DIR" = "True" ]; then
  echo ""
  echo "✅ Project knowledge context found (AGENTS.md + docs/ai-agents/)."
  echo "   Agents will auto-load project context on every prompt."

  # Check if any individual docs are missing
  if [ -n "$MISSING_DOCS" ]; then
    echo ""
    echo "⚠️  Some docs are incomplete: $MISSING_DOCS"
    echo "   Run /bootstrap-project to regenerate missing docs."
  fi

elif [ "$HAS_AGENTS_MD" = "True" ]; then
  echo ""
  echo "⚠️  AGENTS.md found but detailed docs (docs/ai-agents/) are missing."
  echo "   Agents have basic context but lack codebase map, glossary,"
  echo "   architecture, and convention docs."
  echo ""
  echo "   Tell ios-copilot: \"bootstrap the project knowledge\""
  echo "   Or run: /bootstrap-project"

else
  cat <<'NOCONTEXTEOF'

⚠️  No project knowledge context found.
   Without it, agents have no understanding of your project's
   architecture, conventions, domain terms, or file structure.

   This is a one-time setup. Tell ios-copilot:
     "bootstrap the project knowledge"
   Or run: /bootstrap-project

   This generates:
   • AGENTS.md — project index (auto-read every prompt)
   • docs/ai-agents/ — codebase map, glossary, plan rules
   • docs/architecture/ — architecture documentation
   • docs/development/ — code conventions
NOCONTEXTEOF
fi

# ---------------------------------------------------------------------------
# Show project summary for the agent's context
# ---------------------------------------------------------------------------
echo ""
echo "📊 Project: $PROJECT_STATE ($SWIFT_COUNT Swift files, UI: $UI_FRAMEWORK)"
