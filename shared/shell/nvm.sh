# nvm_setup.sh with lazy loading

# Default location for installed Node versions
if [[ -z "$NVM_DIR" ]]; then
    export NVM_DIR="$HOME/.nvm"
fi

# Lazy load NVM to improve shell startup time
_nvm_lazy_load() {
    unset -f nvm node npm npx

    # Source nvm from the Homebrew location if it exists there, checking a few
    # different places that it could be installed
    # Otherwise, attempt to load from the default location
    if [[ -s "/usr/local/opt/nvm/nvm.sh" ]]; then
        source "/usr/local/opt/nvm/nvm.sh"
    elif [[ -s "/opt/homebrew/opt/nvm/nvm.sh" ]]; then
        source "/opt/homebrew/opt/nvm/nvm.sh"
    elif [[ -s "$NVM_DIR/nvm.sh" ]]; then
        source "$NVM_DIR/nvm.sh"
    fi

    # Load completion for nvm from Homebrew path if in a Bash shell
    if [[ "$CURRENT_SHELL" == "bash" ]]; then
        NVM_COMPLETION=""
        if [[ -s "/usr/local/opt/nvm/etc/bash_completion.d/nvm" ]]; then
            NVM_COMPLETION="/usr/local/opt/nvm/etc/bash_completion.d/nvm"
        elif [[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ]]; then
            NVM_COMPLETION="/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"
        elif [[ -s "$NVM_DIR/bash_completion" ]]; then
            NVM_COMPLETION="$NVM_DIR/bash_completion"
        fi
        if [[ -n "$NVM_COMPLETION" ]]; then
            if ! source "$NVM_COMPLETION" 2>/dev/null; then
                echo "[nvm] Warning: Failed to load nvm completions from $NVM_COMPLETION" >&2
            fi
        fi
    fi

    # Source zsh-nvm plugin for zsh completions if available
    if [[ "$CURRENT_SHELL" == "zsh" ]] && [[ -s "$HOME/.zsh-nvm/zsh-nvm.plugin.zsh" ]]; then
        source "$HOME/.zsh-nvm/zsh-nvm.plugin.zsh"
    fi
}

# Check if nvm is already loaded to avoid duplicate loading
if ! typeset -f nvm >/dev/null; then
    # Create placeholder functions that will trigger lazy loading
    nvm() {
        _nvm_lazy_load
        nvm "$@"
    }

    node() {
        _nvm_lazy_load
        node "$@"
    }

    npm() {
        _nvm_lazy_load
        npm "$@"
    }

    npx() {
        _nvm_lazy_load
        npx "$@"
    }
fi
