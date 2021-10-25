function git_prompt_info() {
    # Is this a git repo?
    if ! git --no-optional-locks rev-parse --git-dir &> /dev/null; then
        return 0;
    fi
    local ref
    ref=$(git --no-optional-locks symbolic-ref --short HEAD 2> /dev/null) \
        || $(git --no-optional-locks rev-parse --short HEAD 2> /dev/null) \
        || return 0;
    echo $ref
}

if ! typeset -f __git_ps1 > /dev/null; then
    source $DOTFILES/shared/git-prompt.sh
fi

GIT_PS1_SHOWDIRTYSTATE=1
GIT_PS1_STATESEPARATOR=""

if [ -n "$ZSH_VERSION" ]; then
    precmd () {
        local ret_status="%(?:%{%f%}:%{%F{red}%})"
        __git_ps1 "%F{cyan}%~%f %B%F{blue}[%F{red}" "%F{blue}]%b%f ${ret_status}%#%f " "%s"
    }
fi

if [ -n "$BASH_VERSION" ]; then
   PROMPT_COMMAND='__git_ps1 "\[\033[36m\]\w \[\033[1;34m\][\[\033[1;31m\]" "\[\033[1;34m\]]\[\033[0;0m\] $ " "%s"';
fi