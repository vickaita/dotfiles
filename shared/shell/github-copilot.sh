# check to see if gitub-copilot-cli is installed

if ! command -v github-copilot-cli &> /dev/null
then
    echo "github-copilot-cli could not be found"
    exit
fi

eval "$(github-copilot-cli alias -- "$0")"
