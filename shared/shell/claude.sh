#!/bin/sh

# Claude CLI configuration
if [ -d "$HOME/.claude/local" ]; then
    prepend_to_path "$HOME/.claude/local"
fi