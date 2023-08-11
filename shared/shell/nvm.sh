# nvm_setup.sh

# Default location for installed Node versions
export NVM_DIR="$HOME/.nvm"

# Source nvm from the Homebrew location if it exists there
if [[ -s "/usr/local/opt/nvm/nvm.sh" ]]; then
    source "/usr/local/opt/nvm/nvm.sh"

    # Load bash_completion for nvm from Homebrew path if in a Bash shell
    if [[ -s "/usr/local/opt/nvm/etc/bash_completion.d/nvm" && "$SHELL" == *"/bash"* ]]; then
        source "/usr/local/opt/nvm/etc/bash_completion.d/nvm"
    fi

    # Placeholder for zsh completions if you have them
    # if [[ -s "/path/to/zsh/completions/for/nvm" && "$SHELL" == *"/zsh"* ]]; then
    #     source "/path/to/zsh/completions/for/nvm"
    # fi

# Otherwise, attempt to load from the default location
elif [[ -s "$NVM_DIR/nvm.sh" ]]; then
    source "$NVM_DIR/nvm.sh"

    # Load bash_completion for nvm if in a Bash shell and it exists in the default location
    if [[ -s "$NVM_DIR/bash_completion" && "$SHELL" == *"/bash"* ]]; then
        source "$NVM_DIR/bash_completion"
    fi

    # Placeholder for zsh completions if you have them
    # if [[ -s "/path/to/zsh/completions/for/nvm" && "$SHELL" == *"/zsh"* ]]; then
    #     source "/path/to/zsh/completions/for/nvm"
    # fi
fi
