# Dotfiles

Cross-platform developer configuration for macOS workstations and Ubuntu/Linux
servers. Setup is profile-driven, preserves existing Bash defaults, and leaves
SSH completely alone unless explicitly requested.

## Ubuntu server quick start

Run setup as the normal, non-root user whose home directory should be
configured. The user must have working `sudo`; existing SSH access is enough.

```bash
git clone git@github.com:vickaita/dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# Read-only preview. Review package, module, and conflict output first.
./setup.sh --server --dry-run

# Apply the server profile.
./setup.sh --server
```

The server command does not inspect or change `~/.ssh`, start an SSH agent, or
run `ssh-add`. It also does not replace Ubuntu's `~/.bashrc` or `~/.inputrc`.

## Profiles

`workstation` remains the default for compatibility. `--server` is shorthand
for `--profile server`.

| Profile | Packages | Configuration modules |
| --- | --- | --- |
| `server` | Common developer CLI tools | Bash integration, atuin, bat, git, herdr, htop, jj, lazygit, mise, nvim, prettier, tmux, vim, zellij, agents |
| `workstation` | Common tools plus media, document, text-browser, and monitoring tools | Server modules plus zsh and Ghostty; cmux on macOS |

The common package set is defined in `Brewfile`: atuin, bat, curl, delta,
difftastic, direnv, eza, fd, fzf, gh, gitleaks, git, git-branchless, gnupg, gum,
herdr, htop, jj, jq, lazygit, lesspipe, mise, neovim, neovim-remote, ripgrep,
ripgrep-all, shellcheck, shellharden, shfmt, stow, tldr, tmux, tmuxinator, tpm,
tree, uv, vim, wget, yq, zellij, and zoxide.

`Brewfile.workstation` adds btop, ffmpeg, glances, imagemagick, lynx, pandoc,
poppler, tesseract, and w3m. It installs zsh only on Linux and installs the
Ghostty cask only on macOS. Neovim is installed directly through Homebrew.

## Safety behavior

Before making changes, setup rejects unsupported operating systems and CPU
architectures, root execution, and Linux users without usable `sudo`. On a fresh
Ubuntu/Debian system it installs these Homebrew prerequisites before requiring
`curl`:

```text
build-essential procps curl file git ca-certificates
```

Homebrew is detected at its normal macOS and Linux locations even when it is
not yet on `PATH`. Setup then runs in this order:

1. Resolve the profile and run preflight checks.
2. Install profile packages.
3. Create required real configuration directories.
4. Stow mise, trust the exact resulting config, and run `mise install`.
5. Render machine-local templates with mise-managed Ruby.
6. Integrate Bash and Stow the remaining profile modules.
7. Optionally manage SSH keys when `--setup-ssh` was supplied.
8. Enable this repository's Git hooks.

Stow always performs a conflict preview first. Conflicting modules are reported
and setup exits nonzero; it never uses `stow --adopt`.

### Bash and Readline preservation

The Bash module is not Stowed onto `~/.bashrc`. Instead, setup appends one
marked block that sources the repository's Bash configuration. It uses the same
strategy for `~/.inputrc` with a Readline `$include`:

```text
# >>> dotfiles setup >>>
source "/absolute/path/to/dotfiles/bash/.bashrc"
# <<< dotfiles setup <<<
```

All pre-existing content and file permissions are preserved. Before the first
changed write, setup creates a UTC timestamped backup such as:

```text
~/.bashrc.dotfiles-backup.20260829T143000Z
~/.inputrc.dotfiles-backup.20260829T143000Z
```

No-op reruns create no additional backup. If the repository moves, the marked
path is updated atomically. A symlink to the corresponding file in this
repository is accepted as already configured; any unrelated symlink blocks the
whole Bash integration step without changing either target.

Use `--skip-module bash` to leave Bash and Readline entirely unchanged.

### SSH is opt-in

Without `--setup-ssh`, setup does not inspect, create, chmod, or modify anything
under `~/.ssh`, and does not invoke `ssh-agent` or `ssh-add`.

```bash
./setup.sh --server --setup-ssh
```

The opt-in flow can offer to create a default Ed25519 or RSA key interactively.
It only adds default keys to an already-running agent. It does not create SSH
client policy, rewrite `Host *`, set `IdentitiesOnly`, change algorithms, or
start a transient Linux agent. `--skip-ssh` remains accepted as a compatibility
option and preserves the default no-SSH behavior.

### Templates

Templates are rendered to temporary files through `mise exec -- erb`, checked
for unresolved ERB, validated when they contain Git configuration, and then
moved atomically into place. Existing local files and symlinks are never
overwritten.

Available outputs are:

- `~/.gitconfig.local`
- `~/.jjconfig.local.toml`
- `~/.zshrc.local` on the workstation profile

Optional environment variables include `GIT_NAME`, `GIT_EMAIL`,
`GIT_SIGNING_KEY`, `GIT_EXCLUDES_FILE`, `GIT_EDITOR`, and `JJ_EDITOR`.

## Command-line options

```text
--profile server|workstation  Select a profile (default: workstation)
--server                      Alias for --profile server
--dry-run                     Run read-only checks and print planned actions
--upgrade                     Update Homebrew and upgrade bundle dependencies
--update-brew                 Update Homebrew metadata without upgrading packages
--setup-ssh                   Opt in to SSH key setup
--skip-ssh                    Preserve the default no-SSH behavior
--skip-packages               Skip Homebrew and package installation
--skip-configs                Skip directories, mise setup, templates, Bash, and Stow
--skip-templates              Skip only local template rendering
--skip-stow                   Skip only Stow deployment
--skip-module NAME            Skip one configuration module; repeat as needed
--help                        Show built-in help
```

Unknown module names and conflicting profiles are rejected before setup starts.
Examples:

```bash
# Keep Ubuntu Bash completely untouched but install the rest of the server profile.
./setup.sh --server --skip-module bash

# Omit selected server configuration modules.
./setup.sh --server --skip-module tmux --skip-module zellij

# Install packages only.
./setup.sh --server --skip-configs

# Deploy configuration without touching packages.
./setup.sh --server --skip-packages
```

`--skip-stow` does not disable mise trust/install when an existing
`~/.config/mise/config.toml` is present. Use `--skip-module mise` to skip the
entire managed mise configuration and language-install phase.

## Package update policy

Normal runs use `brew bundle install --no-upgrade`. Already-installed packages
are not upgraded as an incidental part of setup.

```bash
# Refresh Homebrew metadata, then install missing packages without upgrades.
./setup.sh --server --update-brew

# Explicitly update Homebrew and upgrade bundle dependencies.
./setup.sh --server --upgrade
```

## Manual module management

Configuration modules are GNU Stow packages rooted in this repository:

```bash
stow -n -d ~/.dotfiles -t ~ nvim  # preview
stow -d ~/.dotfiles -t ~ nvim     # install
stow -D -d ~/.dotfiles -t ~ nvim  # remove links
```

Do not manually Stow `bash` over an existing Ubuntu `~/.bashrc`; use setup's
managed include or source `bash/.bashrc` from your own configuration. When
managing mise manually, the deployed config is `~/.config/mise/config.toml`:

```bash
mise trust --yes ~/.config/mise/config.toml
mise install
```

## Validation

The setup checks run on Ubuntu and macOS in CI. Locally:

```bash
bash -n setup.sh tests/test_setup.sh tests/test_prompt.sh shared/shell/*.sh
zsh -n zsh/.zshrc
shellcheck -x setup.sh tests/test_setup.sh shared/shell/homebrew.sh
shfmt -d -i 4 -ci setup.sh tests/test_setup.sh
bash tests/test_prompt.sh
bash tests/test_setup.sh
ruby -c Brewfile
ruby -c Brewfile.workstation
```

## Troubleshooting

If dry-run reports a Stow conflict, move or merge the existing target yourself,
then rerun the preview. Setup deliberately does not adopt conflicting files.

If Bash integration reports an unrelated symlink, inspect it with `readlink`
and decide whether to keep it and use `--skip-module bash`, or replace it
manually before rerunning setup.

If template rendering fails, verify that the mise module was deployed and that
`mise install` completed. A failed or unresolved template never creates the
destination file.

This repository enables `.githooks` through local `core.hooksPath`; gitleaks is
also run in GitHub Actions.
