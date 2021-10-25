DOTFILES=$HOME/.dotfiles

source $DOTFILES/shared/prompt.sh

# Configure FZF integration
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Configure Git completion
autoload -Uz compinit && compinit

# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
export PATH="$PATH:$HOME/.rvm/bin"
