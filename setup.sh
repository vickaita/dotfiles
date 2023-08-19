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

MAC_SPECIFIC_PACKAGES=(fd)

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

# Main
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
