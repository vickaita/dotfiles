# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
*i*) ;;
*) return ;;
esac

export DOTFILES="$HOME"/.dotfiles

export CURRENT_SHELL="bash"

safe_source() {
    local file="$1"
    if [[ -f "$file" ]]; then
        source "$file"
    else
        echo "Warning: $file not found!"
    fi
}

safe_source "$DOTFILES/shared/shell/homebrew.sh"
safe_source "$DOTFILES/shared/shell/catppuccin-colors.sh"
safe_source "$DOTFILES/shared/shell/utils.sh"
safe_source "$DOTFILES/shared/shell/prompt.sh"
safe_source "$DOTFILES/shared/shell/history.sh"
safe_source "$DOTFILES/shared/shell/rust.sh"
safe_source "$DOTFILES/shared/shell/direnv.sh"
safe_source "$DOTFILES/shared/shell/fzf.sh"
safe_source "$DOTFILES/shared/shell/mise.sh"
safe_source "$DOTFILES/shared/shell/zoxide.sh"
safe_source "$DOTFILES/shared/shell/editor-binding.sh"
safe_source "$DOTFILES/shared/shell/less-pager.sh"
safe_source "$DOTFILES/shared/shell/claude.sh"
safe_source "$DOTFILES/shared/shell/atuin.sh"
safe_source "$DOTFILES/shared/shell/aliases.sh"
safe_source "$DOTFILES/shared/shell/gh-copilot.sh"

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# set variable identifying the chroot you work in (used in the prompt below)
if [ "${debian_chroot:-}" = "" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

COLOR_RED="\033[0;31m"
COLOR_YELLOW="\033[0;33m"
COLOR_GREEN="\033[0;32m"
COLOR_OCHRE="\033[38;5;95m"
COLOR_BLUE="\033[0;34m"
COLOR_WHITE="\033[0;37m"
COLOR_RESET="\033[0m"

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
xterm-color | *-256color) color_prompt=yes ;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ "$force_color_prompt" != "" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
        # We have color support; assume it's compliant with Ecma-48
        # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
        # a case would tend to support setf rather than setaf.)
        color_prompt=yes
    else
        color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm* | rxvt*)
    # PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*) ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    safe_source ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        safe_source /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        safe_source /etc/bash_completion
    fi
fi

# Source local configuration
if [[ -f ~/.bashrc.local ]]; then
    safe_source ~/.bashrc.local
fi
