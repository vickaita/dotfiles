EDITOR=nvim

if [[ $CURRENT_SHELL == "zsh" ]]; then
    autoload -Uz edit-command-line
    zle -N edit-command-line
    bindkey '^X^E' edit-command-line
fi
