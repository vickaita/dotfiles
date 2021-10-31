DOTFILES=$HOME/.dotfiles

source $DOTFILES/shared/prompt.sh
source $DOTFILES/shared/history.sh

# Configure FZF integration
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Configure Git completion
autoload -Uz compinit && compinit

# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
export PATH="$PATH:$HOME/.rvm/bin"

# added by Nix installer
if [ -e /home/vickaita/.nix-profile/etc/profile.d/nix.sh ]; then
    source /home/vickaita/.nix-profile/etc/profile.d/nix.sh;
fi
