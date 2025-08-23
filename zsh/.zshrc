export CURRENT_SHELL="zsh"
export DOTFILES="$HOME/.dotfiles"

# Define custom function for sourcing files with an extra check to make sure the
# file exists and warn if it doesn't.
_source() {
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
    alias _source="_timing_wrapper _source"
fi

# Source shell configuration files
_source "$DOTFILES/zsh/keybindings.zsh"
_source "$DOTFILES/shared/shell/homebrew.sh"
_source "$DOTFILES/shared/shell/utils.sh"
_source "$DOTFILES/shared/shell/prompt.sh"
_source "$DOTFILES/shared/shell/history.sh"
_source "$DOTFILES/shared/shell/rust.sh"
_source "$DOTFILES/shared/shell/direnv.sh"
_source "$DOTFILES/shared/shell/fzf.sh"
_source "$DOTFILES/shared/shell/mise.sh"
_source "$DOTFILES/shared/shell/zoxide.sh"
_source "$DOTFILES/shared/shell/editor-binding.sh"
_source "$DOTFILES/shared/shell/less-pager.sh"
_source "$DOTFILES/shared/shell/claude.sh"
_source "$DOTFILES/shared/shell/aliases.sh"

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
    _source "$HOME/.zshrc.local"
fi

# Show profiling results if enabled
if [[ -n "$ZSH_PROFILE" ]]; then
    echo "\n=== Zsh File Loading Times ==="
    _show_file_times
    echo "\n=== Function-level Profiling ==="
    zprof
fi
