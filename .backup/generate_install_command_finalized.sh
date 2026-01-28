#!/usr/bin/env bash

set -euo pipefail

# Help section to describe the script
show_help() {
    cat << EOF
Usage: ./generate_install_command_revised.sh

This script processes text files containing package names and generates
corresponding shell scripts with installation commands.

Steps performed:
1. Searches for input files matching the pattern output_*.txt or output.txt.
2. Extracts package names from these files.
3. Generates a corresponding shell script for each input file with the appropriate installation command.
4. Skips files that already have a corresponding shell script.

Generated scripts:
- For output_*.txt, generates output_*.sh.
- For output.txt, generates result.sh.

Error Handling:
- If no input files are found, the script exits with a message.
- If input files are found but no packages are detected, an informational shell script is created.

Prerequisites:
- The input files should be in the correct format with optional dependency lines.
- Ensure you have the required permissions to create and modify files.

EOF
}

# Function to extract package names from the input file
extract_packages() {
    local input_file="$1"
    # Extract optional dependency package names
    grep -E "^\s+[^[:space:]]+:" "$input_file" | 
    sed -E 's/^\s+([^[:space:]]+):.*/\1/' |
    sort | uniq
}

main() {
    # Enable nullglob so patterns expand to empty lists if no match
    shopt -s nullglob

    # Find all output_n.txt files
    files=( ./output_*.txt )

    # If no output_n.txt are found, check for a lone output.txt
    if (( ${#files[@]} == 1 )) && [[ ${files[0]} == "./output_*.txt" ]]; then
        # Means no files matched
        files=()
    fi

    if (( ${#files[@]} == 0 )) && [[ -f "./output.txt" ]]; then
        files=( "./output.txt" )
    fi

    # Disable nullglob
    shopt -u nullglob

    # If no input files are found, display help and exit
    if (( ${#files[@]} == 0 )); then
        echo "Error: No input files found. Please ensure files match the pattern output_*.txt or output.txt."
        show_help
        exit 1
    fi

    # Filter out files that already have a corresponding .sh file
    # If the file is output_n.txt, corresponding script is output_n.sh
    # If the file is output.txt, corresponding script is result.sh
    new_files=()
    for f in "${files[@]}"; do
        if [[ "$f" == "./output.txt" ]]; then
            ofile="./result.sh"
        else
            ofile="${f%.txt}.sh"
        fi

        # Only add to new_files if .sh does not exist
        if [[ ! -f "$ofile" ]]; then
            new_files+=("$f")
        fi
    done

    if (( ${#new_files[@]} == 0 )); then
        echo "All files have already been processed."
        exit 0
    fi

    # Process each new file
    for f in "${new_files[@]}"; do
        if [[ "$f" == "./output.txt" ]]; then
            ofile="./result.sh"
        else
            ofile="${f%.txt}.sh"
        fi

        packages=$(extract_packages "$f" | awk '{printf("%s ", $0)}')

        if [[ -z "$packages" ]]; then
            echo "No packages to install for $f."
            echo "#!/bin/bash" > "$ofile"
            echo "echo 'No packages to install.'" >> "$ofile"
        else
            install_command="yay -S $packages --sudoloop --batchinstall --asdeps"
            echo "Processing $f -> $ofile"
            echo "#!/bin/bash" > "$ofile"
            echo "$install_command" >> "$ofile"
        fi

        chmod +x "$ofile"
    done
}

# Check for help flag
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    show_help
    exit 0
fi

main
