#!/usr/bin/env sh

# GitHub Copilot CLI integration
# Only load aliases if gh is available and copilot extension is installed

if command -v gh >/dev/null 2>&1; then
    if gh extension list | grep -q "github/gh-copilot" 2>/dev/null; then
        # Generate official GitHub Copilot aliases for the current shell
        eval "$(gh copilot alias -- "$CURRENT_SHELL")"
    fi
fi