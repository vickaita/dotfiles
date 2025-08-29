# Atuin - magical shell history
# Initialize atuin for the current shell if available
if command -v atuin &>/dev/null; then
    eval "$(atuin init "$CURRENT_SHELL" --disable-up-arrow)"
fi

