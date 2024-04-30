# Check for fzf availability and configure it appropriately for the shell
case "$CURRENT_SHELL" in
*bash*)
	if command -v fzf >/dev/null 2>&1; then
		eval "$(fzf --bash)"
	else
		echo "fzf is not installed. Please install fzf for bash integration."
	fi
	;;
*zsh*)
	if command -v fzf >/dev/null 2>&1; then
		eval "$(fzf --zsh)"
	else
		echo "fzf is not installed. Please install fzf for zsh integration."
	fi
	;;
# Add more cases if needed for other shells
*)
	echo "Unknown or unsupported shell for fzf setup: $CURRENT_SHELL"
	;;
esac
