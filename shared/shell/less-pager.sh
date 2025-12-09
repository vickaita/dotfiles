# Configure less as the default pager with color support
export PAGER="less -R"

# Helper function to safely eval lesspipe commands with timeout protection
_eval_lesspipe_safe() {
    local cmd="$1"
    if command -v timeout >/dev/null 2>&1; then
        eval "$(timeout 3 env SHELL=/bin/sh "$cmd" 2>&1)" || echo "Warning: lesspipe timed out or failed" >&2
    else
        eval "$(SHELL=/bin/sh "$cmd")"
    fi
}

# make less more friendly for non-text input files, see lesspipe(1)
# Check for lesspipe.sh installed by Homebrew on Apple Silicon Macs
if [ -x /opt/homebrew/bin/lesspipe.sh ]; then
    _eval_lesspipe_safe /opt/homebrew/bin/lesspipe.sh
# Check for lesspipe.sh installed by Homebrew on Intel Macs
elif [ -x /usr/local/bin/lesspipe.sh ]; then
    _eval_lesspipe_safe /usr/local/bin/lesspipe.sh
# Check if 'lesspipe' is available as a command in PATH (most common on Linux)
elif command -v lesspipe >/dev/null 2>&1; then
    _eval_lesspipe_safe lesspipe
# Check for lesspipe.sh in the standard Linux location
elif [ -x /usr/bin/lesspipe.sh ]; then
    _eval_lesspipe_safe /usr/bin/lesspipe.sh
fi
