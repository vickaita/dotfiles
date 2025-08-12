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

# Configure Git completion
autoload -Uz compinit && compinit

# Source local configuration
if [[ -f "$HOME/.zshrc.local" ]]; then
    source "$HOME/.zshrc.local"
fi

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
