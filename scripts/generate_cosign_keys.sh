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
KEY_PASSWORD=${2:-$(openssl rand -base64 32)}
KEYS_DIR="./cosign-keys"

# Create directory for keys if it doesn't exist
mkdir -p "${KEYS_DIR}"

# Generate cosign keypair
echo "Generating Cosign key pair for ${ENVIRONMENT} environment..."
echo "${KEY_PASSWORD}" | cosign generate-key-pair --output-key-prefix "${KEYS_DIR}/cosign_${ENVIRONMENT}"

# Display public key
echo "Cosign public key generated at: ${KEYS_DIR}/cosign_${ENVIRONMENT}.pub"
echo "This public key will be used to verify signed images in your environment."

# Instructions for GitHub Actions setup
echo "====================================================="
echo "MANUAL GITHUB SECRETS SETUP INSTRUCTIONS:"
echo "====================================================="
echo "1. Add the following secrets to your GitHub repository:"
echo "   - COSIGN_PRIVATE_KEY_${ENVIRONMENT^^}: Content of ${KEYS_DIR}/cosign_${ENVIRONMENT}.key"
echo "   - COSIGN_PASSWORD_${ENVIRONMENT^^}: The key password"
echo "   - COSIGN_PUBLIC_KEY_${ENVIRONMENT^^}: Content of ${KEYS_DIR}/cosign_${ENVIRONMENT}.pub"
echo
echo "To add these secrets automatically using gh CLI, run:"
echo "gh secret set COSIGN_PRIVATE_KEY_${ENVIRONMENT^^} < ${KEYS_DIR}/cosign_${ENVIRONMENT}.key"
echo "gh secret set COSIGN_PASSWORD_${ENVIRONMENT^^} -b \"${KEY_PASSWORD}\""
echo "gh secret set COSIGN_PUBLIC_KEY_${ENVIRONMENT^^} < ${KEYS_DIR}/cosign_${ENVIRONMENT}.pub"
echo
echo "2. Update your CI/CD workflow to use these secrets for signing images"
echo "====================================================="

# Clean up
echo "For security reasons, consider removing the private key after adding it to GitHub secrets:"
echo "rm ${KEYS_DIR}/cosign_${ENVIRONMENT}.key" 