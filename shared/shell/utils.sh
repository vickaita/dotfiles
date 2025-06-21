# Adds a segment to the path if it's not already there
prepend_to_path() {
    if [[ ! ":$PATH:" == *":$1:"* ]]; then
        export PATH="$1:$PATH"
    fi
}

# Adds a segment to the end of the path if it's not already there
append_to_path() {
    if [[ ! ":$PATH:" == *":$1:"* ]]; then
        export PATH="$PATH:$1"
    fi
}
