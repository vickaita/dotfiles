if command -v fzf >/dev/null 2>&1; then
    # Catppuccin Mocha theme for fzf using environment variables
    export FZF_DEFAULT_OPTS=" \
    --color=bg+:${CATPPUCCIN_SURFACE0},bg:${CATPPUCCIN_BASE},spinner:${CATPPUCCIN_ROSEWATER},hl:${CATPPUCCIN_RED} \
    --color=fg:${CATPPUCCIN_TEXT},header:${CATPPUCCIN_RED},info:${CATPPUCCIN_MAUVE},pointer:${CATPPUCCIN_ROSEWATER} \
    --color=marker:${CATPPUCCIN_LAVENDER},fg+:${CATPPUCCIN_TEXT},prompt:${CATPPUCCIN_MAUVE},hl+:${CATPPUCCIN_RED} \
    --color=selected-bg:${CATPPUCCIN_SURFACE1} \
    --color=border:${CATPPUCCIN_OVERLAY0},label:${CATPPUCCIN_TEXT}"

    # Check for fzf availability and configure it appropriately for the shell
    case "$CURRENT_SHELL" in
    *bash*)
        eval "$(fzf --bash)"
        ;;
    *zsh*)
        eval "$(fzf --zsh)"
        ;;
    # Add more cases if needed for other shells
    *)
        echo "Unknown or unsupported shell for fzf setup: $CURRENT_SHELL"
        ;;
    esac
else
    echo "fzf is not installed. Please install fzf for bash integration."
fi
