export DOTFILES="$HOME/.dotfiles"

export CURRENT_SHELL="zsh"

source "$DOTFILES"/zsh/keybindings.zsh

source "$DOTFILES"/shared/shell/homebrew.sh
source "$DOTFILES"/shared/shell/utils.sh
source "$DOTFILES"/shared/shell/prompt.sh
source "$DOTFILES"/shared/shell/history.sh
source "$DOTFILES"/shared/shell/rust.sh
source "$DOTFILES"/shared/shell/direnv.sh
source "$DOTFILES"/shared/shell/fzf.sh
source "$DOTFILES"/shared/shell/pyenv.sh
source "$DOTFILES"/shared/shell/nvm.sh
source "$DOTFILES"/shared/shell/editor-binding.sh
source "$DOTFILES"/shared/shell/init_lesspipe.sh
source "$DOTFILES"/shared/shell/claude.sh

# Warn if any important sourced files are missing
for file in \
    "$DOTFILES/shared/shell/homebrew.sh" \
    "$DOTFILES/shared/shell/utils.sh" \
    "$DOTFILES/shared/shell/prompt.sh" \
    "$DOTFILES/shared/shell/history.sh" \
    "$DOTFILES/shared/shell/rust.sh" \
    "$DOTFILES/shared/shell/direnv.sh" \
    "$DOTFILES/shared/shell/fzf.sh" \
    "$DOTFILES/shared/shell/pyenv.sh" \
    "$DOTFILES/shared/shell/nvm.sh" \
    "$DOTFILES/shared/shell/editor-binding.sh" \
    "$DOTFILES/shared/shell/init_lesspipe.sh" \
    "$DOTFILES/shared/shell/claude.sh" \
    "$DOTFILES/zsh/keybindings.zsh"; do
    if [ ! -f "$file" ]; then
        echo "Warning: $file not found!"
    fi
done

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
    source "$HOME/.zshrc.local"
fi
