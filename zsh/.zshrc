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

# Source optional files without warnings
optional_source() {
    [[ -f "$1" ]] && source "$1"
}

# Source files with automatic disable flag checking
# Derives flag name from filename: less-pager.sh -> DOTFILES_DISABLE_LESS_PAGER
conditional_source() {
    local file="$1"
    local basename="${file##*/}"          # Extract filename
    local module="${basename%.*}"         # Remove extension
    local flag_name="DOTFILES_DISABLE_${module:u:gs/-/_}"  # Uppercase, replace - with _
    [[ -z "${(P)flag_name}" ]] && safe_source "$file"
}

# Enable profiling if requested
if [[ -n "$ZSH_PROFILE" ]]; then
    zmodload zsh/zprof
    source "$DOTFILES/zsh/profiling.zsh"
    alias safe_source="timing_wrapper safe_source"
    alias optional_source="timing_wrapper optional_source"
    alias conditional_source="timing_wrapper conditional_source"
fi

# Use this file to set any environment variables for disabling any of the
# conditional_source modules
optional_source "$HOME/.zshrc.local.pre"

# Source shell configuration files
conditional_source "$DOTFILES/zsh/keybindings.zsh"
conditional_source "$DOTFILES/shared/shell/homebrew.sh"
conditional_source "$DOTFILES/shared/shell/catppuccin-colors.sh"
conditional_source "$DOTFILES/shared/shell/utils.sh"
conditional_source "$DOTFILES/shared/shell/prompt.sh"
conditional_source "$DOTFILES/shared/shell/history.sh"
conditional_source "$DOTFILES/shared/shell/rust.sh"
conditional_source "$DOTFILES/shared/shell/direnv.sh"
conditional_source "$DOTFILES/shared/shell/fzf.sh"
conditional_source "$DOTFILES/shared/shell/mise.sh"
conditional_source "$DOTFILES/shared/shell/zoxide.sh"
conditional_source "$DOTFILES/shared/shell/editor-binding.sh"
conditional_source "$DOTFILES/shared/shell/less-pager.sh"
conditional_source "$DOTFILES/shared/shell/claude.sh"
conditional_source "$DOTFILES/shared/shell/atuin.sh"
conditional_source "$DOTFILES/shared/shell/aliases.sh"
conditional_source "$DOTFILES/shared/shell/gh-copilot.sh"

# Add custom bin directory to PATH
prepend_to_path "$DOTFILES/bin"

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
optional_source "$HOME/.zshrc.local"

# Show profiling results if enabled
if [[ -n "$ZSH_PROFILE" ]]; then
    echo "\n=== Zsh File Loading Times ==="
    _show_file_times
    echo "\n=== Function-level Profiling ==="
    zprof
fi
