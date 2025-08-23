#!/usr/bin/env sh

# Common aliases shared between bash and zsh

# ls aliases with eza fallback
if command -v eza >/dev/null 2>&1; then
    alias ll='eza -la --icons --group-directories-first --git'
    alias la='eza -a --icons --group-directories-first'
    alias l='eza --icons --group-directories-first'
else
    alias ll='ls -alF'
    alias la='ls -A'
    alias l='ls -CF'
fi

# eza aliases
alias lz='eza --icons --group-directories-first'
alias lzl='eza -la --icons --group-directories-first --git'
