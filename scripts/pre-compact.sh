#!/usr/bin/env bash
# =============================================================================
# pre-compact.sh
# =============================================================================
# PURPOSE
#   Runs automatically before conversation context is compacted (when the
#   context window is about to overflow). Saves a structured summary of
#   the current session state so that critical context survives compaction.
#
# HOW IT WORKS
#   1. Reads the transcript file path from the hook input (stdin JSON)
#   2. Extracts key context: files modified, decisions made, current phase
#   3. Writes a compact summary to .github/session-context.md in the project
#   4. Returns additionalContext to inject the summary back into the conversation
#
# HOOK EVENT
#   PreCompact — fires when the conversation is too long for the prompt budget.
#
# EXIT CODES
#   0 — always (best-effort summary)
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Parse hook input from stdin
# ---------------------------------------------------------------------------
STDIN_JSON="$(cat)"

TRANSCRIPT_PATH="$(echo "$STDIN_JSON" \
  | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    print(data.get('transcript_path', ''))
except Exception:
    pass
" 2>/dev/null)" || true

CWD="$(echo "$STDIN_JSON" \
  | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    print(data.get('cwd', ''))
except Exception:
    pass
" 2>/dev/null)" || true

WORKSPACE_ROOT="${CWD:-${VSCODE_WORKSPACE_FOLDER:-$(pwd)}}"
SESSION_CONTEXT_FILE="${WORKSPACE_ROOT}/.github/session-context.md"

# ---------------------------------------------------------------------------
# Build a summary from the transcript if available
# ---------------------------------------------------------------------------
SUMMARY=""

if [[ -n "$TRANSCRIPT_PATH" && -f "$TRANSCRIPT_PATH" ]]; then
  # Extract key info from transcript: files mentioned, agent phases, decisions
  SUMMARY="$(python3 -c "
import json, sys, re
from collections import OrderedDict

try:
    with open('$TRANSCRIPT_PATH', 'r') as f:
        transcript = json.load(f)

    files_modified = OrderedDict()
    decisions = []
    current_phase = 'Unknown'
    errors_found = []

    for entry in transcript if isinstance(transcript, list) else []:
        content = str(entry.get('content', '') or entry.get('text', ''))

        # Track files
        swift_files = re.findall(r'[\w/]+\.swift', content)
        for sf in swift_files:
            files_modified[sf] = True

        # Track phases
        phase_match = re.search(r'Phase (\d+\.?\d*)', content)
        if phase_match:
            current_phase = 'Phase ' + phase_match.group(1)

        # Track decisions
        if any(kw in content.lower() for kw in ['decided', 'chose', 'using', 'architecture']):
            if len(content) < 200:
                decisions.append(content[:150])

        # Track errors
        if 'error' in content.lower() and ('fixed' in content.lower() or 'resolved' in content.lower()):
            errors_found.append(content[:100])

    lines = []
    lines.append('# Session Context (Pre-Compaction Summary)')
    lines.append('')
    lines.append('## Current Phase')
    lines.append(current_phase)
    lines.append('')
    lines.append('## Files Modified')
    for f in list(files_modified.keys())[:30]:
        lines.append(f'- {f}')
    lines.append('')
    if decisions:
        lines.append('## Key Decisions')
        for d in decisions[:10]:
            lines.append(f'- {d}')
        lines.append('')
    if errors_found:
        lines.append('## Errors Resolved')
        for e in errors_found[:10]:
            lines.append(f'- {e}')

    print('\\n'.join(lines))
except Exception as ex:
    print(f'# Session Context\\n\\nTranscript parsing failed: {ex}')
" 2>/dev/null)" || true
fi

# If no transcript or parsing failed, create a minimal marker
if [[ -z "$SUMMARY" ]]; then
  SUMMARY="# Session Context (Pre-Compaction Summary)

Context was compacted. Previous conversation details were truncated.
Check .github/session-context.md and AGENTS.md for project context.
Re-read relevant source files before making changes."
fi

# ---------------------------------------------------------------------------
# Write summary to the project (create .github/ if needed)
# ---------------------------------------------------------------------------
mkdir -p "$(dirname "$SESSION_CONTEXT_FILE")"
echo "$SUMMARY" > "$SESSION_CONTEXT_FILE"

# ---------------------------------------------------------------------------
# Return JSON to inject context back into the conversation
# ---------------------------------------------------------------------------
cat <<JSONEOF
{
  "systemMessage": "⚠️ Context window compacted. Session summary saved to .github/session-context.md. Key project context from AGENTS.md and the codebase map are still available. Re-read source files before editing."
}
JSONEOF
