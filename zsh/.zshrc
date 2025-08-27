export CURRENT_SHELL="zsh"
export DOTFILES="$HOME/.dotfiles"

# Define custom function for sourcing files with an extra check to make sure
# the file exists and warn if it doesn't.
safe_source() {
    local file="$1"
    if [[ -f "$file" ]]; then
        source "$file"
    else
        echo "Warning: $file not found!"
    fi
}

# Enable profiling if requested
if [[ -n "$ZSH_PROFILE" ]]; then
    zmodload zsh/zprof
    source "$DOTFILES/zsh/profiling.zsh"
    alias safe_source="timing_wrapper safe_source"
fi

# Source shell configuration files
safe_source "$DOTFILES/zsh/keybindings.zsh"
safe_source "$DOTFILES/shared/shell/homebrew.sh"
safe_source "$DOTFILES/shared/shell/catppuccin-colors.sh"
safe_source "$DOTFILES/shared/shell/utils.sh"
safe_source "$DOTFILES/shared/shell/prompt.sh"
safe_source "$DOTFILES/shared/shell/history.sh"
safe_source "$DOTFILES/shared/shell/rust.sh"
safe_source "$DOTFILES/shared/shell/direnv.sh"
safe_source "$DOTFILES/shared/shell/fzf.sh"
safe_source "$DOTFILES/shared/shell/mise.sh"
safe_source "$DOTFILES/shared/shell/zoxide.sh"
safe_source "$DOTFILES/shared/shell/editor-binding.sh"
safe_source "$DOTFILES/shared/shell/less-pager.sh"
safe_source "$DOTFILES/shared/shell/claude.sh"
safe_source "$DOTFILES/shared/shell/atuin.sh"
safe_source "$DOTFILES/shared/shell/aliases.sh"
safe_source "$DOTFILES/shared/shell/gh-copilot.sh"

# Configure completion system with smart daily caching
# IMPORTANT: This must run AFTER all shell scripts that modify fpath
autoload -Uz compinit

# Rebuild completions only if dump file doesn't exist or is older than 24 hours
if [[ ! -f ~/.zcompdump ]] || [[ -n $(find ~/.zcompdump -mtime +1 -print 2>/dev/null) ]]; then
    compinit
else
    compinit -C
fi

# Source local configuration
if [[ -f "$HOME/.zshrc.local" ]]; then
    safe_source "$HOME/.zshrc.local"
fi

# Show profiling results if enabled
if [[ -n "$ZSH_PROFILE" ]]; then
    echo "\n=== Zsh File Loading Times ==="
    _show_file_times
    echo "\n=== Function-level Profiling ==="
    zprof
fi
