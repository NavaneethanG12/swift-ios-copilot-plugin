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
║           Swift & iOS Developer Plugin  v4.1.0              ║
╠══════════════════════════════════════════════════════════════╣
║                                                              ║
║  ★ Select "ios-copilot" from the agent picker ★             ║
║    It's the root orchestrator — just type your prompt        ║
║    and it will restructure it and route to the right agent.  ║
║                                                              ║
║  Skills  (24 — type / in chat to invoke directly):           ║
║  ── Build ──                                                ║
║    /project-scaffolding   /swiftui-development               ║
║    /networking            /data-persistence                  ║
║    /architecture-patterns /design-system                     ║
║  ── Quality ──                                              ║
║    /swift-code-review     /testing                           ║
║    /ios-debugging          /crash-diagnosis                  ║
║    /memory-management      /swift-concurrency                ║
║    /performance-optimization                                 ║
║  ── Ship ──                                                 ║
║    /ios-security     /accessibility    /localization          ║
║    /ci-cd            /app-store-submission                    ║
║  ── Platform ──                                             ║
║    /platform-adaptation   /push-notifications                ║
║    /storekit              /deep-linking                      ║
║    /background-tasks      /widgets-extensions                ║
║                                                              ║
║  Agents (8):                                                ║
║    ios-copilot ★    — orchestrator (start here)              ║
║    app-builder      — scaffold & build apps                  ║
║    ios-architect    — plan architecture                       ║
║    swift-reviewer   — review code                            ║
║    test-engineer    — write tests                            ║
║    security-auditor — audit vulnerabilities                   ║
║    crash-analyst    — diagnose crashes                        ║
║    memory-profiler  — fix memory issues                      ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
EOF
