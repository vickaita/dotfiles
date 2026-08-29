#!/bin/bash

# Improved setup script with better idempotency and error handling
set -euo pipefail # Exit on error, undefined vars, pipe failures

# Identify the OS
OS="$(uname)"
# Get absolute path in a portable way (realpath doesn't exist on fresh macOS)
SETUP_SCRIPT="${BASH_SOURCE[0]}"
if command -v realpath >/dev/null 2>&1; then
    DOTFILES="$(dirname "$(realpath "$SETUP_SCRIPT")")"
else
    DOTFILES="$(cd "$(dirname "$SETUP_SCRIPT")" && pwd)"
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
WORKSTATION_BREWFILE="$DOTFILES/Brewfile.workstation"
PROFILE="workstation"
PROFILE_WAS_SET=false
DRY_RUN=false
UPGRADE_PACKAGES=false
SETUP_SSH=false
VALID_MODULES=(atuin bash bat git ghostty herdr htop jj lazygit mise nvim prettier tmux vim zellij agents cmux zsh)
SKIP_MODULES=()

set_profile() {
    local requested_profile="$1"

    case "$requested_profile" in
        server | workstation) ;;
        *)
            log_error "Unknown profile: $requested_profile (expected server or workstation)"
            exit 1
            ;;
    esac

    if [[ "$PROFILE_WAS_SET" = "true" && "$PROFILE" != "$requested_profile" ]]; then
        log_error "Conflicting profiles requested: $PROFILE and $requested_profile"
        exit 1
    fi

    PROFILE="$requested_profile"
    PROFILE_WAS_SET=true
}

module_is_valid() {
    local requested_module="$1"
    local module_name

    for module_name in "${VALID_MODULES[@]}"; do
        [[ "$module_name" = "$requested_module" ]] && return 0
    done
    return 1
}

module_is_skipped() {
    local requested_module="$1"
    local module_name

    [[ ${#SKIP_MODULES[@]} -eq 0 ]] && return 1

    for module_name in "${SKIP_MODULES[@]}"; do
        [[ "$module_name" = "$requested_module" ]] && return 0
    done
    return 1
}

skip_module() {
    local requested_module="$1"

    if ! module_is_valid "$requested_module"; then
        log_error "Unknown module: $requested_module"
        exit 1
    fi

    if ! module_is_skipped "$requested_module"; then
        SKIP_MODULES+=("$requested_module")
    fi
}

print_dry_run_plan() {
    local modules=(atuin bat git herdr htop jj lazygit mise nvim prettier tmux vim zellij agents bash)
    local selected_modules=()
    local module_name

    if [[ "$PROFILE" = "workstation" ]]; then
        modules+=(zsh ghostty)
        [[ "$OS" = "Darwin" ]] && modules+=(cmux)
    fi

    for module_name in "${modules[@]}"; do
        module_is_skipped "$module_name" || selected_modules+=("$module_name")
    done

    if [[ "${SKIP_PACKAGES:-false}" = "true" ]]; then
        log_info "Package installation is disabled (--skip-packages)"
    else
        log_info "Dry-run package file: $BREWFILE"
        if [[ "$UPGRADE_PACKAGES" = "true" || "${UPDATE_BREW:-false}" = "true" ]]; then
            log_info "Dry-run command: brew update"
        fi
        if [[ "$UPGRADE_PACKAGES" = "true" ]]; then
            log_info "Dry-run command: brew bundle install --upgrade --file=$BREWFILE"
        else
            log_info "Dry-run command: brew bundle install --no-upgrade --file=$BREWFILE"
        fi
        if [[ "$PROFILE" = "workstation" ]]; then
            if [[ "$UPGRADE_PACKAGES" = "true" ]]; then
                log_info "Dry-run command: brew bundle install --upgrade --file=$WORKSTATION_BREWFILE"
            else
                log_info "Dry-run command: brew bundle install --no-upgrade --file=$WORKSTATION_BREWFILE"
            fi
        fi
    fi
    log_info "Dry-run modules: ${selected_modules[*]}"
    if [[ "$SETUP_SSH" = "true" ]]; then
        log_info "Would run SSH key setup"
    else
        log_info "SSH setup is disabled (use --setup-ssh to enable it)"
    fi

    if [[ "${SKIP_CONFIGS:-false}" != "true" ]]; then
        log_info "Would ensure $HOME/.config and $HOME/.config/herdr exist"
        if [[ "${SKIP_STOW:-false}" != "true" ]]; then
            stow_mise_config
        fi
        if [[ "${SKIP_TEMPLATES:-false}" != "true" ]]; then
            create_local_configs
        fi
        configure_bash
        if [[ "${SKIP_STOW:-false}" != "true" ]]; then
            stow_selected_configs
        fi
    fi
}

preflight_system() {
    local effective_uid="${1:-$EUID}"
    local architecture="${2:-$(uname -m)}"
    local operating_system="${3:-$OS}"

    if [[ "$DRY_RUN" != "true" && "$effective_uid" -eq 0 ]]; then
        log_error "Do not run setup as root; use a normal sudo-capable user"
        return 1
    fi

    case "$architecture" in
        x86_64 | amd64 | arm64 | aarch64) ;;
        *)
            log_error "Unsupported architecture: $architecture"
            return 1
            ;;
    esac

    if [[ "$DRY_RUN" != "true" && "$operating_system" = "Linux" ]] && ! command -v sudo >/dev/null 2>&1; then
        log_error "sudo is required for Linux setup"
        return 1
    fi
    if [[ "$DRY_RUN" != "true" && "$operating_system" = "Linux" ]] && ! sudo -v; then
        log_error "sudo authorization failed; setup has not made changes"
        return 1
    fi
}

# Install Linux build tools required for Homebrew
install_linux_build_tools() {
    log_info "Installing build tools for Homebrew..."

    if command -v apt-get >/dev/null 2>&1; then
        # Debian/Ubuntu
        sudo apt-get update || return 1
        sudo apt-get install -y build-essential procps curl file git ca-certificates || return 1
    elif command -v dnf >/dev/null 2>&1; then
        # Fedora/CentOS/RHEL
        if [[ -f /etc/fedora-release ]]; then
            sudo dnf group install -y development-tools || return 1
        else
            sudo dnf group install -y "Development Tools" || return 1
        fi
        sudo dnf install -y procps-ng curl file git ca-certificates || return 1
    elif command -v yum >/dev/null 2>&1; then
        # Older CentOS/RHEL
        sudo yum groupinstall -y "Development Tools" || return 1
        sudo yum install -y procps-ng curl file git ca-certificates || return 1
    elif command -v pacman >/dev/null 2>&1; then
        # Arch Linux
        sudo pacman -S --needed --noconfirm base-devel procps-ng curl file git ca-certificates || return 1
    elif command -v zypper >/dev/null 2>&1; then
        # openSUSE
        sudo zypper install -y -t pattern devel_basis || return 1
        sudo zypper install -y procps curl file git ca-certificates || return 1
    else
        log_warn "Unknown Linux distribution. Please install build tools manually:"
        log_warn "- build-essential/Development Tools"
        log_warn "- procps, curl, file, git"
        return 1
    fi
}

# Universal Homebrew installation for all platforms
activate_homebrew() {
    local brew_candidate
    local candidates=()

    command -v brew >/dev/null 2>&1 && return 0

    if [[ "$OS" = "Darwin" ]]; then
        candidates=(/opt/homebrew/bin/brew /usr/local/bin/brew)
    else
        candidates=(/home/linuxbrew/.linuxbrew/bin/brew "$HOME/.linuxbrew/bin/brew")
    fi

    for brew_candidate in "${candidates[@]}"; do
        if [[ -x "$brew_candidate" ]]; then
            eval "$("$brew_candidate" shellenv)"
            command -v brew >/dev/null 2>&1 && return 0
        fi
    done

    return 1
}

install_brew_bundle() {
    local bundle_file="$1"

    if [[ ! -f "$bundle_file" ]]; then
        log_error "Brewfile not found at $bundle_file"
        return 1
    fi

    log_info "Installing packages from $(basename "$bundle_file")..."
    if [[ "$UPGRADE_PACKAGES" = "true" ]]; then
        brew bundle install --upgrade --file="$bundle_file"
    else
        brew bundle install --no-upgrade --file="$bundle_file"
    fi
}

install_homebrew() {
    log_info "Setting up Homebrew..."

    if ! activate_homebrew; then
        # On Linux, install build tools first
        if [[ "$OS" = "Linux" ]]; then
            install_linux_build_tools || return 1
        fi

        if ! command -v curl >/dev/null 2>&1; then
            log_error "curl is not installed and is required"
            return 1
        fi

        log_info "Installing Homebrew..."
        local installer_script
        if ! installer_script="$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
            log_error "Failed to download the Homebrew installer"
            return 1
        fi
        if ! /bin/bash -c "$installer_script"; then
            log_error "Homebrew installer failed"
            return 1
        fi

        if ! activate_homebrew; then
            log_error "Homebrew installation failed"
            return 1
        fi
    else
        log_info "Homebrew is already installed"
    fi

    if [[ "${UPDATE_BREW:-false}" = "true" || "$UPGRADE_PACKAGES" = "true" ]]; then
        log_info "Updating Homebrew..."
        brew update || return 1
    fi

    install_brew_bundle "$BREWFILE" || return 1
    if [[ "$PROFILE" = "workstation" ]]; then
        install_brew_bundle "$WORKSTATION_BREWFILE" || return 1
    fi
    log_info "Package installation complete!"
}

# Setup global language versions using mise configuration
setup_global_languages() {
    if ! command -v mise >/dev/null 2>&1; then
        log_error "mise not found; cannot install configured languages"
        return 1
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
        return 1
    fi
}

# Check and manage SSH keys
manage_ssh_keys() {
    local key_dir="$HOME/.ssh"

    # Create SSH directory only in the explicit opt-in flow.
    if [[ ! -d "$key_dir" ]]; then
        if ! mkdir -p "$key_dir" || ! chmod 700 "$key_dir"; then
            log_error "Failed to create a secure SSH directory at $key_dir"
            return 1
        fi
    fi

    log_info "Checking for existing SSH keys..."

    # Check for existing keys
    local keys_found=false
    if [[ -d "$key_dir" ]]; then
        local pub_keys
        if ! pub_keys=$(find "$key_dir" -maxdepth 1 -name '*.pub' -print 2>/dev/null); then
            log_error "Failed to inspect SSH public keys in $key_dir"
            return 1
        fi
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

}

create_ssh_key() {
    local email
    local default_key_rsa="$HOME/.ssh/id_rsa"
    local default_key_ed25519="$HOME/.ssh/id_ed25519"
    read -rp "Enter your email for the SSH key: " email

    echo "Which type of key would you like to create?"
    select key_type in "Ed25519" "RSA"; do
        case $key_type in
            Ed25519)
                if [[ ! -f "$default_key_ed25519" ]]; then
                    if ! ssh-keygen -t ed25519 -C "$email" -f "$default_key_ed25519"; then
                        log_error "Failed to create Ed25519 SSH key"
                        return 1
                    fi
                    log_info "Ed25519 SSH key created!"
                    setup_ssh_agent_integration
                else
                    log_warn "Ed25519 key already exists at $default_key_ed25519"
                fi
                break
                ;;
            RSA)
                if [[ ! -f "$default_key_rsa" ]]; then
                    if ! ssh-keygen -t rsa -b 4096 -C "$email" -f "$default_key_rsa"; then
                        log_error "Failed to create RSA SSH key"
                        return 1
                    fi
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
    if [[ -z "${SSH_AUTH_SOCK:-}" ]]; then
        log_warn "No inherited SSH agent is available; skipping ssh-add"
        return 0
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

# Create ~/.config directory if it doesn't exist; this prevents issues with
# stow creating a symlink to the config directory in the first stowed config
function setup_config_directory() {
    local config_dir="$HOME/.config"
    local herdr_config_dir="$config_dir/herdr"

    if [ ! -d "$config_dir" ]; then
        echo "Creating $config_dir directory..."
        if ! mkdir -p "$config_dir"; then
            log_error "Failed to create $config_dir"
            return 1
        fi
        echo "$config_dir directory created!"
    else
        echo "$config_dir directory already exists."
    fi

    # Herdr writes logs and session state next to config.toml, so keep the
    # directory real and only stow the config file into it.
    if [ ! -d "$herdr_config_dir" ]; then
        echo "Creating $herdr_config_dir directory..."
        if ! mkdir -p "$herdr_config_dir"; then
            log_error "Failed to create $herdr_config_dir"
            return 1
        fi
        echo "$herdr_config_dir directory created!"
    else
        echo "$herdr_config_dir directory already exists."
    fi
}

create_backup() {
    local target_file="$1"
    local timestamp
    local backup_file
    local counter=1

    timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
    backup_file="${target_file}.dotfiles-backup.${timestamp}"
    while [[ -e "$backup_file" || -L "$backup_file" ]]; do
        backup_file="${target_file}.dotfiles-backup.${timestamp}.${counter}"
        counter=$((counter + 1))
    done

    if ! cp -p "$target_file" "$backup_file"; then
        log_error "Failed to back up $target_file"
        return 1
    fi
    log_info "Backed up $target_file to $backup_file"
}

managed_target_is_safe() {
    local target_file="$1"
    local managed_source="$2"

    if [[ ! -L "$target_file" ]]; then
        return 0
    fi
    if [[ "$target_file" -ef "$managed_source" ]]; then
        return 0
    fi

    log_error "Refusing to modify unrelated symlink: $target_file"
    return 1
}

write_managed_block() {
    local target_file="$1"
    local managed_source="$2"
    local managed_line="$3"
    local begin_marker="# >>> dotfiles setup >>>"
    local end_marker="# <<< dotfiles setup <<<"
    local begin_count=0
    local end_count=0
    local content_file
    local target_temp

    if ! managed_target_is_safe "$target_file" "$managed_source"; then
        return 1
    fi
    if [[ -L "$target_file" ]]; then
        log_info "$target_file is already linked to the dotfiles repository"
        return 0
    fi

    if [[ "$DRY_RUN" = "true" ]]; then
        log_info "Would add a managed dotfiles include to $target_file"
        return 0
    fi

    if ! content_file="$(mktemp "${TMPDIR:-/tmp}/dotfiles-managed.XXXXXX")"; then
        log_error "Failed to create a temporary file for $target_file"
        return 1
    fi
    if [[ -f "$target_file" ]]; then
        begin_count="$(grep -Fxc "$begin_marker" "$target_file" 2>/dev/null || true)"
        end_count="$(grep -Fxc "$end_marker" "$target_file" 2>/dev/null || true)"

        if [[ "$begin_count" -eq 0 && "$end_count" -eq 0 ]]; then
            if ! cp "$target_file" "$content_file" ||
                ! printf '\n%s\n%s\n%s\n' "$begin_marker" "$managed_line" "$end_marker" >>"$content_file"; then
                rm -f "$content_file"
                log_error "Failed to prepare the managed block for $target_file"
                return 1
            fi
        elif [[ "$begin_count" -eq 1 && "$end_count" -eq 1 ]]; then
            if ! awk -v begin="$begin_marker" -v end="$end_marker" -v line="$managed_line" '
                $0 == begin {
                    if (inside) exit 40
                    inside = 1
                    print begin
                    print line
                    next
                }
                $0 == end {
                    if (!inside) exit 41
                    inside = 0
                    print end
                    next
                }
                !inside { print }
                END { if (inside) exit 42 }
            ' "$target_file" >"$content_file"; then
                rm -f "$content_file"
                log_error "Malformed managed block in $target_file"
                return 1
            fi
        else
            rm -f "$content_file"
            log_error "Malformed managed block in $target_file"
            return 1
        fi

        if cmp -s "$target_file" "$content_file"; then
            rm -f "$content_file"
            log_info "$target_file already contains the current dotfiles include"
            return 0
        fi
    else
        if ! printf '%s\n%s\n%s\n' "$begin_marker" "$managed_line" "$end_marker" >"$content_file"; then
            rm -f "$content_file"
            log_error "Failed to prepare the managed block for $target_file"
            return 1
        fi
    fi

    if ! target_temp="$(mktemp "$(dirname "$target_file")/.dotfiles-managed.XXXXXX")"; then
        rm -f "$content_file"
        log_error "Failed to create an atomic update file for $target_file"
        return 1
    fi
    if [[ -f "$target_file" ]]; then
        if ! cp -p "$target_file" "$target_temp" || ! create_backup "$target_file"; then
            rm -f "$content_file" "$target_temp"
            return 1
        fi
    fi
    if ! cp "$content_file" "$target_temp" || ! mv "$target_temp" "$target_file"; then
        rm -f "$content_file" "$target_temp"
        log_error "Failed to atomically update $target_file"
        return 1
    fi
    rm -f "$content_file"
    log_info "Updated $target_file"
}

configure_bash() {
    local status=0

    if module_is_skipped "bash"; then
        log_info "Skipping bash module"
        return 0
    fi

    managed_target_is_safe "$HOME/.bashrc" "$DOTFILES/bash/.bashrc" || status=1
    managed_target_is_safe "$HOME/.inputrc" "$DOTFILES/bash/.inputrc" || status=1
    if [[ "$status" -ne 0 ]]; then
        log_error "Bash integration is blocked; no Bash or Readline files were changed"
        return 1
    fi

    write_managed_block \
        "$HOME/.bashrc" \
        "$DOTFILES/bash/.bashrc" \
        "source \"$DOTFILES/bash/.bashrc\"" || status=1
    write_managed_block \
        "$HOME/.inputrc" \
        "$DOTFILES/bash/.inputrc" \
        "\$include $DOTFILES/bash/.inputrc" || status=1

    return "$status"
}

# Process ERB template with environment variables
process_erb_template() {
    local template_file="$1"
    local output_file="$2"
    local output_dir
    local render_temp

    if [[ -e "$output_file" || -L "$output_file" ]]; then
        log_info "$(basename "$output_file") already exists at $output_file, skipping"
        return 0
    fi

    if [[ "$DRY_RUN" = "true" ]]; then
        log_info "Would render $(basename "$template_file") to $output_file"
        return 0
    fi

    output_dir="$(dirname "$output_file")"
    if ! render_temp="$(mktemp "$output_dir/.dotfiles-template.XXXXXX")"; then
        log_error "Failed to create a temporary render file for $output_file"
        return 1
    fi

    if ! command -v mise >/dev/null 2>&1 || ! mise exec -- erb "$template_file" >"$render_temp"; then
        rm -f "$render_temp"
        log_error "ERB rendering through mise-managed Ruby failed for $template_file"
        return 1
    fi

    if grep -q '<%' "$render_temp"; then
        rm -f "$render_temp"
        log_error "Unresolved ERB syntax remains in $template_file"
        return 1
    fi

    if [[ "$(basename "$output_file")" = ".gitconfig.local" ]] &&
        ! git config --file "$render_temp" --list >/dev/null; then
        rm -f "$render_temp"
        log_error "Rendered Git configuration is invalid: $template_file"
        return 1
    fi

    if ! mv "$render_temp" "$output_file"; then
        rm -f "$render_temp"
        log_error "Failed to atomically install rendered template at $output_file"
        return 1
    fi
}

# Create local configuration files from ERB templates
create_local_configs() {
    local templates_dir
    local status=0
    templates_dir="$DOTFILES/templates"

    if [[ ! -d "$templates_dir" ]]; then
        log_warn "Templates directory not found at $templates_dir"
        return
    fi

    log_info "Processing configuration templates from $templates_dir..."

    # Find all .erb files in templates directory (using portable method)
    local erb_files
    if ! erb_files=$(find "$templates_dir" -name "*.erb" -type f -print 2>/dev/null); then
        log_error "Failed to enumerate templates in $templates_dir"
        return 1
    fi

    if [[ -n "$erb_files" ]]; then
        while IFS= read -r template_file; do
            [[ -z "$template_file" ]] && continue

            local template_name
            template_name="$(basename "$template_file")"

            # Remove .erb extension to get target filename
            local target_name="${template_name%.erb}"
            local target_path="$HOME/$target_name"

            if [[ "$target_name" = ".zshrc.local" ]] &&
                { [[ "$PROFILE" = "server" ]] || module_is_skipped "zsh"; }; then
                continue
            fi

            # Check if target file already exists
            if [[ -f "$target_path" ]]; then
                log_info "$target_name already exists at $target_path, skipping"
                continue
            fi

            log_info "Creating $target_name from ERB template..."
            if ! process_erb_template "$template_file" "$target_path"; then
                status=1
                continue
            fi

            # Special handling for gitconfig.local
            if [[ "$target_name" == ".gitconfig.local" ]] && [[ -z "${GIT_EMAIL:-}" ]]; then
                log_warn "Set GIT_EMAIL environment variable or edit ~/.gitconfig.local manually"
            fi
        done <<<"$erb_files"
    fi

    log_info "Template processing complete!"
    return "$status"
}

profile_stow_modules() {
    local modules=(atuin bat git herdr htop jj lazygit mise nvim prettier tmux vim zellij agents)
    local module_name

    if [[ "$PROFILE" = "workstation" ]]; then
        modules+=(ghostty zsh)
        [[ "$OS" = "Darwin" ]] && modules+=(cmux)
    fi

    for module_name in "${modules[@]}"; do
        module_is_skipped "$module_name" || printf '%s\n' "$module_name"
    done
}

stow_one_module() {
    local module_name="$1"
    local module_path="$DOTFILES/$module_name"
    local conflict_output

    if [[ ! -d "$module_path" ]]; then
        log_error "Configuration module not found: $module_name"
        return 1
    fi
    if ! command -v stow >/dev/null 2>&1; then
        if [[ "$DRY_RUN" = "true" ]]; then
            log_info "Would stow $module_name (conflict check unavailable until Stow is installed)"
            return 0
        fi
        log_error "GNU Stow is required to deploy configuration modules"
        return 1
    fi

    if ! conflict_output="$(stow -n -v -d "$DOTFILES" -t "$HOME" "$module_name" 2>&1)"; then
        log_error "Stow conflict for $module_name:"
        printf '%s\n' "$conflict_output" >&2
        return 1
    fi

    if [[ "$DRY_RUN" = "true" ]]; then
        log_info "Would stow $module_name"
        return 0
    fi

    log_info "Stowing $module_name..."
    stow -d "$DOTFILES" -t "$HOME" "$module_name"
}

stow_mise_config() {
    if module_is_skipped "mise"; then
        log_info "Skipping mise module"
        return 0
    fi
    stow_one_module mise
}

stow_selected_configs() {
    local module_name
    local status=0
    local failed_modules=""

    while IFS= read -r module_name; do
        [[ -z "$module_name" || "$module_name" = "mise" ]] && continue
        if ! stow_one_module "$module_name"; then
            status=1
            failed_modules="${failed_modules}${failed_modules:+, }${module_name}"
        fi
    done <<<"$(profile_stow_modules)"

    if [[ "$status" -ne 0 ]]; then
        log_error "Configuration modules with conflicts or errors: $failed_modules"
    else
        log_info "Stowing complete!"
    fi
    return "$status"
}

# Trust mise configuration files
trust_mise_configs() {
    local mise_config="$HOME/.config/mise/config.toml"

    if ! command -v mise >/dev/null 2>&1; then
        log_error "mise is required for language setup"
        return 1
    fi
    if [[ ! -f "$mise_config" ]]; then
        log_error "Stowed mise configuration not found at $mise_config"
        return 1
    fi

    log_info "Trusting mise configuration: $mise_config"
    mise trust --yes "$mise_config"
}

# Configure repository-managed git hooks
setup_git_hooks() {
    if ! command -v git >/dev/null 2>&1; then
        log_warn "git not installed; skipping git hook setup"
        return
    fi

    if ! git -C "$DOTFILES" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        log_warn "Not a git repository at $DOTFILES; skipping git hook setup"
        return
    fi

    log_info "Configuring repository git hooks..."
    if ! git -C "$DOTFILES" config core.hooksPath .githooks; then
        log_error "Failed to configure repository git hooks"
        return 1
    fi
    log_info "Git hooks enabled (core.hooksPath=.githooks)"
}

# Main function
main() {
    local configuration_status=0

    log_info "Starting system setup..."
    log_info "Profile: $PROFILE"

    case "$OS" in
        Darwin | Linux) ;;
        *)
            log_error "Unsupported OS: $OS"
            return 1
            ;;
    esac

    if ! preflight_system; then
        log_error "Setup stopped during preflight"
        return 1
    fi

    if [[ "$DRY_RUN" = "true" ]]; then
        if ! print_dry_run_plan; then
            log_error "Dry-run found conflicts or invalid configuration"
            return 1
        fi
        log_info "Dry-run complete; no changes were made"
        return
    fi

    # Package installation via universal Homebrew
    if [[ "${SKIP_PACKAGES:-false}" != "true" ]]; then
        log_info "Detected $OS"
        if ! install_homebrew; then
            log_error "Package installation failed; configuration was not changed"
            return 1
        fi
    else
        log_info "Skipping package installation (--skip-packages)"
    fi

    if [[ "${SKIP_CONFIGS:-false}" = "true" ]]; then
        log_info "Skipping configuration deployment (--skip-configs)"
    else
        if ! setup_config_directory; then
            log_error "Configuration directory setup failed"
            return 1
        fi

        if module_is_skipped "mise"; then
            log_info "Skipping mise module, trust, and language installation"
        else
            if [[ "${SKIP_STOW:-false}" != "true" ]]; then
                stow_mise_config || configuration_status=1
            else
                log_info "Skipping mise stow (--skip-stow)"
            fi

            if [[ "$configuration_status" -eq 0 ]]; then
                trust_mise_configs || configuration_status=1
                if [[ "$configuration_status" -eq 0 ]]; then
                    setup_global_languages || configuration_status=1
                fi
            fi
        fi

        if [[ "${SKIP_TEMPLATES:-false}" != "true" ]]; then
            create_local_configs || configuration_status=1
        else
            log_info "Skipping template processing (--skip-templates)"
        fi

        configure_bash || configuration_status=1

        if [[ "${SKIP_STOW:-false}" != "true" ]]; then
            stow_selected_configs || configuration_status=1
        else
            log_info "Skipping configuration modules (--skip-stow)"
        fi
    fi

    if [[ "$SETUP_SSH" = "true" ]]; then
        if ! manage_ssh_keys; then
            log_error "SSH setup failed"
            return 1
        fi
    else
        log_info "SSH setup is disabled (use --setup-ssh to enable it)"
    fi

    setup_git_hooks || configuration_status=1

    if [[ "$configuration_status" -ne 0 ]]; then
        log_error "Setup completed with configuration errors"
        return 1
    fi

    log_info "Setup complete! 🎉"
}

# Handle script arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --profile)
            if [[ $# -lt 2 ]]; then
                log_error "--profile requires server or workstation"
                exit 1
            fi
            set_profile "$2"
            shift 2
            ;;
        --server)
            set_profile "server"
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --upgrade)
            UPGRADE_PACKAGES=true
            shift
            ;;
        --setup-ssh)
            SETUP_SSH=true
            shift
            ;;
        --skip-module)
            if [[ $# -lt 2 ]]; then
                log_error "--skip-module requires a module name"
                exit 1
            fi
            skip_module "$2"
            shift 2
            ;;
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
            SETUP_SSH=false
            shift
            ;;
        --skip-stow)
            export SKIP_STOW=true
            shift
            ;;
        --help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --profile server|workstation  Select a profile (default: workstation)"
            echo "  --server                      Alias for --profile server"
            echo "  --dry-run                     Preview setup without making changes"
            echo "  --upgrade                     Update Homebrew and upgrade bundle dependencies"
            echo "  --setup-ssh                   Opt in to SSH key setup"
            echo "  --skip-module NAME            Skip a configuration module (repeatable)"
            echo "  --update-brew                 Update Homebrew metadata without upgrading packages"
            echo "  --skip-packages               Skip package installation"
            echo "  --skip-configs                Skip directories, mise, templates, Bash, and Stow"
            echo "  --skip-templates              Skip only template processing"
            echo "  --skip-ssh                    Compatibility alias for the default SSH behavior"
            echo "  --skip-stow                   Skip only Stow configuration deployment"
            echo "  --help                        Show this help message"
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
