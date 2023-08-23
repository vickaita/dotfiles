# nvm_setup.sh

# Default location for installed Node versions
if [[ -z "$NVIM_DIR" ]]; then
    export NVM_DIR="$HOME/.nvm"
fi

# Check if nvm command exists, if it is already initialized then we don't want
# to source it again
if ! typeset -f nvm >/dev/null; then

    # Source nvm from the Homebrew location if it exists there, checking a few
    # different places that it could be installed
    # Otherwise, attempt to load from the default location
    if [[ -s "/usr/local/opt/nvm/nvm.sh" ]]; then
        source "/usr/local/opt/nvm/nvm.sh"
    elif [[ -s "/opt/homebrew/opt/nvim/nvim.sh" ]]; then
        source "/opt/homebrew/opt/nvm/nvm.sh"
    elif [[ -s "$NVM_DIR/nvm.sh" ]]; then
        source "$NVM_DIR/nvm.sh"
    fi

    # Load bash_completion for nvm from Homebrew path if in a Bash shell
    if [[ "$CURRENT_SHELL" == "bash" ]]; then
        if [[ -s "/usr/local/opt/nvm/etc/bash_completion.d/nvm" ]]; then
            source "/usr/local/opt/nvm/etc/bash_completion.d/nvm"
        elif [[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ]]; then
            source "/usr/local/opt/nvm/etc/bash_completion.d/nvm"
        fi
    fi

    # # Placeholder for zsh completions if you have them
    # if [[ "$CURRENT_SHELL" == "zsh" ]]; then
    #     if [[ -s "/path/to/zsh/completions/for/nvm" ]]; then
    #         source "/path/to/zsh/completions/for/nvm"
    #     fi
    # fi
fi
