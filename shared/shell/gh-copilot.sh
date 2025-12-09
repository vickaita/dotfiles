#!/usr/bin/env sh

# GitHub Copilot CLI integration
# Provides convenient aliases for command suggestions and explanations

if ! command -v copilot >/dev/null 2>&1; then
    printf "GitHub Copilot CLI not found; install via 'brew install copilot-cli'.\n" >&2
    return
fi

# ghcs - "GitHub Copilot Suggest"
# Suggests shell commands based on natural language description
# Usage: ghcs list all files modified in the last week
ghcs() {
    if [ $# -eq 0 ]; then
        printf "Usage: ghcs <description of what you want to do>\n" >&2
        printf "Example: ghcs find all large files in current directory\n" >&2
        return 1
    fi

    copilot -p "Suggest a shell command to: $*"
}

# ghce - "GitHub Copilot Explain"
# Explains what a shell command does
# Usage: ghce tar -xzf archive.tar.gz
ghce() {
    if [ $# -eq 0 ]; then
        printf "Usage: ghce <command to explain>\n" >&2
        printf "Example: ghce tar -xzf archive.tar.gz\n" >&2
        return 1
    fi

    copilot -p "Explain this shell command: $*"
}
