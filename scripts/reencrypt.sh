#!/bin/bash

# Function to reencrypt the sealed secret
reencrypt() {
    kubeseal --re-encrypt -o yaml < $file > tmp.yaml \
        && mv tmp.yaml $file
}

# Function to search for sealed secrets in folders and subfolders
search_sealed_secrets() {
    local search_dir="$1"
    echo "Searching for sealedsecret.yaml in $search_dir"
    local sealed_secrets_files=($(find "$search_dir" -type f -name "*sealedsecret.yaml"))

    if [ ${#sealed_secrets_files[@]} -eq 0 ]; then
        echo "No sealedsecret.yaml found in $search_dir"
    else
        for file in "${sealed_secrets_files[@]}"; do
            echo "Reencrypting $file"
            reencrypt "$file"
            echo ""
        done
    fi
}

# Main function
main() {
    local start_dir="${1:-.}"  # Default to current directory if no argument is provided
    search_sealed_secrets "$start_dir"
}

# Call main function with provided arguments
main "$@"
