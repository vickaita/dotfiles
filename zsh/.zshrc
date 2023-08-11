DOTFILES="$HOME"/.dotfiles

source "$DOTFILES"/shared/shell/prompt.sh
source "$DOTFILES"/shared/shell/history.sh
source "$DOTFILES"/shared/shell/path.sh
source "$DOTFILES"/shared/shell/github-copilot.sh
source "$DOTFILES"/shared/shell/rust.sh
source "$DOTFILES"/shared/shell/direnv.sh
source "$DOTFILES"/shared/shell/fzf.sh
source "$DOTFILES"/shared/shell/pyenv.sh
source "$DOTFILES"/shared/shell/nvm.sh

# Configure Git completion
autoload -Uz compinit && compinit

# added by Nix installer
if [ -e /home/vickaita/.nix-profile/etc/profile.d/nix.sh ]; then
    source /home/vickaita/.nix-profile/etc/profile.d/nix.sh;
fi
