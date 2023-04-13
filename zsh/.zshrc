DOTFILES=$HOME/.dotfiles

source $DOTFILES/shared/shell/prompt.sh
source $DOTFILES/shared/shell/history.sh
source $DOTFILES/shared/shell/path.sh
source $DOTFILES/shared/shell/github-copilot.sh

# Configure FZF integration
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Configure Git completion
autoload -Uz compinit && compinit


# added by Nix installer
if [ -e /home/vickaita/.nix-profile/etc/profile.d/nix.sh ]; then
    source /home/vickaita/.nix-profile/etc/profile.d/nix.sh;
fi
