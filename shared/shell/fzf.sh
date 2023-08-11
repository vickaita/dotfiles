# Check and source the appropriate fzf configuration
case "$SHELL" in
*bash*)
    [ -f "$HOME"/.fzf.bash ] && source "$HOME"/.fzf.bash
    ;;
*zsh*)
    [ -f "$HOME"/.fzf.zsh ] && source "$HOME"/.fzf.zsh
    ;;
*)
    echo "Unknown shell for fzf setup: $SHELL"
    ;;
esac
