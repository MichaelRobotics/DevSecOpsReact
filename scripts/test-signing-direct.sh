#!/bin/bash
set -e

# Script to test Docker Hub login and Cosign signing without Kubernetes
# Usage: ./test-signing-direct.sh [dockerhub_pat] [environment]

# Error handling
error_exit() {
  echo "ERROR: $1" >&2
  exit 1
}

# Check for prerequisites
if ! command -v docker &> /dev/null; then
  error_exit "docker is not installed. Please install docker first."
fi

if ! command -v cosign &> /dev/null; then
  error_exit "cosign is not installed. Please install cosign first."
fi

# Check arguments
if [ $# -lt 1 ]; then
  error_exit "Usage: $0 [dockerhub_pat] [environment]"
fi

# Variables
DOCKERHUB_PASSWORD="$1"
ENVIRONMENT=${2:-dev}
KEYS_DIR="./cosign-keys"
KEY_PATH="${KEYS_DIR}/cosign_${ENVIRONMENT}.key"
PUB_KEY_PATH="${KEYS_DIR}/cosign_${ENVIRONMENT}.pub"
DOCKERHUB_USERNAME="robclusterdev"  # Hardcoded from previous scripts

# Check if Cosign keys exist
if [ ! -f "$KEY_PATH" ]; then
  error_exit "Private key not found at $KEY_PATH. Run generate_cosign_keys.sh first."
fi

if [ ! -f "$PUB_KEY_PATH" ]; then
  error_exit "Public key not found at $PUB_KEY_PATH. Run generate_cosign_keys.sh first."
fi

echo "=== Docker Hub and Cosign Test ==="
echo "Using keys for environment: $ENVIRONMENT"

if [ -z "$DOCKERHUB_PASSWORD" ]; then
  error_exit "Docker Hub PAT cannot be empty"
fi

# Test Docker Hub login
echo "Step 1: Logging in to Docker Hub..."
echo "$DOCKERHUB_PASSWORD" | docker login --username "$DOCKERHUB_USERNAME" --password-stdin
if [ $? -ne 0 ]; then
  error_exit "Docker Hub login failed. Check your credentials."
fi
echo "✅ Successfully logged in to Docker Hub as $DOCKERHUB_USERNAME"

# Build and tag a test image for Docker Hub
echo "Step 2: Building a test image..."
TEST_IMAGE_TAG="test-cosign-$(date +%s)"
TEST_IMAGE_LOCAL="cosign-test-image:$TEST_IMAGE_TAG"
TEST_IMAGE_REMOTE="$DOCKERHUB_USERNAME/clusterimages:$TEST_IMAGE_TAG"

# Create a temporary Dockerfile
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"; docker logout' EXIT

cat > "$TEMP_DIR/Dockerfile" << EOF
FROM alpine:latest
LABEL maintainer="$DOCKERHUB_USERNAME"
LABEL purpose="Cosign Testing"
CMD ["echo", "Cosign test image"]
EOF

# Build the test image
docker build -t "$TEST_IMAGE_LOCAL" "$TEMP_DIR"
if [ $? -ne 0 ]; then
  error_exit "Failed to build test image"
fi
echo "✅ Test image built successfully: $TEST_IMAGE_LOCAL"

# Tag for Docker Hub
docker tag "$TEST_IMAGE_LOCAL" "$TEST_IMAGE_REMOTE"
echo "✅ Image tagged as: $TEST_IMAGE_REMOTE"

# Push to Docker Hub
echo "Step 3: Pushing image to Docker Hub..."
docker push "$TEST_IMAGE_REMOTE"
if [ $? -ne 0 ]; then
  error_exit "Failed to push image to Docker Hub"
fi
echo "✅ Image pushed successfully to Docker Hub"

# Sign the image with Cosign
echo "Step 4: Signing the image with Cosign..."
COSIGN_PASSWORD='' cosign sign --key "$KEY_PATH" "$TEST_IMAGE_REMOTE" -y
SIGN_RESULT=$?

if [ $SIGN_RESULT -ne 0 ]; then
  error_exit "Failed to sign image"
fi
echo "✅ Image signed successfully"

# Verify the signature
echo "Step 5: Verifying the image signature..."
cosign verify --key "$PUB_KEY_PATH" "$TEST_IMAGE_REMOTE"
VERIFY_RESULT=$?

# Display results
echo ""
echo "=== Test Results ==="
if [ $VERIFY_RESULT -eq 0 ]; then
  echo "✅ SUCCESS: Cosign signing and verification test passed!"
  echo "The following operations succeeded:"
  echo "  ✓ Logged in to Docker Hub"
  echo "  ✓ Built and pushed a test image to Docker Hub"
  echo "  ✓ Signed the image with your Cosign private key"
  echo "  ✓ Verified the signature with your Cosign public key"
else
  echo "❌ FAILURE: Cosign verification failed!"
fi

# Clean up
echo ""
echo "=== Cleanup ==="
echo "Removing the test images..."
docker rmi "$TEST_IMAGE_LOCAL" "$TEST_IMAGE_REMOTE" &>/dev/null || true

# Request Docker Hub image deletion (optional)
echo ""
echo "Note: A test image was pushed to your Docker Hub account."
echo "You may want to delete it manually: $TEST_IMAGE_REMOTE"

# Logout from Docker Hub
docker logout
echo "Logged out from Docker Hub."

echo ""
echo "Test completed successfully!"
echo "You can now use Docker Hub and Cosign together for secure image signing and verification." 