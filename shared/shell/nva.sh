#!/usr/bin/env sh

# nva - Launch a Neovim + AI Agent pair in a zellij tab
# Creates a split with nvim (left) and an AI agent (right),
# connected via neovim-remote through a shared socket.

nva() {
    # Must be inside zellij
    if [ -z "$ZELLIJ_SESSION_NAME" ]; then
        printf "nva: must be run inside a zellij session\n" >&2
        return 1
    fi

    # Parse arguments
    local agent=""
    local name=""

    while [ $# -gt 0 ]; do
        case "$1" in
            --claude) agent="claude" ;;
            --codex)  agent="codex" ;;
            -*)
                printf "nva: unknown option: %s\n" "$1" >&2
                printf "Usage: nva [--claude | --codex] [name]\n" >&2
                return 1
                ;;
            *)
                if [ -z "$name" ]; then
                    name="$1"
                else
                    printf "nva: unexpected argument: %s\n" "$1" >&2
                    return 1
                fi
                ;;
        esac
        shift
    done

    # Require agent flag
    if [ -z "$agent" ]; then
        printf "nva: specify --claude or --codex\n" >&2
        printf "Usage: nva [--claude | --codex] [name]\n" >&2
        return 1
    fi

    # Validate agent binary exists
    if ! command -v "$agent" >/dev/null 2>&1; then
        printf "nva: %s not found in PATH\n" "$agent" >&2
        return 1
    fi

    # Validate nvr is available
    if ! command -v nvr >/dev/null 2>&1; then
        printf "nva: nvr (neovim-remote) not found; install via 'brew install neovim-remote'\n" >&2
        return 1
    fi

    # Generate name if not provided
    if [ -z "$name" ]; then
        name=$(od -An -tx4 -N4 /dev/urandom | tr -d ' ')
    fi

    local socket="/tmp/nva-${name}.sock"

    # Clean stale socket
    if [ -e "$socket" ] && ! nvr --servername "$socket" --remote-expr 'v:true' >/dev/null 2>&1; then
        rm -f "$socket"
    fi

    # Build agent pane command based on agent type
    local agent_cmd=""
    local agent_args=""
    case "$agent" in
        claude)
            agent_cmd="claude"
            agent_args="\"--append-system-prompt\" \"You are in an NVA session. A Neovim instance is connected at NVA_SOCKET=$socket. Use the /nvr command for full nvr reference. Quick examples: nvr --servername \\\"$socket\\\" --remote <file> to open files, nvr --servername \\\"$socket\\\" -c '<ex-cmd>' to run Ex commands.\""
            ;;
        codex)
            agent_cmd="codex"
            agent_args=""
            ;;
    esac

    # Generate temporary KDL layout
    local layout_file
    layout_file=$(mktemp /tmp/nva-layout-XXXXXX.kdl)

    if [ "$agent" = "claude" ]; then
        cat > "$layout_file" <<LAYOUT_EOF
layout {
    tab name="nva:${name}" {
        pane split_direction="vertical" {
            pane command="nvim" {
                args "--listen" "${socket}"
            }
            pane command="claude" {
                args "--append-system-prompt" "You are in an NVA session. A Neovim instance is connected at NVA_SOCKET=${socket}. Use the /nvr command for full nvr reference. Quick examples: nvr --servername \"${socket}\" --remote <file> to open files, nvr --servername \"${socket}\" -c '<ex-cmd>' to run Ex commands."
            }
        }
    }
}
LAYOUT_EOF
    else
        cat > "$layout_file" <<LAYOUT_EOF
layout {
    tab name="nva:${name}" {
        pane split_direction="vertical" {
            pane command="nvim" {
                args "--listen" "${socket}"
            }
            pane command="codex" {
            }
        }
    }
}
LAYOUT_EOF
    fi

    # Launch the tab
    zellij action new-tab --layout "$layout_file" --name "nva:${name}"

    # Cleanup
    rm -f "$layout_file"
}

# nvim-listen - Launch Neovim with a predictable socket path
# Simpler alternative to nva() - just nvim with socket, no zellij orchestration
nvim-listen() {
    local socket_path

    if [[ -n "$1" ]]; then
        # User-provided name
        socket_path="/tmp/nvim-$1.sock"
    else
        # Derive from pwd (hash for uniqueness)
        local pwd_hash
        if command -v md5sum >/dev/null 2>&1; then
            pwd_hash=$(echo "$PWD" | md5sum | cut -d' ' -f1 | head -c 8)
        else
            # macOS uses md5 -q
            pwd_hash=$(echo "$PWD" | md5 -q | head -c 8)
        fi
        socket_path="/tmp/nvim-${pwd_hash}.sock"
    fi

    # Clean stale socket
    [[ -e "$socket_path" ]] && rm -f "$socket_path"

    # Export for current shell and child processes
    export NVA_SOCKET="$socket_path"

    echo "Neovim listening on: $socket_path"
    nvim --listen "$socket_path"
}
