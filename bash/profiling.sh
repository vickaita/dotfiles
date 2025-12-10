# Bash profiling utilities for timing shell startup

# Initialize associative arrays for detailed file profiling
declare -A _bash_file_times
declare -a _bash_file_order

# Get current time in nanoseconds (or fallback to milliseconds)
_get_time_ns() {
    # Try nanosecond precision first (Linux, modern macOS)
    if date +%s%N 2>/dev/null | grep -q N; then
        # %N not supported, use milliseconds
        echo $(($(date +%s) * 1000000000))
    else
        date +%s%N
    fi
}

# Timing wrapper that decorates the base safe_source function
timing_wrapper() {
    local original_source_func="$1"
    local file="$2"

    # Start timing
    local start_time=$(_get_time_ns)

    # Call the original safe_source function (handles file checking and sourcing)
    $original_source_func "$file"

    # Only store timing if file was actually sourced (file exists)
    if [[ -f "$file" ]]; then
        local end_time=$(_get_time_ns)

        # Calculate duration in nanoseconds, then convert to tenths of milliseconds
        local duration_ns=$((end_time - start_time))
        local duration_tenths=$((duration_ns / 100000))

        # Store timing info
        _bash_file_times["$file"]=$duration_tenths
        _bash_file_order+=("$file")
    fi
}

# Function to display file timing results
_show_file_times() {
    # Create array of file:time pairs for sorting
    local -a sorted_files=()
    local total_time=0

    # Collect all files and their times
    for file in "${!_bash_file_times[@]}"; do
        local time_tenths=${_bash_file_times[$file]}
        total_time=$((total_time + time_tenths))
        sorted_files+=("${time_tenths}:${file}")
    done

    # Sort by time (descending) - using sort command since bash doesn't have built-in numeric sort
    local IFS=$'\n'
    local sorted=($(printf '%s\n' "${sorted_files[@]}" | sort -t: -k1 -rn))

    # Display sorted results
    for entry in "${sorted[@]}"; do
        local time_tenths=${entry%%:*}
        local file=${entry#*:}

        # Remove any quotes from the file path and extract filename for display
        local clean_file=${file//\"/}
        local display_name=${clean_file#$DOTFILES/}
        if [[ "$display_name" == "$clean_file" ]]; then
            # If not under DOTFILES, show just basename
            display_name=${clean_file##*/}
        fi

        # Convert tenths back to decimal milliseconds for display
        local time_ms=$(awk "BEGIN {printf \"%.1f\", $time_tenths / 10.0}")
        printf "  %6sms  %s\n" "$time_ms" "$display_name"
    done

    local total_ms=$(awk "BEGIN {printf \"%.1f\", $total_time / 10.0}")
    printf "\nTotal: %sms across %d files\n" "$total_ms" "${#_bash_file_order[@]}"
}
