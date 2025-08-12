# Adds a segment to the path if it's not already there
prepend_to_path() {
    if [[ ! ":$PATH:" == *":$1:"* ]]; then
        export PATH="$1:$PATH"
    fi
}

# Adds a segment to the end of the path if it's not already there
append_to_path() {
    if [[ ! ":$PATH:" == *":$1:"* ]]; then
        export PATH="$PATH:$1"
    fi
}

# Rebuild shell completions (useful after installing new software)
rebuild-completions() {
    echo "🔄 Rebuilding shell completions..."
    rm -f ~/.zcompdump
    if [[ "$CURRENT_SHELL" == "zsh" ]]; then
        autoload -Uz compinit && compinit
        echo "✅ Zsh completions rebuilt successfully!"
    elif [[ "$CURRENT_SHELL" == "bash" ]]; then
        echo "✅ Bash completions will reload on next shell session."
    else
        echo "✅ Completion cache cleared."
    fi
    echo "💡 Tip: New completions are available for any software you just installed."
}
