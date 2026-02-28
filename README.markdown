# Dotfiles

A comprehensive, cross-platform dotfiles setup optimized for development
productivity across macOS and Ubuntu systems. Features automated installation,
performance optimizations, and extensive customization options.

## Table of Contents

- [Features](#features)
- [Quick Start](#quick-start)
- [Installation Options](#installation-options)
- [Available Modules](#available-modules)
- [Customization](#customization)
- [Installed Packages](#installed-packages)
- [Shell Performance](#shell-performance)
- [Maintenance](#maintenance)
- [Troubleshooting](#troubleshooting)

## Features

- **Cross-platform support**: Works seamlessly on macOS and Ubuntu
- **Automated setup**: One command installs everything you need
- **Performance optimized**: Fast shell startup with smart completion caching
- **Modular design**: Use stow to install only what you need
- **Template system**: Machine-specific configurations with ERB templates
- **60+ packages**: Automatically installs essential development tools
- **SSH key management**: Optional SSH key creation and setup

## Quick Start

1. Clone the repository:

    ```bash
    git clone https://github.com/yourusername/dotfiles ~/.dotfiles
    cd ~/.dotfiles
    ```

2. Run the setup script:

    ```bash
    ./setup.sh
    ```

3. Restart your shell or source your configuration:
    ```bash
    exec $SHELL
    ```

## Installation Options

### Full Setup

```bash
./setup.sh
```

### Setup with Options

```bash
# Optionally update Homebrew before installing (macOS and Linux)
./setup.sh --update-brew

# Selective installation
./setup.sh --skip-packages    # Skip package installation
./setup.sh --skip-configs     # Skip config directory setup
./setup.sh --skip-templates   # Skip template processing
./setup.sh --skip-ssh         # Skip SSH key management
./setup.sh --skip-stow        # Skip stowing configuration files
```

### Manual Module Installation

If you prefer to install specific modules only:

```bash
# Install specific configurations
stow nvim      # Neovim configuration
stow zsh       # Zsh configuration
stow tmux      # Tmux configuration
```

**Note:** When setting up manually, trust the repository's Mise configuration
files so they can be processed correctly:

```bash
mise trust ~/.dotfiles/mise/.config/mise/config.toml
```

The `setup.sh` script performs this automatically.

## Available Modules

### Editors & IDEs

- **nvim**: Modern Neovim configuration with Lua-based setup
- **vim**: Classic Vim configuration with shared settings

### Shells & Terminals

- **bash**: Bash configuration with shared shell utilities
- **zsh**: Zsh configuration with optimized startup
- **tmux**: Terminal multiplexer with custom keybindings

### Development Tools

- **git**: Git configuration with template support
- **prettier**: Code formatting configuration

### System Tools

- **htop**: System monitor configuration
- **lazygit**: Git TUI configuration
- **ghostty**: Terminal emulator settings

### Shared Components

- **shared/shell**: Common shell utilities and functions
- **shared/vim**: Shared Vim/Neovim configurations

## Customization

### Environment Variables

Set these environment variables before running setup to customize your
installation:

```bash
export GIT_EMAIL="your.email@example.com"
export GIT_SIGNING_KEY="your-gpg-key-id"
export GIT_EXCLUDES_FILE="~/.gitignore_global"
export GIT_EDITOR="nvim"
```

### Template System

The setup script processes ERB templates for machine-specific configurations:

- `.gitconfig.local.erb` → `~/.gitconfig.local`
- `.zshrc.local.erb` → `~/.zshrc.local`

Templates support environment variable substitution and conditional logic.

### Local Overrides

After setup, you can customize configurations in:

- `~/.gitconfig.local`: Machine-specific Git settings
- `~/.zshrc.local`: Machine-specific Zsh settings

## Installed Packages

### Common Tools (All Platforms)

- **Core**: bat, curl, fzf, git, jq, neovim, ripgrep, ruby, stow, tmux, vim
- **System**: direnv, glances, htop, tree, wget
- **Development**: lazygit, shellcheck, shellharden, shfmt, lesspipe
- **Python**: uv (Python package installer)
- **Terminal**: lynx, w3m, zellij, tmuxinator, tpm

### Platform Notes

- **Package Manager**: Homebrew on macOS and Linux
- **Applications**: ghostty (via Homebrew Cask on macOS)

## Shell Performance

The shell configurations are optimized for fast startup:

- **FNM (Fast Node Manager)**: Rust-based Node.js version manager, 40x faster
  than NVM
- **Smart completion caching**: Rebuilds only when needed (every 24 hours or
  when cache is missing)
- **Lazy loading**: Tools are loaded only when first used

### Rebuilding Completions

After installing new CLI tools, you may want to refresh shell completions
immediately:

```bash
rebuild-completions
```

This utility function will clear the completion cache and rebuild it, making new
completions available right away. Otherwise, completions automatically rebuild
within 24 hours.

## GitHub Copilot Extension Setup

The setup script installs the GitHub CLI (`gh`) but does not automatically
install the Copilot extension due to authentication requirements. To enable
GitHub Copilot in your terminal:

1. **Authenticate with GitHub**:

    ```bash
    gh auth login
    ```

2. **Install the Copilot extension**:

    ```bash
    gh extension install github/gh-copilot
    ```

3. **Restart your shell to load aliases**:
    ```bash
    exec $SHELL
    ```

Once set up, you'll have access to these convenient aliases:

- `ghcs` - Get command suggestions (`gh copilot suggest`)
- `ghce` - Get command explanations (`gh copilot explain`)

**Note**: You need an active GitHub Copilot subscription to use these features.

## Maintenance

### Updating Dotfiles

```bash
cd ~/.dotfiles
git pull origin main
./setup.sh --skip-packages  # Update configs without reinstalling packages
```

### Managing Modules

```bash
# Install a new module
stow <module-name>

# Remove a module (unlink its symlinks)
stow -D <module-name>

# Reinstall a module (useful after updates)
stow -R <module-name>
```

### Package Updates

```bash
# macOS
brew update && brew upgrade

# Ubuntu
sudo apt update && sudo apt upgrade
```

### Secret Scanning (gitleaks)

This repo includes automated gitleaks scanning on pull requests and pushes to
`main` via GitHub Actions.

Run a local scan before pushing:

```bash
gitleaks git -v
```

Pre-commit scanning is also configured through repo-managed hooks.

For existing clones, enable them once:

```bash
git config core.hooksPath .githooks
```

After running `./setup.sh`, this is configured automatically.

## Troubleshooting

### Stow Conflicts

If stow reports conflicts when installing a module:

```bash
# Check what conflicts exist
stow -n <module-name>

# Backup existing files and try again
mv ~/.config/nvim ~/.config/nvim.backup
stow nvim
```

### Shell Performance Issues

If shell startup is slow:

```bash
# Force rebuild completions
rebuild-completions

# Check shell startup time
time zsh -i -c exit

# Profile shell startup to identify slow components
ZSH_PROFILE=1 zsh -i -c exit
```

### SSH Key Issues

If SSH key creation fails or you need to regenerate:

```bash
# Generate new SSH key manually
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519

# Or run setup with only SSH management
./setup.sh --skip-packages --skip-configs --skip-templates --skip-stow
```

### ERB Template Processing

If templates aren't processed correctly:

```bash
# Check if ERB is available
which erb

# Install ruby if missing (provides ERB)
brew install ruby    # macOS
sudo apt install ruby # Ubuntu
```
