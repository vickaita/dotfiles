#!/bin/bash

# Improved setup script with better idempotency and error handling
set -euo pipefail # Exit on error, undefined vars, pipe failures

# Identify the OS
OS="$(uname)"
DOTFILES="$(dirname "$(realpath "$0")")"

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
    gnupg
    htop
    jq
    lazygit
    lesspipe
    lynx
    neovim
    ripgrep
    shellcheck
    shellharden
    shfmt
    stow
    tmux
    tmuxinator
    tree
    uv
    vim
    w3m
    wget
    zellij
)

MAC_SPECIFIC_PACKAGES=(fd gh mise difftastic tpm)
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

    # Setup Node.js LTS
    setup_nodejs_lts

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
    install_mise_ubuntu
    install_gh_ubuntu
    install_difftastic_ubuntu
    install_tmux_plugin_manager_ubuntu

    # Setup Node.js LTS
    setup_nodejs_lts

    log_info "Ubuntu tools installation complete!"
}

# Install mise (polyglot tool version manager) - Ubuntu only (macOS uses Homebrew)
install_mise_ubuntu() {
    if command -v mise >/dev/null 2>&1; then
        log_info "mise is already installed"
        return
    fi

    log_info "Installing mise via script..."

    local tmp_dir
    tmp_dir=$(mktemp -d)
    local sig_file="$tmp_dir/install.sh.sig"
    local installer="$tmp_dir/install.sh"
    local mise_gpg_fingerprint="24853EC9F655CE80B48E6C3A8B81C9D17413A06D"

    # Import mise GPG key if missing
    if ! gpg --list-keys "$mise_gpg_fingerprint" >/dev/null 2>&1; then
        if ! curl -fsSL https://github.com/jdx.gpg | gpg --import >/dev/null 2>&1; then
            log_error "Failed to import mise GPG key"
            rm -rf "$tmp_dir"
            return 1
        fi
    fi

    if ! curl -fsSL https://github.com/jdx/mise/releases/latest/download/install.sh.sig -o "$sig_file"; then
        log_error "Failed to download mise installer signature"
        rm -rf "$tmp_dir"
        return 1
    fi

    if ! gpg --decrypt "$sig_file" > "$installer" 2>/dev/null; then
        log_error "Mise installer signature verification failed"
        rm -rf "$tmp_dir"
        return 1
    fi

    if ! sh "$installer"; then
        log_error "Mise installation script failed"
        rm -rf "$tmp_dir"
        return 1
    fi

    rm -rf "$tmp_dir"
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

# Install difftastic for Ubuntu
install_difftastic_ubuntu() {
    if command -v difft >/dev/null 2>&1; then
        log_info "difftastic is already installed"
        return
    fi

    log_info "Installing difftastic via snap..."
    sudo snap install difftastic
}

# Setup Node.js LTS using mise
setup_nodejs_lts() {
    if ! command -v mise >/dev/null 2>&1; then
        log_warn "mise not found, skipping Node.js setup"
        return
    fi

    log_info "Setting up Node.js LTS via mise..."

    # Install the latest LTS version and set as global default
    if mise install node@lts && mise use -g node@lts; then
        log_info "Node.js LTS installed and set as global default"

        # Verify installation
        if mise exec -- node --version >/dev/null 2>&1; then
            local node_version
            node_version=$(mise exec -- node --version)
            log_info "Node.js version: $node_version"
        fi
    else
        log_error "Failed to install Node.js LTS"
    fi
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
        mapfile -t pub_keys < <(find "$key_dir" -maxdepth 1 -name '*.pub' -print)
        if [[ ${#pub_keys[@]} -gt 0 ]]; then
            keys_found=true
            for key in "${pub_keys[@]}"; do
                log_info "Found key: $(basename "$key")"
            done
        fi
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

# Process ERB template with environment variables
process_erb_template() {
    local template_file="$1"
    local output_file="$2"

    if command -v erb >/dev/null 2>&1; then
        erb "$template_file" >"$output_file"
    else
        log_warn "ERB not available, copying template as-is"
        cp "$template_file" "$output_file"
    fi
}

# Create local configuration files from ERB templates
create_local_configs() {
    local templates_dir
    templates_dir="$(dirname "$0")/templates"

    if [[ ! -d "$templates_dir" ]]; then
        log_warn "Templates directory not found at $templates_dir"
        return
    fi

    log_info "Processing configuration templates from $templates_dir..."

    # Find all .erb files in templates directory
    while IFS= read -r -d '' template_file; do
        local template_name
        template_name="$(basename "$template_file")"

        # Remove .erb extension to get target filename
        local target_name="${template_name%.erb}"
        local target_path="$HOME/$target_name"

        # Check if target file already exists
        if [[ -f "$target_path" ]]; then
            log_info "$target_name already exists at $target_path, skipping"
            continue
        fi

        log_info "Creating $target_name from ERB template..."
        process_erb_template "$template_file" "$target_path"

        # Special handling for gitconfig.local
        if [[ "$target_name" == ".gitconfig.local" ]] && [[ -z "${GIT_EMAIL:-}" ]]; then
            log_warn "Set GIT_EMAIL environment variable or edit ~/.gitconfig.local manually"
        fi

    done < <(find "$templates_dir" -name "*.erb" -type f -print0)

    log_info "Template processing complete!"
}

# Stow all configuration directories
stow_configs() {
    local dotfiles_dir
    dotfiles_dir="$(dirname "$(realpath "$0")")"

    # List of directories to stow
    local stow_dirs=(
        "bash"
        "ghostty"
        "htop"
        "mise"
        "nvim"
        "prettier"
        "tmux"
        "vim"
        "zsh"
    )

    log_info "Stowing configuration files from $dotfiles_dir..."

    for dir_name in "${stow_dirs[@]}"; do
        local dir_path="$dotfiles_dir/$dir_name"

        # Check if directory exists
        if [[ ! -d "$dir_path" ]]; then
            log_warn "Directory $dir_name not found, skipping"
            continue
        fi

        # Check if stow would conflict
        if stow -n -d "$dotfiles_dir" -t "$HOME" "$dir_name" 2>/dev/null; then
            log_info "Stowing $dir_name..."
            stow -d "$dotfiles_dir" -t "$HOME" "$dir_name"
        else
            log_warn "Conflicts detected for $dir_name, skipping. Run 'stow -d $dotfiles_dir -t $HOME $dir_name' manually to see details."
        fi
    done

    log_info "Stowing complete!"
}

# Install TMux Plugin Manager (Ubuntu only - macOS uses homebrew tpm package)
install_tmux_plugin_manager_ubuntu() {
    local tpm_dir="$HOME/.tmux/plugins/tpm"

    if [[ -d "$tpm_dir" ]]; then
        log_info "TMux Plugin Manager already installed at $tpm_dir"
        return
    fi

    if ! command -v tmux >/dev/null 2>&1; then
        log_warn "tmux not found, skipping TMux Plugin Manager installation"
        return
    fi

    if ! command -v git >/dev/null 2>&1; then
        log_warn "git not found, skipping TMux Plugin Manager installation"
        return
    fi

    log_info "Installing TMux Plugin Manager for Ubuntu..."

    # Create .tmux/plugins directory if it doesn't exist
    mkdir -p "$(dirname "$tpm_dir")"

    if git clone https://github.com/tmux-plugins/tpm "$tpm_dir"; then
        log_info "TMux Plugin Manager installed successfully to $tpm_dir"
    else
        log_error "Failed to install TMux Plugin Manager"
    fi
}

# Trust mise configuration files
trust_mise_configs() {
    if command -v mise >/dev/null 2>&1; then
        local configs=()

        if [[ -f "$DOTFILES/mise.toml" ]]; then
            configs+=("$DOTFILES/mise.toml")
        fi

        if [[ -d "$DOTFILES/mise" ]]; then
            while IFS= read -r -d '' file; do
                configs+=("$file")
            done < <(find "$DOTFILES/mise" -name '*.toml' -print0)
        fi

        if [[ ${#configs[@]} -gt 0 ]]; then
            log_info "Trusting mise configuration files..."
            for config in "${configs[@]}"; do
                mise trust --yes "$config"
            done
        fi
    else
        log_warn "mise not installed; skipping mise trust step"
    fi
}

# Main function
main() {
    log_info "Starting system setup..."

    # Package installation
    if [[ "${SKIP_PACKAGES:-false}" != "true" ]]; then
        case "$OS" in
        Darwin)
            log_info "Detected macOS"
            install_mac
            ;;
        Linux)
            if grep -q 'Ubuntu' /etc/os-release 2>/dev/null; then
                log_info "Detected Ubuntu"
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
    else
        log_info "Skipping package installation (--skip-packages)"
    fi

    # Trust mise configuration files
    trust_mise_configs

    # Common post-installation tasks
    if [[ "${SKIP_CONFIGS:-false}" != "true" ]]; then
        setup_config_directory
    else
        log_info "Skipping config directory setup (--skip-configs)"
    fi

    if [[ "${SKIP_TEMPLATES:-false}" != "true" ]]; then
        create_local_configs
    else
        log_info "Skipping template processing (--skip-templates)"
    fi

    if [[ "${SKIP_SSH:-false}" != "true" ]]; then
        manage_ssh_keys
    else
        log_info "Skipping SSH key management (--skip-ssh)"
    fi

    if [[ "${SKIP_STOW:-false}" != "true" ]]; then
        stow_configs
    else
        log_info "Skipping stowing configuration files (--skip-stow)"
    fi

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
    --skip-packages)
        export SKIP_PACKAGES=true
        shift
        ;;
    --skip-configs)
        export SKIP_CONFIGS=true
        shift
        ;;
    --skip-templates)
        export SKIP_TEMPLATES=true
        shift
        ;;
    --skip-ssh)
        export SKIP_SSH=true
        shift
        ;;
    --skip-stow)
        export SKIP_STOW=true
        shift
        ;;
    --help)
        echo "Usage: $0 [options]"
        echo "Options:"
        echo "  --update-brew      Update Homebrew before installing packages"
        echo "  --update-apt       Update APT packages before installing"
        echo "  --skip-packages    Skip package installation"
        echo "  --skip-configs     Skip config directory setup"
        echo "  --skip-templates   Skip template processing"
        echo "  --skip-ssh         Skip SSH key management"
        echo "  --skip-stow        Skip stowing configuration files"
        echo "  --help             Show this help message"
        exit 0
        ;;
    *)
        log_error "Unknown option: $1"
        exit 1
        ;;
    esac
done

main "$@"
