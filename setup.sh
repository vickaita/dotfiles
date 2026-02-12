#!/bin/bash

# Improved setup script with better idempotency and error handling
set -euo pipefail # Exit on error, undefined vars, pipe failures

# Identify the OS
OS="$(uname)"
# Get absolute path in a portable way (realpath doesn't exist on fresh macOS)
if command -v realpath >/dev/null 2>&1; then
    DOTFILES="$(dirname "$(realpath "$0")")"
else
    DOTFILES="$(cd "$(dirname "$0")" && pwd)"
fi

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

# Path to Brewfile
BREWFILE="$DOTFILES/Brewfile"

# Install Linux build tools required for Homebrew
install_linux_build_tools() {
    log_info "Installing build tools for Homebrew..."

    if command -v apt-get >/dev/null 2>&1; then
        # Debian/Ubuntu
        sudo apt-get update
        sudo apt-get install -y build-essential procps curl file git
    elif command -v dnf >/dev/null 2>&1; then
        # Fedora/CentOS/RHEL
        sudo dnf groupinstall -y "Development Tools"
        sudo dnf install -y procps curl file git
    elif command -v yum >/dev/null 2>&1; then
        # Older CentOS/RHEL
        sudo yum groupinstall -y "Development Tools"
        sudo yum install -y procps curl file git
    elif command -v pacman >/dev/null 2>&1; then
        # Arch Linux
        sudo pacman -S --needed --noconfirm base-devel procps-ng curl file git
    elif command -v zypper >/dev/null 2>&1; then
        # openSUSE
        sudo zypper install -y -t pattern devel_basis
        sudo zypper install -y procps curl file git
    else
        log_warn "Unknown Linux distribution. Please install build tools manually:"
        log_warn "- build-essential/Development Tools"
        log_warn "- procps, curl, file, git"
        return 1
    fi
}

# Universal Homebrew installation for all platforms
install_homebrew() {
    log_info "Setting up Homebrew..."

    # Check for curl
    if ! command -v curl >/dev/null 2>&1; then
        log_error "curl is not installed and is required"
        exit 1
    fi

    # Check for Homebrew, and install if missing
    if ! command -v brew >/dev/null 2>&1; then
        # On Linux, install build tools first
        if [[ "$OS" = "Linux" ]]; then
            install_linux_build_tools
        fi

        log_info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        # Source Homebrew environment
        if [[ "$OS" = "Darwin" ]]; then
            if [[ -x "/opt/homebrew/bin/brew" ]]; then
                eval "$(/opt/homebrew/bin/brew shellenv)"
            elif [[ -x "/usr/local/bin/brew" ]]; then
                eval "$(/usr/local/bin/brew shellenv)"
            fi
        else
            # Linux
            eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
        fi

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

    # Install packages from Brewfile
    if [[ -f "$BREWFILE" ]]; then
        log_info "Installing packages from Brewfile..."
        brew bundle --file="$BREWFILE"
        log_info "Package installation complete!"
    else
        log_error "Brewfile not found at $BREWFILE"
        exit 1
    fi

    # Setup global language versions
    setup_global_languages
}

# Setup global language versions using mise configuration
setup_global_languages() {
    if ! command -v mise >/dev/null 2>&1; then
        log_warn "mise not found, skipping language setup"
        return
    fi

    log_info "Installing languages defined in mise configuration..."

    # Install all tools defined in mise config files (including stowed config.toml)
    if mise install; then
        log_info "Languages installed successfully"

        # Show installed versions
        log_info "Installed language versions:"
        if command -v node >/dev/null 2>&1 || mise which node >/dev/null 2>&1; then
            local node_version
            node_version=$(mise exec -- node --version 2>/dev/null || echo "not available")
            log_info "  Node.js: $node_version"
        fi

        if command -v python >/dev/null 2>&1 || mise which python >/dev/null 2>&1; then
            local python_version
            python_version=$(mise exec -- python --version 2>/dev/null || echo "not available")
            log_info "  Python: $python_version"
        fi

        if command -v ruby >/dev/null 2>&1 || mise which ruby >/dev/null 2>&1; then
            local ruby_version
            ruby_version=$(mise exec -- ruby --version 2>/dev/null | cut -d' ' -f2 || echo "not available")
            log_info "  Ruby: $ruby_version"
        fi
    else
        log_error "Failed to install languages from mise configuration"
    fi
}

# Check and manage SSH keys
manage_ssh_keys() {
    local key_dir="$HOME/.ssh"
    local default_key_rsa="$key_dir/id_rsa"
    local default_key_ed25519="$key_dir/id_ed25519"
    local ssh_config="$key_dir/config"

    # Create SSH directory if it doesn't exist
    [[ ! -d "$key_dir" ]] && mkdir -p "$key_dir" && chmod 700 "$key_dir"

    log_info "Checking for existing SSH keys..."

    # Check for existing keys
    local keys_found=false
    if [[ -d "$key_dir" ]]; then
        local pub_keys
        pub_keys=$(find "$key_dir" -maxdepth 1 -name '*.pub' -print 2>/dev/null)
        if [[ -n "$pub_keys" ]]; then
            keys_found=true
            while IFS= read -r key; do
                log_info "Found key: $(basename "$key")"
            done <<<"$pub_keys"
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
        setup_ssh_agent_integration
    fi

    # Always ensure SSH config is properly set up
    setup_ssh_config
}

create_ssh_key() {
    local email
    read -rp "Enter your email for the SSH key: " email

    echo "Which type of key would you like to create?"
    select key_type in "Ed25519" "RSA"; do
        case $key_type in
        Ed25519)
            if [[ ! -f "$default_key_ed25519" ]]; then
                ssh-keygen -t ed25519 -C "$email" -f "$default_key_ed25519"
                log_info "Ed25519 SSH key created!"
                setup_ssh_agent_integration
            else
                log_warn "Ed25519 key already exists at $default_key_ed25519"
            fi
            break
            ;;
        RSA)
            if [[ ! -f "$default_key_rsa" ]]; then
                ssh-keygen -t rsa -b 4096 -C "$email" -f "$default_key_rsa"
                log_info "RSA SSH key created!"
                setup_ssh_agent_integration
            else
                log_warn "RSA key already exists at $default_key_rsa"
            fi
            break
            ;;
        esac
    done
}

# Set up SSH agent integration with platform-specific optimizations
setup_ssh_agent_integration() {
    local key_dir="$HOME/.ssh"

    log_info "Setting up SSH agent integration..."

    # Find SSH keys to add
    local keys_to_add=()
    [[ -f "$key_dir/id_ed25519" ]] && keys_to_add+=("$key_dir/id_ed25519")
    [[ -f "$key_dir/id_rsa" ]] && keys_to_add+=("$key_dir/id_rsa")

    if [[ ${#keys_to_add[@]} -eq 0 ]]; then
        log_warn "No SSH keys found to add to agent"
        return
    fi

    # Platform-specific setup
    case "$OS" in
    Darwin)
        log_info "Setting up macOS Keychain integration..."
        # Add keys to macOS Keychain
        for key in "${keys_to_add[@]}"; do
            if ssh-add --apple-use-keychain "$key" 2>/dev/null; then
                log_info "Added $(basename "$key") to macOS Keychain"
            else
                log_warn "Failed to add $(basename "$key") to Keychain (may need passphrase)"
            fi
        done
        ;;
    Linux)
        log_info "Setting up SSH agent for Linux..."
        # Start ssh-agent if not already running
        if [[ -z "${SSH_AUTH_SOCK:-}" ]]; then
            eval "$(ssh-agent -s)" >/dev/null 2>&1
        fi

        # Add keys to agent
        for key in "${keys_to_add[@]}"; do
            if ssh-add "$key" 2>/dev/null; then
                log_info "Added $(basename "$key") to SSH agent"
            else
                log_warn "Failed to add $(basename "$key") to agent (may need passphrase)"
            fi
        done
        ;;
    esac
}

# Set up SSH config with best practices
setup_ssh_config() {
    local ssh_config="$HOME/.ssh/config"
    local config_updated=false

    log_info "Configuring SSH client settings..."

    # Create config file if it doesn't exist
    if [[ ! -f "$ssh_config" ]]; then
        touch "$ssh_config"
        chmod 600 "$ssh_config"
    fi

    # Check if our config block already exists
    if ! grep -q "# Dotfiles SSH Configuration" "$ssh_config"; then
        log_info "Adding SSH configuration optimizations..."

        # Platform-specific configuration
        case "$OS" in
        Darwin)
            cat >>"$ssh_config" <<'EOF'

# Dotfiles SSH Configuration - macOS optimized
Host *
    # Use macOS Keychain for key management
    AddKeysToAgent yes
    UseKeychain yes

    # Security and performance optimizations
    IdentitiesOnly yes
    HashKnownHosts yes

    # Connection optimizations
    ServerAliveInterval 60
    ServerAliveCountMax 3

    # Preferred key algorithms (modern only; excludes deprecated ssh-rsa)
    PubkeyAcceptedKeyTypes ssh-ed25519,sk-ssh-ed25519@openssh.com,ecdsa-sha2-nistp256,sk-ecdsa-sha2-nistp256@openssh.com,ecdsa-sha2-nistp384
EOF
            ;;
        Linux)
            cat >>"$ssh_config" <<'EOF'

# Dotfiles SSH Configuration - Linux optimized
Host *
    # Use SSH agent for key management
    AddKeysToAgent yes

    # Security and performance optimizations
    IdentitiesOnly yes
    HashKnownHosts yes

    # Connection optimizations
    ServerAliveInterval 60
    ServerAliveCountMax 3

    # Preferred key algorithms (modern only; excludes deprecated ssh-rsa)
    PubkeyAcceptedKeyTypes ssh-ed25519,sk-ssh-ed25519@openssh.com,ecdsa-sha2-nistp256,sk-ecdsa-sha2-nistp256@openssh.com,ecdsa-sha2-nistp384
EOF
            ;;
        esac

        config_updated=true
    fi

    if [[ "$config_updated" = "true" ]]; then
        log_info "SSH configuration updated with security optimizations"
    else
        log_info "SSH configuration already contains dotfiles settings"
    fi
}

# Create ~/.config directory if it doesn't exist; this prevents issues with
# stow creating a symlink to the config directory in the first stowed config
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

    # Find all .erb files in templates directory (using portable method)
    local erb_files
    erb_files=$(find "$templates_dir" -name "*.erb" -type f -print 2>/dev/null)

    if [[ -n "$erb_files" ]]; then
        while IFS= read -r template_file; do
            [[ -z "$template_file" ]] && continue

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
        done <<<"$erb_files"
    fi

    log_info "Template processing complete!"
}

# Stow all configuration directories
stow_configs() {
    local dotfiles_dir
    # Get absolute path in a portable way
    if command -v realpath >/dev/null 2>&1; then
        dotfiles_dir="$(dirname "$(realpath "$0")")"
    else
        dotfiles_dir="$(cd "$(dirname "$0")" && pwd)"
    fi

    # List of directories to stow
    # Include all configured modules present in this repo
    local stow_dirs=(
        "atuin"
        "bash"
        "bat"
        "git"
        "ghostty"
        "htop"
        "jj"
        "lazygit"
        "mise"
        "nvim"
        "prettier"
        "tmux"
        "vim"
        "zellij"
        "agents"
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

# Trust mise configuration files
trust_mise_configs() {
    if command -v mise >/dev/null 2>&1; then
        local configs=()

        if [[ -f "$DOTFILES/mise.toml" ]]; then
            configs+=("$DOTFILES/mise.toml")
        fi

        if [[ -d "$DOTFILES/mise" ]]; then
            local toml_files
            toml_files=$(find "$DOTFILES/mise" -name '*.toml' -print 2>/dev/null)
            if [[ -n "$toml_files" ]]; then
                while IFS= read -r file; do
                    [[ -z "$file" ]] && continue
                    configs+=("$file")
                done <<<"$toml_files"
            fi
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

    # Package installation via universal Homebrew
    if [[ "${SKIP_PACKAGES:-false}" != "true" ]]; then
        case "$OS" in
        Darwin)
            log_info "Detected macOS"
            install_homebrew
            ;;
        Linux)
            log_info "Detected Linux"
            install_homebrew
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
