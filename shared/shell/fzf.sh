# Check and source the appropriate fzf configuration
case "$CURRENT_SHELL" in
*bash*)
    [ -f "$HOME"/.fzf.bash ] && source "$HOME"/.fzf.bash
    ;;
*zsh*)
    [ -f "$HOME"/.fzf.zsh ] && source "$HOME"/.fzf.zsh
    ;;
# Add more cases if needed for other shells
*)
    echo "Unknown shell for fzf setup: $CURRENT_SHELL"
    ;;
esac
