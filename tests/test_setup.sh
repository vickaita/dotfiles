#!/usr/bin/env bash

set -euo pipefail

DOTFILES_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    exit 1
}

assert_contains() {
    local haystack="$1"
    local needle="$2"

    [[ "$haystack" == *"$needle"* ]] || fail "expected output to contain: $needle"
}

assert_not_contains() {
    local haystack="$1"
    local needle="$2"

    [[ "$haystack" != *"$needle"* ]] || fail "expected output not to contain: $needle"
}

assert_command_fails_with() {
    local expected="$1"
    shift
    local output

    if output="$("$@" 2>&1)"; then
        fail "expected command to fail: $*"
    fi
    assert_contains "$output" "$expected"
}

test_server_dry_run_is_read_only() {
    local test_home
    local output
    local hooks_before
    local hooks_after
    test_home="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-setup-home.XXXXXX")"
    hooks_before="$(git -C "$DOTFILES_ROOT" config --local --get core.hooksPath 2>/dev/null || true)"

    output="$(HOME="$test_home" "$DOTFILES_ROOT/setup.sh" --server --dry-run 2>&1)" || {
        printf '%s\n' "$output" >&2
        fail "server dry-run should succeed"
    }

    assert_contains "$output" "Profile: server"
    assert_contains "$output" "Brewfile"
    assert_contains "$output" "SSH setup is disabled"
    assert_not_contains "$output" "Brewfile.workstation"
    assert_not_contains "$output" "ghostty"
    assert_not_contains "$output" "cmux"
    assert_not_contains "$output" "zsh"

    [[ -z "$(find "$test_home" -mindepth 1 -print -quit)" ]] || fail "dry-run modified HOME"
    hooks_after="$(git -C "$DOTFILES_ROOT" config --local --get core.hooksPath 2>/dev/null || true)"
    [[ "$hooks_after" = "$hooks_before" ]] || fail "dry-run modified repository Git configuration"
}

test_dry_run_reports_opt_in_ssh_without_touching_home() {
    local test_home
    local output
    test_home="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-ssh-preview.XXXXXX")"

    output="$(HOME="$test_home" "$DOTFILES_ROOT/setup.sh" --server --setup-ssh --dry-run 2>&1)"
    assert_contains "$output" "Would run SSH key setup"
    [[ -z "$(find "$test_home" -mindepth 1 -print -quit)" ]] || fail "SSH dry-run modified HOME"
}

test_setup_can_be_sourced_without_running_main() {
    local output

    output="$(DOTFILES_TEST_ROOT="$DOTFILES_ROOT" bash -c '
        source "$DOTFILES_TEST_ROOT/setup.sh" --dry-run
        printf sourced
    ')"
    [[ "$output" = "sourced" ]] || fail "sourcing setup.sh executed main"
}

test_dry_run_previews_managed_bash_files() {
    local test_home
    local output
    test_home="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-bash-preview.XXXXXX")"

    output="$(HOME="$test_home" "$DOTFILES_ROOT/setup.sh" --server --dry-run 2>&1)"
    assert_contains "$output" "Would add a managed dotfiles include to $test_home/.bashrc"
    assert_contains "$output" "Would add a managed dotfiles include to $test_home/.inputrc"

    output="$(HOME="$test_home" "$DOTFILES_ROOT/setup.sh" --server --skip-module bash --dry-run 2>&1)"
    assert_not_contains "$output" "Would add a managed dotfiles include"
}

test_conflicting_profiles_are_rejected() {
    assert_command_fails_with \
        "Conflicting profiles" \
        "$DOTFILES_ROOT/setup.sh" --server --profile workstation --dry-run
}

test_unknown_modules_are_rejected() {
    assert_command_fails_with \
        "Unknown module" \
        "$DOTFILES_ROOT/setup.sh" --server --skip-module not-a-module --dry-run
}

test_packages_do_not_upgrade_by_default() {
    local test_home
    local output
    test_home="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-package-preview.XXXXXX")"

    output="$(HOME="$test_home" "$DOTFILES_ROOT/setup.sh" --server --dry-run 2>&1)"
    assert_contains "$output" "brew bundle install --no-upgrade --file=$DOTFILES_ROOT/Brewfile"
}

test_dry_run_honors_package_flags() {
    local test_home
    local output
    test_home="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-package-flags.XXXXXX")"

    output="$(HOME="$test_home" "$DOTFILES_ROOT/setup.sh" --server --skip-packages --dry-run 2>&1)"
    assert_contains "$output" "Package installation is disabled"
    assert_not_contains "$output" "brew bundle install"

    output="$(HOME="$test_home" "$DOTFILES_ROOT/setup.sh" --server --update-brew --dry-run 2>&1)"
    assert_contains "$output" "Dry-run command: brew update"
    assert_contains "$output" "brew bundle install --no-upgrade"
    assert_not_contains "$output" "brew bundle install --upgrade"

    output="$(HOME="$test_home" "$DOTFILES_ROOT/setup.sh" --server --upgrade --dry-run 2>&1)"
    assert_contains "$output" "Dry-run command: brew update"
    assert_contains "$output" "brew bundle install --upgrade"
    assert_not_contains "$output" "brew bundle install --no-upgrade"
}

test_brewfiles_match_profile_packages() {
    local actual_common
    local actual_workstation
    local expected_common
    local expected_workstation

    actual_common="$(sed -n 's/^brew "\([^"]*\)".*/\1/p' "$DOTFILES_ROOT/Brewfile")"
    expected_common="$(printf '%s\n' \
        atuin bat curl delta difftastic direnv eza fd fzf gh gitleaks git \
        git-branchless gnupg gum herdr htop jj jq lazygit lesspipe mise neovim \
        neovim-remote ripgrep ripgrep-all shellcheck shellharden shfmt stow tldr \
        tmux tmuxinator tpm tree uv vim wget yq zellij zoxide)"
    [[ "$actual_common" = "$expected_common" ]] || fail "common Brewfile does not match the server package profile"

    actual_workstation="$(sed -n 's/^brew "\([^"]*\)".*/\1/p' "$DOTFILES_ROOT/Brewfile.workstation")"
    expected_workstation="$(printf '%s\n' btop ffmpeg glances imagemagick lynx pandoc poppler tesseract w3m zsh)"
    [[ "$actual_workstation" = "$expected_workstation" ]] || fail "workstation Brewfile does not match its package profile"

    grep -Fxq 'brew "zsh" if OS.linux?' "$DOTFILES_ROOT/Brewfile.workstation" || fail "zsh is not Linux-gated"
    grep -Fxq 'cask "ghostty" if OS.mac?' "$DOTFILES_ROOT/Brewfile.workstation" || fail "Ghostty is not macOS-gated"
    ! grep -Eiq 'bob|copilot' "$DOTFILES_ROOT/Brewfile" "$DOTFILES_ROOT/Brewfile.workstation" || fail "removed packages remain in a Brewfile"
}

test_shell_startup_activates_user_local_linuxbrew() {
    local test_home
    local fake_bin
    local fake_brew
    test_home="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-user-linuxbrew.XXXXXX")"
    fake_bin="$test_home/test-bin"
    fake_brew="$test_home/.linuxbrew/bin/brew"
    mkdir -p "$fake_bin" "$(dirname "$fake_brew")"
    # shellcheck disable=SC2016
    printf '%s\n' \
        '#!/bin/sh' \
        'if [ "${1:-}" = shellenv ]; then' \
        '    printf "%s\n" "export DOTFILES_TEST_BREW_ACTIVE=true"' \
        'fi' >"$fake_brew"
    printf '%s\n' '#!/bin/sh' 'printf "%s\n" Linux' >"$fake_bin/uname"
    chmod +x "$fake_brew"
    chmod +x "$fake_bin/uname"

    if ! HOME="$test_home" DOTFILES_TEST_ROOT="$DOTFILES_ROOT" PATH="$fake_bin:$PATH" bash -c '
        set -euo pipefail
        unset DOTFILES_TEST_BREW_ACTIVE
        source "$DOTFILES_TEST_ROOT/shared/shell/homebrew.sh"
        [[ "${DOTFILES_TEST_BREW_ACTIVE:-}" = true ]]
    '; then
        fail "shell startup did not activate user-local Linuxbrew"
    fi
}

test_ci_runs_on_master_pushes() {
    local workflow
    workflow="$(<"$DOTFILES_ROOT/.github/workflows/test.yml")"

    assert_contains "$workflow" "      - master"
}

test_workstation_adds_platform_appropriate_extras() {
    local test_home
    local output
    test_home="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-workstation-preview.XXXXXX")"

    output="$(HOME="$test_home" "$DOTFILES_ROOT/setup.sh" --dry-run 2>&1)"
    assert_contains "$output" "Brewfile.workstation"
    assert_contains "$output" "ghostty"

    if [[ "$(uname)" = "Darwin" ]]; then
        assert_contains "$output" "cmux"
    else
        assert_not_contains "$output" "cmux"
    fi
}

test_bash_integration_preserves_existing_config() {
    local test_home
    local original_line="# valuable Ubuntu default"
    local backup_count
    test_home="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-bash-home.XXXXXX")"
    printf '%s\n' "$original_line" >"$test_home/.bashrc"

    if ! HOME="$test_home" DOTFILES_TEST_ROOT="$DOTFILES_ROOT" bash -c '
        set -euo pipefail
        source "$DOTFILES_TEST_ROOT/setup.sh"
        DOTFILES="$DOTFILES_TEST_ROOT"
        DRY_RUN=false
        configure_bash
        configure_bash
    '; then
        fail "Bash integration should succeed"
    fi

    assert_contains "$(<"$test_home/.bashrc")" "$original_line"
    assert_contains "$(<"$test_home/.bashrc")" "# >>> dotfiles setup >>>"
    assert_contains "$(<"$test_home/.bashrc")" "source \"$DOTFILES_ROOT/bash/.bashrc\""
    [[ "$(grep -c '# >>> dotfiles setup >>>' "$test_home/.bashrc")" -eq 1 ]] || fail "Bash marker was duplicated"

    backup_count="$(find "$test_home" -maxdepth 1 -name '.bashrc.dotfiles-backup.*' | wc -l | tr -d ' ')"
    [[ "$backup_count" -eq 1 ]] || fail "expected exactly one Bash backup, found $backup_count"
}

test_bash_integration_refuses_unrelated_symlinks() {
    local test_home
    local foreign_target
    test_home="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-bash-link-home.XXXXXX")"
    foreign_target="$test_home/foreign-bashrc"
    printf '%s\n' "# foreign config" >"$foreign_target"
    ln -s "$foreign_target" "$test_home/.bashrc"

    if HOME="$test_home" DOTFILES_TEST_ROOT="$DOTFILES_ROOT" bash -c '
        set -euo pipefail
        source "$DOTFILES_TEST_ROOT/setup.sh"
        DOTFILES="$DOTFILES_TEST_ROOT"
        DRY_RUN=false
        write_managed_block \
            "$HOME/.bashrc" \
            "$DOTFILES/bash/.bashrc" \
            "source \"$DOTFILES/bash/.bashrc\""
    '; then
        fail "unrelated Bash symlink should be refused"
    fi

    [[ -L "$test_home/.bashrc" ]] || fail "unrelated Bash symlink was replaced"
    [[ "$(<"$foreign_target")" = "# foreign config" ]] || fail "unrelated symlink target was modified"
}

test_bash_integration_accepts_existing_repo_symlink() {
    local test_home
    test_home="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-bash-repo-link.XXXXXX")"
    ln -s "$DOTFILES_ROOT/bash/.bashrc" "$test_home/.bashrc"

    if ! HOME="$test_home" DOTFILES_TEST_ROOT="$DOTFILES_ROOT" bash -c '
        set -euo pipefail
        source "$DOTFILES_TEST_ROOT/setup.sh"
        DOTFILES="$DOTFILES_TEST_ROOT"
        DRY_RUN=false
        write_managed_block \
            "$HOME/.bashrc" \
            "$DOTFILES/bash/.bashrc" \
            "source \"$DOTFILES/bash/.bashrc\""
    '; then
        fail "existing dotfiles Bash symlink should be accepted"
    fi

    [[ -L "$test_home/.bashrc" ]] || fail "dotfiles Bash symlink was replaced"
}

test_bash_integration_preflights_both_targets() {
    local test_home
    local original_bashrc="# valuable Ubuntu default"
    test_home="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-bash-preflight.XXXXXX")"
    printf '%s\n' "$original_bashrc" >"$test_home/.bashrc"
    printf '%s\n' '# foreign input config' >"$test_home/foreign-inputrc"
    ln -s "$test_home/foreign-inputrc" "$test_home/.inputrc"

    if HOME="$test_home" DOTFILES_TEST_ROOT="$DOTFILES_ROOT" bash -c '
        set -euo pipefail
        set --
        source "$DOTFILES_TEST_ROOT/setup.sh"
        DOTFILES="$DOTFILES_TEST_ROOT"
        configure_bash
    '; then
        fail "Bash integration should be blocked by an unrelated inputrc symlink"
    fi

    [[ "$(<"$test_home/.bashrc")" = "$original_bashrc" ]] || fail "Bash integration partially modified .bashrc"
    [[ -z "$(find "$test_home" -maxdepth 1 -name '.bashrc.dotfiles-backup.*' -print -quit)" ]] || fail "blocked Bash integration created a backup"
    [[ -L "$test_home/.inputrc" ]] || fail "blocked inputrc symlink was replaced"
}

test_bash_integration_updates_stale_paths_and_preserves_modes() {
    local test_home
    local bash_mode
    local input_mode
    local bash_backup_count
    local input_backup_count
    test_home="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-bash-relocation.XXXXXX")"
    printf '%s\n' \
        '# valuable Ubuntu default' \
        '# >>> dotfiles setup >>>' \
        'source "/old/location/bash/.bashrc"' \
        '# <<< dotfiles setup <<<' >"$test_home/.bashrc"
    # shellcheck disable=SC2016
    printf '%s\n' \
        '# valuable Readline default' \
        '# >>> dotfiles setup >>>' \
        '$include /old/location/bash/.inputrc' \
        '# <<< dotfiles setup <<<' >"$test_home/.inputrc"
    chmod 640 "$test_home/.bashrc"
    chmod 600 "$test_home/.inputrc"

    HOME="$test_home" DOTFILES_TEST_ROOT="$DOTFILES_ROOT" bash -c '
        set -euo pipefail
        set --
        source "$DOTFILES_TEST_ROOT/setup.sh"
        DOTFILES="$DOTFILES_TEST_ROOT"
        configure_bash
        configure_bash
    '

    assert_not_contains "$(<"$test_home/.bashrc")" "/old/location"
    assert_contains "$(<"$test_home/.bashrc")" "source \"$DOTFILES_ROOT/bash/.bashrc\""
    assert_not_contains "$(<"$test_home/.inputrc")" "/old/location"
    assert_contains "$(<"$test_home/.inputrc")" "\$include $DOTFILES_ROOT/bash/.inputrc"

    if stat -f '%Lp' "$test_home/.bashrc" >/dev/null 2>&1; then
        bash_mode="$(stat -f '%Lp' "$test_home/.bashrc")"
        input_mode="$(stat -f '%Lp' "$test_home/.inputrc")"
    else
        bash_mode="$(stat -c '%a' "$test_home/.bashrc")"
        input_mode="$(stat -c '%a' "$test_home/.inputrc")"
    fi
    [[ "$bash_mode" = "640" ]] || fail ".bashrc permissions changed to $bash_mode"
    [[ "$input_mode" = "600" ]] || fail ".inputrc permissions changed to $input_mode"

    bash_backup_count="$(find "$test_home" -maxdepth 1 -name '.bashrc.dotfiles-backup.*' | wc -l | tr -d ' ')"
    input_backup_count="$(find "$test_home" -maxdepth 1 -name '.inputrc.dotfiles-backup.*' | wc -l | tr -d ' ')"
    [[ "$bash_backup_count" -eq 1 ]] || fail "expected one relocation backup for .bashrc"
    [[ "$input_backup_count" -eq 1 ]] || fail "expected one relocation backup for .inputrc"
}

test_bash_config_discovers_repository_location() {
    local test_home
    local output
    test_home="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-bash-location.XXXXXX")"
    ln -s "$DOTFILES_ROOT/bash/.bashrc" "$test_home/repo-bashrc"

    output="$(HOME="$test_home" bash --noprofile --norc -ic '
        source "$1"
        printf "%s" "$DOTFILES"
    ' bash "$test_home/repo-bashrc" 2>/dev/null)"

    [[ "$output" = "$DOTFILES_ROOT" ]] || fail "Bash config hard-coded DOTFILES to $output"
}

test_failed_erb_render_leaves_no_target() {
    local test_dir
    local fake_bin
    local template_file
    local output_file
    test_dir="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-erb-failure.XXXXXX")"
    fake_bin="$test_dir/bin"
    template_file="$test_dir/example.erb"
    output_file="$test_dir/example"
    mkdir -p "$fake_bin"
    printf '%s\n' '#!/bin/sh' 'exit 1' >"$fake_bin/erb"
    printf '%s\n' '#!/bin/sh' 'exit 1' >"$fake_bin/mise"
    chmod +x "$fake_bin/erb" "$fake_bin/mise"
    printf '%s\n' '<%= "rendered" %>' >"$template_file"

    if DOTFILES_TEST_ROOT="$DOTFILES_ROOT" bash -c '
        set -euo pipefail
        fake_bin="$1"
        template_file="$2"
        output_file="$3"
        set --
        source "$DOTFILES_TEST_ROOT/setup.sh"
        PATH="$fake_bin:$PATH"
        process_erb_template "$template_file" "$output_file"
    ' bash "$fake_bin" "$template_file" "$output_file"; then
        fail "failed ERB render should return nonzero"
    fi

    [[ ! -e "$output_file" ]] || fail "failed ERB render created a target file"
}

test_template_render_does_not_fall_back_to_system_erb() {
    local test_dir
    local fake_bin
    local template_file
    local output_file
    local erb_marker
    test_dir="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-erb-mise-only.XXXXXX")"
    fake_bin="$test_dir/bin"
    template_file="$test_dir/example.erb"
    output_file="$test_dir/example"
    erb_marker="$test_dir/system-erb-called"
    mkdir -p "$fake_bin"
    printf '%s\n' '#!/bin/sh' 'exit 1' >"$fake_bin/mise"
    # shellcheck disable=SC2016
    printf '%s\n' '#!/bin/sh' ': >"$ERB_MARKER"' 'printf "%s\n" rendered' >"$fake_bin/erb"
    chmod +x "$fake_bin/erb" "$fake_bin/mise"
    printf '%s\n' '<%= "rendered" %>' >"$template_file"

    if ERB_MARKER="$erb_marker" DOTFILES_TEST_ROOT="$DOTFILES_ROOT" bash -c '
        set -euo pipefail
        fake_bin="$1"
        template_file="$2"
        output_file="$3"
        set --
        source "$DOTFILES_TEST_ROOT/setup.sh"
        PATH="$fake_bin:/usr/bin:/bin"
        process_erb_template "$template_file" "$output_file"
    ' bash "$fake_bin" "$template_file" "$output_file"; then
        fail "template rendering should require mise-managed Ruby"
    fi

    [[ ! -e "$erb_marker" ]] || fail "template rendering invoked system erb"
    [[ ! -e "$output_file" ]] || fail "system erb fallback created a target file"
}

test_template_batch_reports_render_failures() {
    local test_dir
    local fake_bin
    test_dir="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-erb-batch.XXXXXX")"
    fake_bin="$test_dir/bin"
    mkdir -p "$fake_bin" "$test_dir/repo/templates" "$test_dir/home"
    printf '%s\n' '#!/bin/sh' 'exit 1' >"$fake_bin/mise"
    chmod +x "$fake_bin/mise"
    printf '%s\n' '<%= "rendered" %>' >"$test_dir/repo/templates/.example.erb"

    if HOME="$test_dir/home" DOTFILES_TEST_ROOT="$DOTFILES_ROOT" bash -c '
        set -euo pipefail
        fake_bin="$1"
        test_repo="$2"
        set --
        source "$DOTFILES_TEST_ROOT/setup.sh"
        DOTFILES="$test_repo"
        PATH="$fake_bin:/usr/bin:/bin"
        create_local_configs || exit $?
    ' bash "$fake_bin" "$test_dir/repo"; then
        fail "template batch should report an individual render failure"
    fi

    [[ ! -e "$test_dir/home/.example" ]] || fail "failed template batch created a target file"
}

test_invalid_rendered_git_config_is_rejected() {
    local test_dir
    local fake_bin
    local template_file
    local output_file
    test_dir="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-invalid-git-config.XXXXXX")"
    fake_bin="$test_dir/bin"
    template_file="$test_dir/gitconfig.erb"
    output_file="$test_dir/.gitconfig.local"
    mkdir -p "$fake_bin"
    printf '%s\n' '#!/bin/sh' 'printf "%s\n" "[user"' >"$fake_bin/mise"
    chmod +x "$fake_bin/mise"
    printf '%s\n' '<%= "invalid config" %>' >"$template_file"

    if DOTFILES_TEST_ROOT="$DOTFILES_ROOT" bash -c '
        set -euo pipefail
        fake_bin="$1"
        template_file="$2"
        output_file="$3"
        set --
        source "$DOTFILES_TEST_ROOT/setup.sh"
        PATH="$fake_bin:/usr/bin:/bin"
        process_erb_template "$template_file" "$output_file"
    ' bash "$fake_bin" "$template_file" "$output_file"; then
        fail "invalid rendered Git configuration should be rejected"
    fi

    [[ ! -e "$output_file" ]] || fail "invalid Git configuration created a target file"
}

test_valid_rendered_git_config_is_installed() {
    local test_dir
    local fake_bin
    local template_file
    local output_file
    test_dir="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-valid-git-config.XXXXXX")"
    fake_bin="$test_dir/bin"
    template_file="$test_dir/gitconfig.erb"
    output_file="$test_dir/.gitconfig.local"
    mkdir -p "$fake_bin"
    printf '%s\n' '#!/bin/sh' 'printf "%s\n" "[user]" "    name = Test User"' >"$fake_bin/mise"
    chmod +x "$fake_bin/mise"
    printf '%s\n' '<%= "valid config" %>' >"$template_file"

    DOTFILES_TEST_ROOT="$DOTFILES_ROOT" bash -c '
        set -euo pipefail
        fake_bin="$1"
        template_file="$2"
        output_file="$3"
        set --
        source "$DOTFILES_TEST_ROOT/setup.sh"
        PATH="$fake_bin:/usr/bin:/bin"
        process_erb_template "$template_file" "$output_file"
    ' bash "$fake_bin" "$template_file" "$output_file"

    [[ "$(git config --file "$output_file" --get user.name)" = "Test User" ]] || fail "valid rendered Git configuration did not parse"
}

test_existing_local_config_is_untouched() {
    local test_dir
    local fake_bin
    local template_file
    local output_file
    local mise_marker
    test_dir="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-existing-local.XXXXXX")"
    fake_bin="$test_dir/bin"
    template_file="$test_dir/example.erb"
    output_file="$test_dir/.gitconfig.local"
    mise_marker="$test_dir/mise-called"
    mkdir -p "$fake_bin"
    # shellcheck disable=SC2016
    printf '%s\n' '#!/bin/sh' ': >"$MISE_MARKER"' >"$fake_bin/mise"
    chmod +x "$fake_bin/mise"
    printf '%s\n' '<%= "replacement" %>' >"$template_file"
    printf '%s\n' '# valuable local config' >"$output_file"

    MISE_MARKER="$mise_marker" DOTFILES_TEST_ROOT="$DOTFILES_ROOT" bash -c '
        set -euo pipefail
        fake_bin="$1"
        template_file="$2"
        output_file="$3"
        set --
        source "$DOTFILES_TEST_ROOT/setup.sh"
        PATH="$fake_bin:/usr/bin:/bin"
        process_erb_template "$template_file" "$output_file"
    ' bash "$fake_bin" "$template_file" "$output_file"

    [[ "$(<"$output_file")" = "# valuable local config" ]] || fail "existing local config was overwritten"
    [[ ! -e "$mise_marker" ]] || fail "existing local config was unnecessarily rendered"
}

test_main_does_not_manage_ssh_by_default() {
    local test_dir
    local marker_file
    test_dir="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-ssh-default.XXXXXX")"
    marker_file="$test_dir/ssh-called"

    DOTFILES_TEST_ROOT="$DOTFILES_ROOT" SSH_MARKER="$marker_file" bash -c '
        set -euo pipefail
        set --
        source "$DOTFILES_TEST_ROOT/setup.sh"
        SKIP_PACKAGES=true
        SKIP_CONFIGS=true
        SKIP_TEMPLATES=true
        SKIP_STOW=true
        trust_mise_configs() { :; }
        setup_git_hooks() { :; }
        manage_ssh_keys() { : >"$SSH_MARKER"; }
        main
    '

    [[ ! -e "$marker_file" ]] || fail "main invoked SSH management without --setup-ssh"
}

test_skip_mise_skips_trust_and_language_install() {
    local test_dir
    local event_log
    test_dir="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-skip-mise.XXXXXX")"
    event_log="$test_dir/events.log"
    : >"$event_log"

    DOTFILES_TEST_ROOT="$DOTFILES_ROOT" EVENT_LOG="$event_log" bash -c '
        set -euo pipefail
        set --
        source "$DOTFILES_TEST_ROOT/setup.sh"
        SKIP_PACKAGES=true
        SKIP_TEMPLATES=true
        SKIP_MODULES=(mise)
        preflight_system() { :; }
        setup_config_directory() { :; }
        stow_mise_config() { printf "%s\n" stow-mise >>"$EVENT_LOG"; }
        trust_mise_configs() { printf "%s\n" trust-mise >>"$EVENT_LOG"; }
        setup_global_languages() { printf "%s\n" install-languages >>"$EVENT_LOG"; }
        configure_bash() { :; }
        stow_selected_configs() { :; }
        setup_git_hooks() { :; }
        main
    '

    [[ ! -s "$event_log" ]] || fail "--skip-module mise still ran mise setup: $(<"$event_log")"
}

test_package_failure_stops_before_configuration() {
    local test_dir
    local mutation_marker
    local output
    test_dir="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-package-failure.XXXXXX")"
    mutation_marker="$test_dir/configuration-started"

    if output="$(DOTFILES_TEST_ROOT="$DOTFILES_ROOT" MUTATION_MARKER="$mutation_marker" bash -c '
        set -euo pipefail
        set --
        source "$DOTFILES_TEST_ROOT/setup.sh"
        preflight_system() { :; }
        install_homebrew() { return 1; }
        setup_config_directory() { : >"$MUTATION_MARKER"; }
        main
    ' 2>&1)"; then
        fail "package failure should fail setup"
    fi

    assert_contains "$output" "Package installation failed"
    [[ ! -e "$mutation_marker" ]] || fail "setup mutated configuration after a package failure"
}

test_linux_ssh_setup_does_not_start_transient_agent() {
    local test_dir
    local fake_bin
    local agent_marker
    local add_marker
    test_dir="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-ssh-agent.XXXXXX")"
    fake_bin="$test_dir/bin"
    agent_marker="$test_dir/agent-called"
    add_marker="$test_dir/add-called"
    mkdir -p "$fake_bin" "$test_dir/home/.ssh"
    : >"$test_dir/home/.ssh/id_ed25519"
    # shellcheck disable=SC2016
    printf '%s\n' '#!/bin/sh' ': >"$SSH_AGENT_MARKER"' >"$fake_bin/ssh-agent"
    # shellcheck disable=SC2016
    printf '%s\n' '#!/bin/sh' ': >"$SSH_ADD_MARKER"' >"$fake_bin/ssh-add"
    chmod +x "$fake_bin/ssh-agent" "$fake_bin/ssh-add"

    HOME="$test_dir/home" \
        DOTFILES_TEST_ROOT="$DOTFILES_ROOT" \
        SSH_AGENT_MARKER="$agent_marker" \
        SSH_ADD_MARKER="$add_marker" \
        bash -c '
            set -euo pipefail
            fake_bin="$1"
            set --
            source "$DOTFILES_TEST_ROOT/setup.sh"
            OS=Linux
            PATH="$fake_bin:$PATH"
            unset SSH_AUTH_SOCK
            setup_ssh_agent_integration
        ' bash "$fake_bin"

    [[ ! -e "$agent_marker" ]] || fail "SSH setup started a transient agent"
    [[ ! -e "$add_marker" ]] || fail "SSH setup called ssh-add without an inherited agent"
}

test_macos_ssh_setup_requires_running_agent() {
    local test_dir
    local fake_bin
    local add_marker
    test_dir="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-macos-ssh-agent.XXXXXX")"
    fake_bin="$test_dir/bin"
    add_marker="$test_dir/add-called"
    mkdir -p "$fake_bin" "$test_dir/home/.ssh"
    : >"$test_dir/home/.ssh/id_ed25519"
    # shellcheck disable=SC2016
    printf '%s\n' '#!/bin/sh' ': >"$SSH_ADD_MARKER"' >"$fake_bin/ssh-add"
    chmod +x "$fake_bin/ssh-add"

    HOME="$test_dir/home" \
        DOTFILES_TEST_ROOT="$DOTFILES_ROOT" \
        SSH_ADD_MARKER="$add_marker" \
        bash -c '
            set -euo pipefail
            fake_bin="$1"
            set --
            source "$DOTFILES_TEST_ROOT/setup.sh"
            OS=Darwin
            PATH="$fake_bin:$PATH"
            unset SSH_AUTH_SOCK
            setup_ssh_agent_integration
        ' bash "$fake_bin"

    [[ ! -e "$add_marker" ]] || fail "macOS SSH setup called ssh-add without an inherited agent"
}

test_opt_in_ssh_setup_does_not_rewrite_client_config() {
    local test_home
    local original_config="Host production"
    test_home="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-ssh-config.XXXXXX")"
    mkdir -p "$test_home/.ssh"
    printf '%s\n' "$original_config" >"$test_home/.ssh/config"
    printf '%s\n' 'ssh-ed25519 test' >"$test_home/.ssh/custom.pub"

    HOME="$test_home" DOTFILES_TEST_ROOT="$DOTFILES_ROOT" bash -c '
        set -euo pipefail
        set --
        source "$DOTFILES_TEST_ROOT/setup.sh"
        OS=Linux
        unset SSH_AUTH_SOCK
        manage_ssh_keys
    '

    [[ "$(<"$test_home/.ssh/config")" = "$original_config" ]] || fail "SSH client config was rewritten"
}

test_preflight_rejects_root() {
    local output

    if output="$(DOTFILES_TEST_ROOT="$DOTFILES_ROOT" bash -c '
        set -euo pipefail
        set --
        source "$DOTFILES_TEST_ROOT/setup.sh"
        preflight_system 0 x86_64 Linux
    ' 2>&1)"; then
        fail "preflight should reject root"
    fi

    assert_contains "$output" "Do not run setup as root"
}

test_preflight_rejects_unsupported_architecture() {
    local output

    if output="$(DOTFILES_TEST_ROOT="$DOTFILES_ROOT" bash -c '
        set -euo pipefail
        set --
        source "$DOTFILES_TEST_ROOT/setup.sh"
        preflight_system 501 mips64 Darwin
    ' 2>&1)"; then
        fail "preflight should reject unsupported architectures"
    fi

    assert_contains "$output" "Unsupported architecture: mips64"
}

test_linux_preflight_requires_sudo() {
    local empty_path
    local output
    empty_path="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-empty-path.XXXXXX")"

    if output="$(DOTFILES_TEST_ROOT="$DOTFILES_ROOT" bash -c '
        set -euo pipefail
        empty_path="$1"
        set --
        source "$DOTFILES_TEST_ROOT/setup.sh"
        PATH="$empty_path"
        preflight_system 501 x86_64 Linux
    ' bash "$empty_path" 2>&1)"; then
        fail "Linux preflight should require sudo"
    fi

    assert_contains "$output" "sudo is required for Linux setup"
}

test_linux_preflight_requires_working_sudo() {
    local fake_path
    local output
    fake_path="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-failing-sudo.XXXXXX")"
    printf '%s\n' '#!/bin/sh' 'exit 1' >"$fake_path/sudo"
    chmod +x "$fake_path/sudo"

    if output="$(DOTFILES_TEST_ROOT="$DOTFILES_ROOT" bash -c '
        set -euo pipefail
        fake_path="$1"
        set --
        source "$DOTFILES_TEST_ROOT/setup.sh"
        PATH="$fake_path"
        preflight_system 501 x86_64 Linux
    ' bash "$fake_path" 2>&1)"; then
        fail "Linux preflight should reject unusable sudo"
    fi

    assert_contains "$output" "sudo authorization failed"
}

test_linux_bootstrap_installs_prerequisites_before_requiring_curl() {
    local test_dir
    local fake_bin
    local command_log
    test_dir="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-linux-bootstrap.XXXXXX")"
    fake_bin="$test_dir/bin"
    command_log="$test_dir/commands.log"
    mkdir -p "$fake_bin"
    : >"$command_log"
    printf '%s\n' '#!/bin/sh' 'exit 0' >"$fake_bin/apt-get"
    # shellcheck disable=SC2016
    printf '%s\n' \
        '#!/bin/sh' \
        'printf "%s\n" "$*" >>"$COMMAND_LOG"' \
        'case " $* " in' \
        '  *" apt-get install "*)' \
        '    printf "%s\n" "#!/bin/sh" "exit 1" >"$FAKE_BIN/curl"' \
        '    /bin/chmod +x "$FAKE_BIN/curl"' \
        '    ;;' \
        'esac' \
        'exit 0' >"$fake_bin/sudo"
    chmod +x "$fake_bin/apt-get" "$fake_bin/sudo"

    COMMAND_LOG="$command_log" \
        FAKE_BIN="$fake_bin" \
        DOTFILES_TEST_ROOT="$DOTFILES_ROOT" \
        bash -c '
            set -u
            set --
            source "$DOTFILES_TEST_ROOT/setup.sh"
            OS=Linux
            PATH="$FAKE_BIN"
            install_homebrew
        ' >/dev/null 2>&1 || true

    assert_contains "$(<"$command_log")" "apt-get update"
    assert_contains "$(<"$command_log")" "apt-get install -y build-essential procps curl file git ca-certificates"
}

test_main_uses_safe_first_run_order() {
    local test_dir
    local event_log
    local expected
    test_dir="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-order.XXXXXX")"
    event_log="$test_dir/events.log"
    : >"$event_log"

    DOTFILES_TEST_ROOT="$DOTFILES_ROOT" EVENT_LOG="$event_log" bash -c '
        set -euo pipefail
        set --
        source "$DOTFILES_TEST_ROOT/setup.sh"
        PROFILE=server
        record() { printf "%s\n" "$1" >>"$EVENT_LOG"; }
        preflight_system() { record preflight; }
        install_homebrew() { record packages; }
        setup_config_directory() { record config-dirs; }
        stow_mise_config() { record stow-mise; }
        trust_mise_configs() { record trust-mise; }
        setup_global_languages() { record install-languages; }
        create_local_configs() { record templates; }
        configure_bash() { record bash; }
        stow_selected_configs() { record stow-modules; }
        stow_configs() { record old-stow; }
        setup_git_hooks() { record git-hooks; }
        main
    '

    expected="$(printf '%s\n' \
        preflight \
        packages \
        config-dirs \
        stow-mise \
        trust-mise \
        install-languages \
        templates \
        bash \
        stow-modules \
        git-hooks)"
    [[ "$(<"$event_log")" = "$expected" ]] || {
        printf 'Actual order:\n%s\n' "$(<"$event_log")" >&2
        fail "main used an unsafe first-run order"
    }
}

test_stow_conflicts_are_collected() {
    local test_dir
    local event_log
    local output
    test_dir="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-stow-conflicts.XXXXXX")"
    event_log="$test_dir/events.log"
    : >"$event_log"

    if output="$(DOTFILES_TEST_ROOT="$DOTFILES_ROOT" EVENT_LOG="$event_log" bash -c '
        set -euo pipefail
        set --
        source "$DOTFILES_TEST_ROOT/setup.sh"
        profile_stow_modules() { printf "%s\n" atuin bat git; }
        stow_one_module() {
            printf "%s\n" "$1" >>"$EVENT_LOG"
            [[ "$1" != atuin && "$1" != git ]]
        }
        stow_selected_configs
    ' 2>&1)"; then
        fail "Stow conflicts should make setup fail"
    fi

    [[ "$(<"$event_log")" = "$(printf '%s\n' atuin bat git)" ]] || fail "Stow stopped before checking all requested modules"
    assert_contains "$output" "atuin, git"
    assert_not_contains "$(<"$DOTFILES_ROOT/setup.sh")" "stow --adopt"
}

test_unsupported_os_stops_before_mutation() {
    local test_dir
    local mutation_marker
    local output
    test_dir="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-unsupported-os.XXXXXX")"
    mutation_marker="$test_dir/mutated"

    if output="$(DOTFILES_TEST_ROOT="$DOTFILES_ROOT" MUTATION_MARKER="$mutation_marker" bash -c '
        set -euo pipefail
        set --
        source "$DOTFILES_TEST_ROOT/setup.sh"
        OS=FreeBSD
        preflight_system() { : >"$MUTATION_MARKER"; }
        install_homebrew() { : >"$MUTATION_MARKER"; }
        main
    ' 2>&1)"; then
        fail "unsupported OS should fail setup"
    fi

    assert_contains "$output" "Unsupported OS: FreeBSD"
    [[ ! -e "$mutation_marker" ]] || fail "unsupported OS reached a mutating phase"
}

test_tmux_resolves_tpm_from_homebrew_prefix() {
    local tmux_config
    tmux_config="$(<"$DOTFILES_ROOT/tmux/.tmux.conf")"

    assert_not_contains "$tmux_config" "/opt/homebrew/opt/tpm"
    assert_contains "$tmux_config" "brew --prefix tpm"
    assert_contains "$tmux_config" ".tmux/plugins/tpm/tpm"
}

test_server_dry_run_is_read_only
test_dry_run_reports_opt_in_ssh_without_touching_home
test_setup_can_be_sourced_without_running_main
test_dry_run_previews_managed_bash_files
test_conflicting_profiles_are_rejected
test_unknown_modules_are_rejected
test_packages_do_not_upgrade_by_default
test_dry_run_honors_package_flags
test_brewfiles_match_profile_packages
test_shell_startup_activates_user_local_linuxbrew
test_ci_runs_on_master_pushes
test_workstation_adds_platform_appropriate_extras
test_bash_integration_preserves_existing_config
test_bash_integration_refuses_unrelated_symlinks
test_bash_integration_accepts_existing_repo_symlink
test_bash_integration_preflights_both_targets
test_bash_integration_updates_stale_paths_and_preserves_modes
test_bash_config_discovers_repository_location
test_failed_erb_render_leaves_no_target
test_template_render_does_not_fall_back_to_system_erb
test_template_batch_reports_render_failures
test_invalid_rendered_git_config_is_rejected
test_valid_rendered_git_config_is_installed
test_existing_local_config_is_untouched
test_main_does_not_manage_ssh_by_default
test_skip_mise_skips_trust_and_language_install
test_package_failure_stops_before_configuration
test_linux_ssh_setup_does_not_start_transient_agent
test_macos_ssh_setup_requires_running_agent
test_opt_in_ssh_setup_does_not_rewrite_client_config
test_preflight_rejects_root
test_preflight_rejects_unsupported_architecture
test_linux_preflight_requires_sudo
test_linux_preflight_requires_working_sudo
test_linux_bootstrap_installs_prerequisites_before_requiring_curl
test_main_uses_safe_first_run_order
test_stow_conflicts_are_collected
test_unsupported_os_stops_before_mutation
test_tmux_resolves_tpm_from_homebrew_prefix
printf 'PASS: setup safety and profile tests\n'
