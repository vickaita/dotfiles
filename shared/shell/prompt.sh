git_prompt_info() {
    # Is this a git repo?
    if ! git --no-optional-locks rev-parse --git-dir &>/dev/null; then
        return 0
    fi
    local ref
    ref=$(git --no-optional-locks symbolic-ref --short HEAD 2>/dev/null) ||
        "$(git --no-optional-locks rev-parse --short HEAD 2>/dev/null)" ||
        return 0
    echo "$ref"
}

if ! typeset -f __git_ps1 >/dev/null; then
    source "$DOTFILES"/shared/shell/git-prompt.sh
fi

GIT_PS1_SHOWDIRTYSTATE=1
GIT_PS1_STATESEPARATOR=""

if [ "$ZSH_VERSION" != "" ]; then
    precmd() {
        local ret_status="%(?:%{%f%}:%{%F{red}%})"
        __git_ps1 "%F{cyan}%~%f" " ${ret_status}%#%f " " %%B%%F{blue}[%%F{red}%s%%F{blue}]%%b%%f"
    }
fi

if [ "$BASH_VERSION" != "" ]; then
    PROMPT_COMMAND='history -a; history -c; history -r; __git_ps1 "\[\033[36m\]\w" "\[\033[0;0m\] $ " " \[\033[1;34m\][\[\033[1;31m\]%s\[\033[1;34m\]]"'
fi
