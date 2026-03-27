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
#     Not used directly here, but available if the banner ever needs to
#     display the install path or read a version from plugin.json.
#
# EXIT CODES
#   0 — always (cat cannot meaningfully fail on a heredoc)
# =============================================================================

# Exit immediately on any error and treat unset variables as errors.
set -euo pipefail

# ---------------------------------------------------------------------------
# Print the welcome banner using a quoted heredoc so that no variable
# expansion or command substitution occurs inside the box art — the box
# characters and special symbols are printed literally.
# ---------------------------------------------------------------------------
cat <<'EOF'
╔══════════════════════════════════════════════════════════════╗
║           Swift & iOS Developer Plugin  v4.2.0              ║
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
