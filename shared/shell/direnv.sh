# Check if direnv is installed
if command -v direnv >/dev/null; then
    # Detect the shell and set the appropriate hook
    case "$0" in
    *bash*)
        eval "$(direnv hook bash)"
        ;;
    *zsh*)
        eval "$(direnv hook zsh)"
        ;;
    # Add more cases if needed for other shells
    *)
        echo "Unknown shell for direnv setup: $0"
        ;;
    esac
fi
