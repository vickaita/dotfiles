# Use emacs-style keymap (default for zsh unless overridden)
bindkey -e

# Core cursor movement and editing
bindkey '^A' beginning-of-line
bindkey '^E' end-of-line
bindkey '^B' backward-char
bindkey '^F' forward-char
bindkey '^P' up-line-or-history
bindkey '^N' down-line-or-history
bindkey '^H' backward-delete-char
bindkey '^D' delete-char
bindkey '^K' kill-line
bindkey '^U' kill-whole-line
bindkey '^W' backward-kill-word
bindkey '^Y' yank
bindkey '^R' history-incremental-search-backward
bindkey '^S' history-incremental-search-forward  # NOTE: may be blocked by terminal flow control

# Accepting/clearing
bindkey '^M' accept-line     # Enter
bindkey '^J' accept-line     # Ctrl-J also acts as Enter
bindkey '^L' clear-screen

# Terminal recovery function for frozen nvim sessions (especially in Zellij)
# Press Ctrl-X Ctrl-R to reset terminal state
reset-terminal() {
    tput reset 2>/dev/null || true
    zle reset-prompt
}
zle -N reset-terminal
bindkey '^X^R' reset-terminal
