export DOTFILES="$HOME"/.dotfiles

export CURRENT_SHELL="zsh"

source "$DOTFILES"/shared/shell/prompt.sh
source "$DOTFILES"/shared/shell/history.sh
source "$DOTFILES"/shared/shell/rust.sh
source "$DOTFILES"/shared/shell/direnv.sh
source "$DOTFILES"/shared/shell/fzf.sh
source "$DOTFILES"/shared/shell/pyenv.sh
source "$DOTFILES"/shared/shell/nvm.sh
source "$DOTFILES"/shared/shell/github-copilot.sh
source "$DOTFILES"/shared/shell/editor-binding.sh
source "$DOTFILES"/shared/shell/init_lesspipe.sh

plugins=(docker docker-compose)

# Configure Git completion
autoload -Uz compinit && compinit

# added by Nix installer
if [ -e /home/vickaita/.nix-profile/etc/profile.d/nix.sh ]; then
    source /home/vickaita/.nix-profile/etc/profile.d/nix.sh;
fi

# Source local configuration
if [[ -f ~/.zshrc.local ]]; then
    source ~/.zshrc.local
fi

