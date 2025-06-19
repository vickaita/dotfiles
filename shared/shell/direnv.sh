# direnv.sh - Load direnv shell hook for supported shells.
#
# What is direnv?
#   direnv is a shell extension that automatically loads and unloads environment variables
#   based on the presence of a .envrc file in your directory. It is useful for managing
#   project-specific environment variables, secrets, and tool versions without polluting
#   your global shell environment.
#
# Usage: Set $CURRENT_SHELL to your current shell (e.g., "zsh" or "bash") before sourcing.
# Intended to be sourced from .zshrc or .bashrc.
# WARNING: Uses eval on output from direnv. Only use trusted direnv binaries.

# Check if direnv is installed
if command -v direnv >/dev/null; then
    # Detect the shell and set the appropriate hook
    case "$CURRENT_SHELL" in
    bash)
        eval "$(direnv hook bash)"
        ;;
    zsh)
        eval "$(direnv hook zsh)"
        ;;
    # Add more cases if needed for other shells
    *)
        echo "Unknown shell for direnv setup: $CURRENT_SHELL"
        ;;
    esac
fi
