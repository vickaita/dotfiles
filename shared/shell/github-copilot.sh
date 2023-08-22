# check to see if github-copilot-cli is installed

if command -v github-copilot-cli &>/dev/null; then
    eval "$(github-copilot-cli alias -- "$0")"
else
    echo "github-copilot-cli could not be found"
fi
