#!/bin/bash

# Function to decrypt and print the secret
decrypt_secret() {
    local sealed_secret_file="$1"
    local secrets=$(cat $sealed_secret_file | kubeseal --recovery-unseal --recovery-private-key main.key)

    while IFS= read -r line; do
        IFS=":" read -r key value <<< "$line"
        key=$(echo "$key" | xargs)
        value=$(echo "$value" | xargs | base64 -d)
        echo "$key: $value"
    done <<< "$(echo "$secrets" | jq .data | jq -r 'to_entries[] | "\(.key): \(.value)"')"

    #echo "Decrypted Value: $decrypted_value"
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
            echo "Decrypting $file"
            decrypt_secret "$file"
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
