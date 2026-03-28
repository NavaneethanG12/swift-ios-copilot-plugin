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
# Check if the project has a codebase map. If not, nudge the user.
# ---------------------------------------------------------------------------
WORKSPACE_ROOT="${VSCODE_WORKSPACE_FOLDER:-$(pwd)}"
MAP_FILE="${WORKSPACE_ROOT}/.github/instructions/codebase-map.instructions.md"

if [ ! -f "$MAP_FILE" ]; then
  cat <<'MAPEOF'

⚠️  No codebase map found for this project.
   Agents will scan all files on every prompt (slow for large projects).

   To generate one, tell ios-copilot:
     "generate the codebase map for this project"

   This creates .github/instructions/codebase-map.instructions.md
   so agents only read files relevant to each task.
MAPEOF
fi

# ---------------------------------------------------------------------------
# Check for AGENTS.md — the always-on project context file.
# VS Code auto-reads AGENTS.md from the workspace root for every prompt.
# ---------------------------------------------------------------------------
AGENTS_FILE="${WORKSPACE_ROOT}/AGENTS.md"

if [ ! -f "$AGENTS_FILE" ]; then
  cat <<'AGENTSEOF'

⚠️  No AGENTS.md found in the project root.
   Without it, agents have no project-level context (architecture,
   conventions, module structure, key decisions).

   Tell ios-copilot:
     "create the AGENTS.md for this project"

   This creates AGENTS.md with project context (architecture,
   conventions, modules, dependencies) — readable by any agent.
AGENTSEOF
else
  echo ""
  echo "✅ AGENTS.md found — project context will be loaded automatically."
fi
