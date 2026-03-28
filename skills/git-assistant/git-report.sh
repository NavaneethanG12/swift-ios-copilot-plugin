#!/usr/bin/env bash
# =============================================================================
# git-report.sh
# =============================================================================
# PURPOSE
#   Gathers comprehensive git status information for the current repository
#   and outputs a structured report. Designed to be called by an agent via
#   the execute tool, or manually in a terminal, to understand what has
#   changed and prepare commit messages.
#
# USAGE
#   ./scripts/git-report.sh [--staged-only]
#
#   --staged-only   Only report on staged (git add) changes. Useful when
#                   preparing a commit message for already-staged files.
#
# OUTPUT
#   A structured text report printed to stdout containing:
#     - Current branch and tracking info
#     - Staged / unstaged / untracked file lists
#     - Diff stats and detailed diffs
#     - Recent commit log (last 10)
#
# DEPENDENCIES
#   git — must be installed and the working directory must be inside a repo.
#
# EXIT CODES
#   0 — success
#   1 — not inside a git repository
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Pre-flight: confirm we're inside a git repo
# ---------------------------------------------------------------------------
if ! git rev-parse --is-inside-work-tree &>/dev/null; then
  echo "ERROR: Not inside a git repository." >&2
  exit 1
fi

STAGED_ONLY=false
if [[ "${1:-}" == "--staged-only" ]]; then
  STAGED_ONLY=true
fi

REPO_ROOT=$(git rev-parse --show-toplevel)
BRANCH=$(git branch --show-current 2>/dev/null || echo "detached HEAD")
TRACKING=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null || echo "none")

# ---------------------------------------------------------------------------
# Header
# ---------------------------------------------------------------------------
cat <<EOF
════════════════════════════════════════════════════════════════
  GIT CHANGE REPORT
════════════════════════════════════════════════════════════════
  Repository : $(basename "$REPO_ROOT")
  Branch     : $BRANCH
  Tracking   : $TRACKING
  Generated  : $(date '+%Y-%m-%d %H:%M:%S')
════════════════════════════════════════════════════════════════
EOF

# ---------------------------------------------------------------------------
# Ahead / behind remote
# ---------------------------------------------------------------------------
if [[ "$TRACKING" != "none" ]]; then
  AHEAD=$(git rev-list --count @{u}..HEAD 2>/dev/null || echo "?")
  BEHIND=$(git rev-list --count HEAD..@{u} 2>/dev/null || echo "?")
  echo ""
  echo "  ↑ Ahead of remote : $AHEAD commit(s)"
  echo "  ↓ Behind remote   : $BEHIND commit(s)"
fi

# ---------------------------------------------------------------------------
# Staged changes
# ---------------------------------------------------------------------------
echo ""
echo "── STAGED CHANGES (will be committed) ──────────────────────"
STAGED=$(git diff --cached --name-status)
if [[ -z "$STAGED" ]]; then
  echo "  (none)"
else
  echo "$STAGED" | while IFS=$'\t' read -r status file; do
    case "$status" in
      A)  echo "  + added     : $file" ;;
      M)  echo "  * modified  : $file" ;;
      D)  echo "  - deleted   : $file" ;;
      R*) echo "  → renamed   : $file" ;;
      C*) echo "  © copied    : $file" ;;
      *)  echo "  ? $status   : $file" ;;
    esac
  done
fi

# ---------------------------------------------------------------------------
# Staged diff stats
# ---------------------------------------------------------------------------
STAGED_STAT=$(git diff --cached --stat 2>/dev/null)
if [[ -n "$STAGED_STAT" ]]; then
  echo ""
  echo "  Diff stats (staged):"
  echo "$STAGED_STAT" | sed 's/^/    /'
fi

if [[ "$STAGED_ONLY" == true ]]; then
  # ---------------------------------------------------------------------------
  # Staged detailed diff (for commit message generation)
  # ---------------------------------------------------------------------------
  echo ""
  echo "── STAGED DIFF (detailed) ────────────────────────────────"
  STAGED_DIFF=$(git diff --cached)
  if [[ -z "$STAGED_DIFF" ]]; then
    echo "  (no staged diff)"
  else
    echo "$STAGED_DIFF"
  fi

  echo ""
  echo "════════════════════════════════════════════════════════════════"
  echo "  End of staged-only report"
  echo "════════════════════════════════════════════════════════════════"
  exit 0
fi

# ---------------------------------------------------------------------------
# Unstaged changes (working tree)
# ---------------------------------------------------------------------------
echo ""
echo "── UNSTAGED CHANGES (not yet staged) ───────────────────────"
UNSTAGED=$(git diff --name-status)
if [[ -z "$UNSTAGED" ]]; then
  echo "  (none)"
else
  echo "$UNSTAGED" | while IFS=$'\t' read -r status file; do
    case "$status" in
      M)  echo "  * modified  : $file" ;;
      D)  echo "  - deleted   : $file" ;;
      *)  echo "  ? $status   : $file" ;;
    esac
  done
fi

# ---------------------------------------------------------------------------
# Unstaged diff stats
# ---------------------------------------------------------------------------
UNSTAGED_STAT=$(git diff --stat 2>/dev/null)
if [[ -n "$UNSTAGED_STAT" ]]; then
  echo ""
  echo "  Diff stats (unstaged):"
  echo "$UNSTAGED_STAT" | sed 's/^/    /'
fi

# ---------------------------------------------------------------------------
# Untracked files
# ---------------------------------------------------------------------------
echo ""
echo "── UNTRACKED FILES ───────────────────────────────────────────"
UNTRACKED=$(git ls-files --others --exclude-standard)
if [[ -z "$UNTRACKED" ]]; then
  echo "  (none)"
else
  echo "$UNTRACKED" | while read -r file; do
    echo "  ? new       : $file"
  done
fi

# ---------------------------------------------------------------------------
# Full diff (staged + unstaged combined stats)
# ---------------------------------------------------------------------------
echo ""
echo "── COMBINED DIFF STATS ─────────────────────────────────────"
COMBINED_STAT=$(git diff HEAD --stat 2>/dev/null)
if [[ -z "$COMBINED_STAT" ]]; then
  echo "  (no changes vs HEAD)"
else
  echo "$COMBINED_STAT" | sed 's/^/    /'
fi

# ---------------------------------------------------------------------------
# Recent commits (last 10)
# ---------------------------------------------------------------------------
echo ""
echo "── RECENT COMMITS (last 10) ────────────────────────────────"
git log --oneline --decorate -10 2>/dev/null | sed 's/^/  /'

# ---------------------------------------------------------------------------
# Files changed since last commit on remote (if tracking)
# ---------------------------------------------------------------------------
if [[ "$TRACKING" != "none" ]]; then
  echo ""
  echo "── FILES CHANGED vs REMOTE ($TRACKING) ────────────────────"
  REMOTE_DIFF=$(git diff --name-status "$TRACKING"...HEAD 2>/dev/null)
  if [[ -z "$REMOTE_DIFF" ]]; then
    echo "  (in sync with remote)"
  else
    echo "$REMOTE_DIFF" | while IFS=$'\t' read -r status file; do
      case "$status" in
        A)  echo "  + added     : $file" ;;
        M)  echo "  * modified  : $file" ;;
        D)  echo "  - deleted   : $file" ;;
        R*) echo "  → renamed   : $file" ;;
        *)  echo "  ? $status   : $file" ;;
      esac
    done
  fi
fi

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "  End of report"
echo "════════════════════════════════════════════════════════════════"
