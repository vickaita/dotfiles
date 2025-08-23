# Initialize zoxide for smart directory jumping
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init "$CURRENT_SHELL")"
fi

