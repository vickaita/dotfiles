export DOTFILES="$HOME/.dotfiles"

export CURRENT_SHELL="zsh"

# Enable profiling if requested
if [[ -n "$ZSH_PROFILE" ]]; then
  zmodload zsh/zprof
  source "$DOTFILES/zsh/profiling.zsh"
else
  # Define _source function for normal mode (with file existence check)
  _source() {
    local file="$1"
    if [[ -f "$file" ]]; then
      source "$file"
    else
      echo "Warning: $file not found!"
    fi
  }
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
_source "$DOTFILES/shared/shell/pyenv.sh"
_source "$DOTFILES/shared/shell/fnm.sh"
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

# Clean up - remove _source function from global scope
unset -f _source

# Show profiling results if enabled
if [[ -n "$ZSH_PROFILE" ]]; then
  _show_file_times
  echo "\n=== Function-level Profiling ==="
  zprof
fi
