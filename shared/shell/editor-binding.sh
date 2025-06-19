# Set default editor to Neovim if available, otherwise fall back to Vim, then Vi
if command -v nvim >/dev/null 2>&1; then
    export EDITOR=nvim
elif command -v vim >/dev/null 2>&1; then
    export EDITOR=vim
else
    export EDITOR=vi
fi
export VISUAL="$EDITOR"

if [[ $CURRENT_SHELL == "zsh" ]]; then
    autoload -Uz edit-command-line
    zle -N edit-command-line
    bindkey '^X^E' edit-command-line
fi
