#!/usr/bin/env bash

set -euo pipefail

dotfiles_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

prompt_for() {
    local shell_name=$1
    local connection=${2-}
    local command
    local -a shell_args

    if [[ $shell_name == bash ]]; then
        command='DOTFILES=$1; cd /private/tmp; source "$DOTFILES/shared/shell/prompt.sh"; __prompt_command; printf %s "$PS1"'
        shell_args=(--noprofile --norc)
    else
        command='DOTFILES=$1; cd /private/tmp; source "$DOTFILES/shared/shell/prompt.sh"; precmd; print -rn -- "$PROMPT"'
        shell_args=(-f)
    fi

    if [[ -n $connection ]]; then
        SSH_CONNECTION=$connection "$shell_name" "${shell_args[@]}" -c "$command" _ "$dotfiles_root"
    else
        env -u SSH_CONNECTION "$shell_name" "${shell_args[@]}" -c "$command" _ "$dotfiles_root"
    fi
}

assert_contains() {
    local actual=$1
    local expected=$2
    local description=$3

    if [[ $actual != *"$expected"* ]]; then
        printf 'FAIL: %s\nExpected prompt to contain: %s\nActual prompt: %s\n' \
            "$description" "$expected" "$actual" >&2
        return 1
    fi
}

assert_not_contains() {
    local actual=$1
    local unexpected=$2
    local description=$3

    if [[ $actual == *"$unexpected"* ]]; then
        printf 'FAIL: %s\nExpected prompt not to contain: %s\nActual prompt: %s\n' \
            "$description" "$unexpected" "$actual" >&2
        return 1
    fi
}

ssh_connection='192.0.2.10 54321 192.0.2.20 22'

bash_local=$(prompt_for bash)
bash_remote=$(prompt_for bash "$ssh_connection")
zsh_local=$(prompt_for zsh)
zsh_remote=$(prompt_for zsh "$ssh_connection")

assert_not_contains "$bash_local" '\u@\h' 'Bash local prompt omits user and hostname'
assert_contains "$bash_remote" '\u@\h' 'Bash SSH prompt includes user and hostname'
assert_not_contains "$zsh_local" '%n@%m' 'Zsh local prompt omits user and hostname'
assert_contains "$zsh_remote" '%n@%m' 'Zsh SSH prompt includes user and hostname'

printf 'PASS: shared prompt distinguishes local and SSH sessions in Bash and Zsh\n'
