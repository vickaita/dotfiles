# Zsh profiling utilities for timing shell startup

# Initialize timing arrays for detailed file profiling
typeset -A _zsh_file_times
typeset -a _zsh_file_order

# Timing wrapper that decorates the base _source function
_timing_wrapper() {
  local original_source_func="$1"
  local file="$2"

  # Start timing
  zmodload zsh/datetime
  local start_time=$EPOCHREALTIME

  # Call the original _source function (handles file checking and sourcing)
  $original_source_func "$file"

  # Only store timing if file was actually sourced (file exists)
  if [[ -f "$file" ]]; then
    local end_time=$EPOCHREALTIME

    # Calculate duration in milliseconds (multiply by 1000)
    # Use awk for reliable floating point math, store as integer tenths of ms
    local duration_tenths=$(awk "BEGIN {printf \"%.0f\", ($end_time - $start_time) * 10000}" 2>/dev/null || echo "10")

    # Store timing info as integer
    _zsh_file_times["$file"]=$duration_tenths
    _zsh_file_order+=("$file")
  fi
}

# Function to display file timing results
_show_file_times() {
  # Create array of file:time pairs for sorting
  local -a sorted_files
  local total_time=0

  # Use the keys from the associative array directly
  for file in "${(@k)_zsh_file_times}"; do
    local time_tenths=${_zsh_file_times[$file]}
    total_time=$(( total_time + time_tenths ))
    sorted_files+=("${time_tenths}:${file}")
  done

  # Sort by time (descending) and display
  for entry in ${(On)sorted_files}; do
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
    local time_ms=$(( time_tenths / 10.0 ))
    printf "  %6.1fms  %s\n" $time_ms "$display_name"
  done

  local total_ms=$(( total_time / 10.0 ))
  printf "\nTotal: %.1fms across %d files\n" $total_ms ${#_zsh_file_order}
}
