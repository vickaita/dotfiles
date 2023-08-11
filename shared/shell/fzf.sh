# Check and source the appropriate fzf configuration
case "$0" in
*bash*)
    echo "confiugring fzf for bash"
    [ -f "$HOME"/.fzf.bash ] && source "$HOME"/.fzf.bash
    ;;
*zsh*)
    echo "confiugring fzf for zsh"
    [ -f "$HOME"/.fzf.zsh ] && source "$HOME"/.fzf.zsh
    ;;
*)
    echo "Unknown shell for fzf setup: $0"
    ;;
esac
