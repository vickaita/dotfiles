#!/bin/bash

# Identify the OS
OS="$(uname)"

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
    nvm
    pyenv
    ripgrep
    shellcheck
    shellharden
    shfmt
    stow
    tmux
    tree
    vim
    wget
)

MAC_SPECIFIC_PACKAGES=(fd gh)

# TODO: Add gh for Ubuntu; I think this might require a PPA
# https://github.com/cli/cli#installation
UBUNTU_SPECIFIC_PACKAGES=(fd-find)

install_mac() {
    echo "Installing tools for MacOS..."

    # Check for curl
    if ! command -v curl >/dev/null; then
        echo "Error: curl is not installed."
        exit 1
    fi

    # Check for Homebrew, and install if missing
    if ! command -v brew >/dev/null; then
        echo "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    # Update Homebrew and install tools
    brew update
    brew install "${COMMON_PACKAGES[@]}" "${MAC_SPECIFIC_PACKAGES[@]}"

    echo "MacOS tools installation complete!"
}

install_ubuntu() {
    echo "Installing tools for Ubuntu..."

    # Update and upgrade packages
    sudo apt update && sudo apt upgrade -y

    # Install tools
    sudo apt install -y "${COMMON_PACKAGES[@]}" "${UBUNTU_SPECIFIC_PACKAGES[@]}"

    echo "Ubuntu tools installation complete!"
}

# Check and manage SSH keys
function manage_ssh_keys() {
    local key_dir="$HOME/.ssh"
    local default_key_rsa="$key_dir/id_rsa"
    local default_key_ed25519="$key_dir/id_ed25519"

    echo "Checking for existing SSH keys..."

    # Check for existing keys in the default location
    local keys_found=false
    for key in "$key_dir"/*.pub; do
        if [[ -e "$key" ]]; then
            keys_found=true
            echo "Key: $(basename "$key")"
        fi
    done

    if [[ "$keys_found" == false ]]; then
        echo "No SSH public keys found in the default location."
    fi

    # Prompt the user for action
    read -pr "Would you like to create a new SSH key? (y/n): " choice

    case $choice in
    [Yy]*)
        # Ask for type of key
        echo "Which type of key would you like to create?"
        select key_type in "Ed25519" "RSA"; do
            case $key_type in
            RSA)
                ssh-keygen -t rsa -b 4096 -f "$default_key_rsa"
                break
                ;;
            Ed25519)
                ssh-keygen -t ed25519 -f "$default_key_ed25519"
                break
                ;;
            esac
        done
        echo "New SSH key created!"
        ;;
    *)
        echo "Skipping SSH key creation."
        ;;
    esac
}

# Create ~/.config directory if it doesn't exist; this prevents issues with stow
# creating a symlink to the config directory in the first stowed config
function setup_config_directory() {
    local config_dir="$HOME/.config"

    if [ ! -d "$config_dir" ]; then
        echo "Creating ~/.config directory..."
        mkdir -p "$config_dir"
        echo "~/.config directory created!"
    else
        echo "~/.config directory already exists."
    fi
}

# Main
function main() {
    setup_config_directory

    if [ "$OS" = "Darwin" ]; then
        install_mac
    elif [ "$OS" = "Linux" ]; then
        # A more detailed check for Ubuntu, just as an example
        if grep -q 'Ubuntu' /etc/os-release; then
            install_ubuntu
        else
            echo "Unsupported Linux distribution. The script currently supports Ubuntu."
            exit 1
        fi
    else
        echo "Unsupported OS."
        exit 1
    fi

    manage_ssh_keys
}

# Execute the main function
main
