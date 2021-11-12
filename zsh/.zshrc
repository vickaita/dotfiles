DOTFILES=$HOME/.dotfiles

source $DOTFILES/shared/prompt.sh
source $DOTFILES/shared/history.sh
source $DOTFILES/shared/path.sh

# Configure FZF integration
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Configure Git completion
autoload -Uz compinit && compinit


# added by Nix installer
if [ -e /home/vickaita/.nix-profile/etc/profile.d/nix.sh ]; then
    source /home/vickaita/.nix-profile/etc/profile.d/nix.sh;
fi
