#!/bin/zsh -l
# Double-click to start Claude Code in this folder with Remote Control,
# so the session appears in the Code tab of the Claude app on your phone.
cd "$HOME/Claude/Bokspring" || exit 1
export PATH="$HOME/.local/bin:$HOME/.claude/local:/opt/homebrew/bin:/usr/local/bin:$PATH"
if ! command -v claude >/dev/null 2>&1; then
  echo "Claude Code (the 'claude' command) is not installed or not on PATH."
  echo "Install it from https://code.claude.com, then double-click this file again."
  read -k1 "?Press any key to close."
  exit 1
fi
echo "Starting Claude Code Remote Control in $(pwd)..."
claude remote-control
