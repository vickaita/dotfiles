#!/bin/bash
# Script to generate Catppuccin atuin theme files using environment variables
# This ensures consistency across all themes

# Source the color definitions
source "$(dirname "$0")/catppuccin-colors.sh"

THEME_DIR="${1:-$HOME/.config/atuin/themes}"

# Create themes directory if it doesn't exist
mkdir -p "$THEME_DIR"

# Function to generate theme file
generate_theme() {
    local accent_color="$1"
    local accent_name="$2"
    local theme_file="$THEME_DIR/catppuccin-mocha-${accent_name}.toml"

    cat >"$theme_file" <<EOF
# Catppuccin Mocha theme for Atuin (${accent_name} accent)
# Based on Catppuccin themes: https://github.com/catppuccin/atuin
# Copyright (c) 2021 Catppuccin
# Licensed under the MIT License

[theme]
name = "catppuccin-mocha-${accent_name}"

[colors]
AlertInfo = "${CATPPUCCIN_GREEN}"
AlertWarn = "${CATPPUCCIN_PEACH}"
AlertError = "${CATPPUCCIN_RED}"
Annotation = "${accent_color}"
Base = "${CATPPUCCIN_TEXT}"
Guidance = "${CATPPUCCIN_OVERLAY2}"
Important = "${CATPPUCCIN_RED}"
Title = "${accent_color}"
EOF
}

# Generate all accent variants
generate_theme "$CATPPUCCIN_ROSEWATER" "rosewater"
generate_theme "$CATPPUCCIN_FLAMINGO" "flamingo"
generate_theme "$CATPPUCCIN_PINK" "pink"
generate_theme "$CATPPUCCIN_MAUVE" "mauve"
generate_theme "$CATPPUCCIN_RED" "red"
generate_theme "$CATPPUCCIN_MAROON" "maroon"
generate_theme "$CATPPUCCIN_PEACH" "peach"
generate_theme "$CATPPUCCIN_YELLOW" "yellow"
generate_theme "$CATPPUCCIN_GREEN" "green"
generate_theme "$CATPPUCCIN_TEAL" "teal"
generate_theme "$CATPPUCCIN_SKY" "sky"
generate_theme "$CATPPUCCIN_SAPPHIRE" "sapphire"
generate_theme "$CATPPUCCIN_BLUE" "blue"
generate_theme "$CATPPUCCIN_LAVENDER" "lavender"

echo "Generated Catppuccin atuin themes in $THEME_DIR"

