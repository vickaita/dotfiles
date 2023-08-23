# only source cargo env if it exists
if [[ -f "$HOME/.cargo/env" ]]; then
    source "$HOME/.cargo/env"
    prepend_to_path "$HOME/.cargo/bin"
fi
