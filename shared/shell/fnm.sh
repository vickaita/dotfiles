# fnm_setup.sh - Fast Node Manager (Rust-based, much faster than NVM)

# Initialize fnm if it's installed
if command -v fnm >/dev/null 2>&1; then
    # Initialize fnm with automatic version switching on directory change
    eval "$(fnm env --use-on-cd --shell $CURRENT_SHELL)"
else
    echo "Warning: fnm not found. Run 'curl -fsSL https://fnm.vercel.app/install | bash' to install."
fi