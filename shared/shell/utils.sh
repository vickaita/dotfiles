# Adds a segment to the path if it's not already there
prepend_to_path() {
    if [[ ! ":$PATH:" == *":$1:"* ]]; then
        export PATH="$1:$PATH"
    fi
}
