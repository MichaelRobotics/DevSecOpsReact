#!/bin/bash
set -e

# Script to generate Cosign key pair for container image signing
echo "Generating Cosign keys for secure container image signing..."

# Check if cosign is installed
if ! command -v cosign &> /dev/null; then
    echo "Error: cosign not found. Please install cosign first."
    echo "Installation instructions: https://docs.sigstore.dev/cosign/installation/"
    exit 1
fi

# Environment setup
ENVIRONMENT=${1:-dev}
KEYS_DIR="./cosign-keys"

# Create directory for keys if it doesn't exist
mkdir -p "${KEYS_DIR}"

# For testing purposes, create a small file with an empty password
PASSWORD_FILE=$(mktemp)
echo -n "" > "$PASSWORD_FILE"  # Empty password

# Generate cosign keypair with empty password (for testing only)
echo "Generating Cosign key pair for ${ENVIRONMENT} environment (with empty password)..."
cosign generate-key-pair --output-key-prefix "${KEYS_DIR}/cosign_${ENVIRONMENT}" < "$PASSWORD_FILE"
rm "$PASSWORD_FILE"  # Remove the temporary password file

# Display public key
echo "Cosign public key generated at: ${KEYS_DIR}/cosign_${ENVIRONMENT}.pub"
echo "This public key will be used to verify signed images in your environment."

# Instructions for GitHub Actions setup
echo "====================================================="
echo "MANUAL GITHUB SECRETS SETUP INSTRUCTIONS:"
echo "====================================================="
echo "1. Add the following secrets to your GitHub repository:"
echo "   - COSIGN_PRIVATE_KEY_${ENVIRONMENT^^}: Content of ${KEYS_DIR}/cosign_${ENVIRONMENT}.key"
echo "   - COSIGN_PUBLIC_KEY_${ENVIRONMENT^^}: Content of ${KEYS_DIR}/cosign_${ENVIRONMENT}.pub"
echo
echo "To add these secrets automatically using gh CLI, run:"
echo "gh secret set COSIGN_PRIVATE_KEY_${ENVIRONMENT^^} < ${KEYS_DIR}/cosign_${ENVIRONMENT}.key"
echo "gh secret set COSIGN_PUBLIC_KEY_${ENVIRONMENT^^} < ${KEYS_DIR}/cosign_${ENVIRONMENT}.pub"
echo
echo "2. Update your CI/CD workflow to use these secrets for signing images"
echo "====================================================="

# Usage instructions
echo "====================================================="
echo "USING THE KEYS FOR SIGNING/VERIFICATION:"
echo "====================================================="
echo "To sign an image (empty password will be used):"
echo "COSIGN_PASSWORD='' cosign sign --key ${KEYS_DIR}/cosign_${ENVIRONMENT}.key <IMAGE_REFERENCE>"
echo
echo "To verify a signed image:"
echo "cosign verify --key ${KEYS_DIR}/cosign_${ENVIRONMENT}.pub <IMAGE_REFERENCE>"
echo "====================================================="

# Clean up warning
echo "Note: Using empty passwords is NOT recommended for production."
echo "This is for testing purposes only."
echo "For maximum security after adding to GitHub, you could remove the key files:"
echo "rm ${KEYS_DIR}/cosign_${ENVIRONMENT}.key" 