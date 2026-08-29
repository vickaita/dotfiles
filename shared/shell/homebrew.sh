#!/usr/bin/env bash

# Initialize Homebrew environment from the standard paths for the active OS.
case "$(uname)" in
    Darwin)
        if [[ -x "/opt/homebrew/bin/brew" ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        elif [[ -x "/usr/local/bin/brew" ]]; then
            eval "$(/usr/local/bin/brew shellenv)"
        fi
        ;;
    Linux)
        if [[ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
            eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
        elif [[ -x "$HOME/.linuxbrew/bin/brew" ]]; then
            eval "$("$HOME/.linuxbrew/bin/brew" shellenv)"
        fi
        ;;
esac
