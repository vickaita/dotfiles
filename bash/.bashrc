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

# Source optional files without warnings
optional_source() {
    [[ -f "$1" ]] && source "$1"
}

# Source files with automatic disable flag checking
# Derives flag name from filename: less-pager.sh -> DOTFILES_DISABLE_LESS_PAGER
conditional_source() {
    local file="$1"
    local basename="${file##*/}"          # Extract filename
    local module="${basename%.*}"         # Remove extension
    local module_upper="${module^^}"      # Uppercase (bash 4+)
    local flag_name="DOTFILES_DISABLE_${module_upper//-/_}"  # Replace - with _
    [[ -z "${!flag_name}" ]] && safe_source "$file"
}

# Enable profiling if requested
if [[ -n "$BASH_PROFILE" ]]; then
    source "$DOTFILES/bash/profiling.sh"
    # Create wrapper aliases for timing
    alias safe_source='timing_wrapper safe_source'
    alias optional_source='timing_wrapper optional_source'
    alias conditional_source='timing_wrapper conditional_source'
fi

# Use this file to set any environment variables for disabling any of the
# conditional_source modules
optional_source "$HOME/.bashrc.local.pre"

# Source shell configuration files
conditional_source "$DOTFILES/shared/shell/homebrew.sh"
conditional_source "$DOTFILES/shared/shell/catppuccin-colors.sh"
conditional_source "$DOTFILES/shared/shell/utils.sh"
conditional_source "$DOTFILES/shared/shell/prompt.sh"
conditional_source "$DOTFILES/shared/shell/history.sh"
conditional_source "$DOTFILES/shared/shell/rust.sh"
conditional_source "$DOTFILES/shared/shell/direnv.sh"
conditional_source "$DOTFILES/shared/shell/fzf.sh"
conditional_source "$DOTFILES/shared/shell/mise.sh"
conditional_source "$DOTFILES/shared/shell/zoxide.sh"
conditional_source "$DOTFILES/shared/shell/editor-binding.sh"
conditional_source "$DOTFILES/shared/shell/less-pager.sh"
conditional_source "$DOTFILES/shared/shell/claude.sh"
conditional_source "$DOTFILES/shared/shell/atuin.sh"
conditional_source "$DOTFILES/shared/shell/aliases.sh"
conditional_source "$DOTFILES/shared/shell/gh-copilot.sh"

# Add custom bin directory to PATH
prepend_to_path "$DOTFILES/bin"

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

# Note: Prompt is configured by shared/shell/prompt.sh

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
optional_source ~/.bashrc.local

# Show profiling results if enabled
if [[ -n "$BASH_PROFILE" ]]; then
    echo ""
    echo "=== Bash File Loading Times ==="
    _show_file_times
fi
