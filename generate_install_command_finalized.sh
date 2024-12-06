#!/usr/bin/env bash

set -euo pipefail

extract_packages() {
    local input_file="$1"
    # Extract optional dependency package names:
    # lines start with spaces, followed by a token ending in ':'
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

    # If still no files found, print message and exit
    if (( ${#files[@]} == 0 )); then
        echo "No more are left to be processed."
        exit 0
    fi

    # Process each file
    for f in "${files[@]}"; do
        # Determine the output .sh file name
        if [[ "$f" == "./output.txt" ]]; then
            ofile="./result.sh"
        else
            ofile="${f%.txt}.sh"
        fi

        # Extract packages
        packages=$(extract_packages "$f" | awk '{printf("%s ", $0)}')

        if [[ -z "$packages" ]]; then
            echo "No packages to install for $f."
            echo "#!/bin/bash" > "$ofile"
            echo "echo 'No packages to install.'" >> "$ofile"
        else
            local install_command="yay -S $packages --sudoloop --batchinstall --asdeps"
            echo "Processing $f -> $ofile"
            echo "#!/bin/bash" > "$ofile"
            echo "$install_command" >> "$ofile"
        fi

        chmod +x "$ofile"
    done
}

main
