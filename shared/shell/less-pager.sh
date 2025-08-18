# Configure less as the default pager with color support
export PAGER="less -R"

# make less more friendly for non-text input files, see lesspipe(1)
# Check for lesspipe.sh installed by Homebrew on Apple Silicon Macs
if [ -x /opt/homebrew/bin/lesspipe.sh ]; then
    eval "$(SHELL=/bin/sh /opt/homebrew/bin/lesspipe.sh)"
# Check for lesspipe.sh installed by Homebrew on Intel Macs
elif [ -x /usr/local/bin/lesspipe.sh ]; then
    eval "$(SHELL=/bin/sh /usr/local/bin/lesspipe.sh)"
# Check if 'lesspipe' is available as a command in PATH (most common on Linux)
elif command -v lesspipe >/dev/null 2>&1; then
    eval "$(SHELL=/bin/sh lesspipe)"
# Check for lesspipe.sh in the standard Linux location
elif [ -x /usr/bin/lesspipe.sh ]; then
    eval "$(SHELL=/bin/sh /usr/bin/lesspipe.sh)"
fi
