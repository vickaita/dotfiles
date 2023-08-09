# Check and source the appropriate fzf configuration
case "$0" in
*bash*)
    [ -f "$HOME"/.fzf.bash ] && source "$HOME"/.fzf.bash
    ;;
*zsh*)
    [ -f "$HOME"/.fzf.zsh ] && source "$HOME"~/.fzf.zsh
    ;;
*)
    echo "Unknown shell for fzf setup"
    ;;
esac
