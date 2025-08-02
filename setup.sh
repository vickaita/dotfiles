#!/bin/bash

# Improved setup script with better idempotency and error handling
set -euo pipefail # Exit on error, undefined vars, pipe failures

# Identify the OS
OS="$(uname)"

# Color output for better UX
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

COMMON_PACKAGES=(
    bat
    curl
    direnv
    fzf
    git
    glances
    htop
    jq
    lazygit
    lesspipe
    neovim
    ripgrep
    shellcheck
    shellharden
    shfmt
    stow
    tmux
    tmuxinator
    tpm
    tree
    uv
    vim
    wget
    zellij
)

MAC_SPECIFIC_PACKAGES=(fd gh pyenv nvm)
MAC_CASK_PACKAGES=(ghostty)
UBUNTU_SPECIFIC_PACKAGES=(fd-find)

# Check if a package is installed (cross-platform)
is_package_installed() {
    local package="$1"
    if [[ "$OS" = "Darwin" ]]; then
        brew list --formula | grep -q "^${package}$" 2>/dev/null
    elif [[ "$OS" = "Linux" ]]; then
        dpkg-query -W -f='${Status}' "$package" 2>/dev/null | grep -q "install ok installed"
    fi
}

# Check if a cask is installed (macOS only)
is_cask_installed() {
    local cask="$1"
    brew list --cask | grep -q "^${cask}$" 2>/dev/null
}

# Install packages only if not already installed
install_packages() {
    local packages=("$@")
    local to_install=()

    for package in "${packages[@]}"; do
        if ! is_package_installed "$package"; then
            to_install+=("$package")
        else
            log_info "$package is already installed, skipping"
        fi
    done

    if [[ ${#to_install[@]} -gt 0 ]]; then
        if [[ "$OS" = "Darwin" ]]; then
            log_info "Installing packages: ${to_install[*]}"
            brew install "${to_install[@]}"
        elif [[ "$OS" = "Linux" ]]; then
            log_info "Installing packages: ${to_install[*]}"
            sudo apt install -y "${to_install[@]}"
        fi
    else
        log_info "All packages are already installed"
    fi
}

# Install cask packages only if not already installed (macOS only)
install_casks() {
    local casks=("$@")
    local to_install=()

    for cask in "${casks[@]}"; do
        if ! is_cask_installed "$cask"; then
            to_install+=("$cask")
        else
            log_info "$cask is already installed, skipping"
        fi
    done

    if [[ ${#to_install[@]} -gt 0 ]]; then
        log_info "Installing casks: ${to_install[*]}"
        brew install --cask "${to_install[@]}"
    else
        log_info "All casks are already installed"
    fi
}

install_mac() {
    log_info "Setting up tools for macOS..."

    # Check for curl
    if ! command -v curl >/dev/null 2>&1; then
        log_error "curl is not installed and is required"
        exit 1
    fi

    # Check for Homebrew, and install if missing
    if ! command -v brew >/dev/null 2>&1; then
        log_info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        # Verify installation
        if ! command -v brew >/dev/null 2>&1; then
            log_error "Homebrew installation failed"
            exit 1
        fi
    else
        log_info "Homebrew is already installed"
    fi

    # Optional: Update Homebrew (make this configurable)
    if [[ "${UPDATE_BREW:-false}" = "true" ]]; then
        log_info "Updating Homebrew..."
        brew update
    fi

    # Install packages
    install_packages "${COMMON_PACKAGES[@]}" "${MAC_SPECIFIC_PACKAGES[@]}"

    # Install cask packages
    if [[ ${#MAC_CASK_PACKAGES[@]} -gt 0 ]]; then
        install_casks "${MAC_CASK_PACKAGES[@]}"
    fi

    log_info "macOS tools installation complete!"
}

install_ubuntu() {
    log_info "Setting up tools for Ubuntu..."

    # Optional: Update packages (make this configurable)
    if [[ "${UPDATE_APT:-false}" = "true" ]]; then
        log_info "Updating package lists and upgrading system..."
        sudo apt update && sudo apt upgrade -y
    fi

    # Install packages
    install_packages "${COMMON_PACKAGES[@]}" "${UBUNTU_SPECIFIC_PACKAGES[@]}"

    # Handle special packages
    install_nvm_ubuntu
    install_pyenv_ubuntu
    install_gh_ubuntu

    log_info "Ubuntu tools installation complete!"
}

# Install nvm (Node Version Manager) - Ubuntu only (macOS uses Homebrew)
install_nvm_ubuntu() {
    if command -v nvm >/dev/null 2>&1; then
        log_info "nvm is already installed"
        return
    fi

    log_info "Installing nvm via script..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
}

# Install pyenv - platform specific
install_pyenv_ubuntu() {
    if command -v pyenv >/dev/null 2>&1; then
        log_info "pyenv is already installed"
        return
    fi

    log_info "Installing pyenv dependencies..."
    sudo apt install -y make build-essential libssl-dev zlib1g-dev \
        libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm \
        libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev \
        libffi-dev liblzma-dev

    log_info "Installing pyenv via script..."
    curl https://pyenv.run | bash
}

# Install GitHub CLI for Ubuntu
install_gh_ubuntu() {
    if command -v gh >/dev/null 2>&1; then
        log_info "GitHub CLI is already installed"
        return
    fi

    log_info "Installing GitHub CLI..."
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
    sudo apt update
    sudo apt install -y gh
}

# Check and manage SSH keys (improved idempotency)
manage_ssh_keys() {
    local key_dir="$HOME/.ssh"
    local default_key_rsa="$key_dir/id_rsa"
    local default_key_ed25519="$key_dir/id_ed25519"

    # Create SSH directory if it doesn't exist
    [[ ! -d "$key_dir" ]] && mkdir -p "$key_dir" && chmod 700 "$key_dir"

    log_info "Checking for existing SSH keys..."

    # Check for existing keys
    local keys_found=false
    if [[ -d "$key_dir" ]]; then
        for key in "$key_dir"/*.pub; do
            if [[ -e "$key" ]]; then
                keys_found=true
                log_info "Found key: $(basename "$key")"
            fi
        done
    fi

    if [[ "$keys_found" = "false" ]]; then
        log_warn "No SSH public keys found"

        # Only prompt if running interactively
        if [[ -t 0 ]]; then
            read -rp "Would you like to create a new SSH key? (y/n): " choice
            case $choice in
            [Yy]*)
                create_ssh_key
                ;;
            *)
                log_info "Skipping SSH key creation"
                ;;
            esac
        else
            log_info "Running non-interactively, skipping SSH key creation"
        fi
    else
        log_info "SSH keys already exist, skipping creation"
    fi
}

create_ssh_key() {
    echo "Which type of key would you like to create?"
    select key_type in "Ed25519" "RSA"; do
        case $key_type in
        Ed25519)
            if [[ ! -f "$default_key_ed25519" ]]; then
                ssh-keygen -t ed25519 -f "$default_key_ed25519"
                log_info "Ed25519 SSH key created!"
            else
                log_warn "Ed25519 key already exists at $default_key_ed25519"
            fi
            break
            ;;
        RSA)
            if [[ ! -f "$default_key_rsa" ]]; then
                ssh-keygen -t rsa -b 4096 -f "$default_key_rsa"
                log_info "RSA SSH key created!"
            else
                log_warn "RSA key already exists at $default_key_rsa"
            fi
            break
            ;;
        esac
    done
}

# Install zsh-nvm plugin with improved idempotency
install_zsh_nvm() {
    local ZSH_NVM_DIR="$HOME/.zsh-nvm"
    # Specify the commit to pin zsh-nvm to a specific version
    local ZSH_NVM_COMMIT="745291dcf20686ec421935f1c3f8f3a2918dd106"

    if [[ ! -d "$ZSH_NVM_DIR" ]]; then
        log_info "Cloning zsh-nvm repository..."
        git clone https://github.com/lukechilds/zsh-nvm.git "$ZSH_NVM_DIR"
        cd "$ZSH_NVM_DIR"
        git checkout "$ZSH_NVM_COMMIT"
        cd - >/dev/null
    else
        cd "$ZSH_NVM_DIR"
        local current_commit
        current_commit=$(git rev-parse HEAD)

        if [[ "$current_commit" != "$ZSH_NVM_COMMIT" ]]; then
            log_info "Updating zsh-nvm to pinned commit..."
            git fetch
            git checkout "$ZSH_NVM_COMMIT"
        else
            log_info "zsh-nvm is already at the correct commit"
        fi
        cd - >/dev/null
    fi
}

# Create ~/.config directory if it doesn't exist; this prevents issues with stow
# creating a symlink to the config directory in the first stowed config
function setup_config_directory() {
    local config_dir="$HOME/.config"

    if [ ! -d "$config_dir" ]; then
        echo "Creating $config_dir directory..."
        mkdir -p "$config_dir"
        echo "$config_dir directory created!"
    else
        echo "$config_dir directory already exists."
    fi
}

# Main function
main() {
    log_info "Starting system setup..."

    case "$OS" in
    Darwin)
        install_mac
        ;;
    Linux)
        if grep -q 'Ubuntu' /etc/os-release 2>/dev/null; then
            install_ubuntu
        else
            log_error "Unsupported Linux distribution. This script currently supports Ubuntu."
            exit 1
        fi
        ;;
    *)
        log_error "Unsupported OS: $OS"
        exit 1
        ;;
    esac

    # Common post-installation tasks
    setup_config_directory
    install_zsh_nvm
    manage_ssh_keys

    log_info "Setup complete! 🎉"
}

# Handle script arguments
while [[ $# -gt 0 ]]; do
    case $1 in
    --update-brew)
        export UPDATE_BREW=true
        shift
        ;;
    --update-apt)
        export UPDATE_APT=true
        shift
        ;;
    --help)
        echo "Usage: $0 [options]"
        echo "Options:"
        echo "  --update-brew    Update Homebrew before installing packages"
        echo "  --update-apt     Update APT packages before installing"
        echo "  --help          Show this help message"
        exit 0
        ;;
    *)
        log_error "Unknown option: $1"
        exit 1
        ;;
    esac
done

main "$@"
