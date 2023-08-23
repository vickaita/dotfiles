# Check if pyenv command exists
if command -v pyenv >/dev/null 2>&1; then
    # PYENV_ROOT might be defined if you've installed pyenv using other methods
    # or have it placed somewhere else. You can remove the if block if you're sure.
    if [[ "$PYENV_ROOT" = "" ]]; then
        export PYENV_ROOT="$HOME/.pyenv"
    fi

    prepend_to_path "$PYENV_ROOT/bin"

    # Initialize pyenv. The `--path` option is recommended since pyenv v2.0.0
    # However, older versions might not recognize it, so we conditionally apply it.
    if pyenv init --help 2>&1 | grep -q -- '--path'; then
        eval "$(pyenv init --path)"
    else
        eval "$(pyenv init -)"
    fi
fi
