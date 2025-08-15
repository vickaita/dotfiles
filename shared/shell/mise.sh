# mise - Fast, polyglot tool version manager
# Replaces pyenv, fnm, rbenv, etc. with a single fast tool
# Configuration is stored in ~/.config/mise/config.toml (versioned in dotfiles)

# Check if mise command exists
if command -v mise >/dev/null 2>&1; then
    # Initialize mise for shell integration using CURRENT_SHELL variable
    eval "$(mise activate $CURRENT_SHELL)"
fi