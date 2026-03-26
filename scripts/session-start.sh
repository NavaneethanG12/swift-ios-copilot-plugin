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
╔══════════════════════════════════════════════════════════╗
║          Swift & iOS Developer Plugin  v1.0.0           ║
╠══════════════════════════════════════════════════════════╣
║  Skills  (type / in chat to invoke):                     ║
║    /swift-code-review  — audit Swift files for issues    ║
║    /ios-debugging      — diagnose crashes & build errors ║
║                                                          ║
║  Agents  (select from the agent picker):                 ║
║    ios-architect   — plan features & architecture        ║
║    swift-reviewer  — review code with handoff workflow   ║
║                                                          ║
║  Auto-formatting: edited .swift files are formatted      ║
║  with swift-format on save (if installed).               ║
╚══════════════════════════════════════════════════════════╝
EOF
