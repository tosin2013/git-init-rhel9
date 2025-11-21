#!/bin/bash
# Test script to verify the git-init-rhel9 image meets all requirements

set -e

IMAGE_NAME="${1:-quay.io/takinosh/git-init-rhel9:latest}"

echo "Testing image: $IMAGE_NAME"
echo "================================"

# Test 1: Check if bash is available
echo "Test 1: Checking if /bin/bash is available..."
docker run --rm "$IMAGE_NAME" /bin/bash --version
echo "✓ /bin/bash is available"

# Test 2: Check if git is installed
echo -e "\nTest 2: Checking if git is installed..."
docker run --rm "$IMAGE_NAME" git --version
echo "✓ git is installed"

# Test 3: Check if openssh-clients is installed
echo -e "\nTest 3: Checking if ssh is available..."
docker run --rm "$IMAGE_NAME" ssh -V
echo "✓ openssh-clients is installed"

# Test 4: Check user ID and group
echo -e "\nTest 4: Checking user ID and group..."
USER_INFO=$(docker run --rm "$IMAGE_NAME" id)
echo "$USER_INFO"
if echo "$USER_INFO" | grep -q "uid=1001(git-user)" && echo "$USER_INFO" | grep -q "gid=0(root)"; then
    echo "✓ User has UID 1001 and is in group 0"
else
    echo "✗ User does not have correct UID or group"
    exit 1
fi

# Test 5: Check /workspace directory permissions
echo -e "\nTest 5: Checking /workspace directory..."
WORKSPACE_INFO=$(docker run --rm "$IMAGE_NAME" ls -ld /workspace)
echo "$WORKSPACE_INFO"
if echo "$WORKSPACE_INFO" | grep -q "drwxrwxr-x.*1001.*root.*workspace"; then
    echo "✓ /workspace directory has correct ownership and permissions"
else
    echo "✗ /workspace directory does not have correct ownership or permissions"
    exit 1
fi

# Test 6: Check git safe.directory configuration
echo -e "\nTest 6: Checking git safe.directory configuration..."
SAFE_DIR=$(docker run --rm "$IMAGE_NAME" git config --global --get safe.directory)
echo "safe.directory = $SAFE_DIR"
if [ "$SAFE_DIR" = "*" ]; then
    echo "✓ git safe.directory is set to '*'"
else
    echo "✗ git safe.directory is not set correctly"
    exit 1
fi

# Test 7: Test git clone functionality
echo -e "\nTest 7: Testing git clone with bash -c..."
docker run --rm "$IMAGE_NAME" /bin/bash -c 'git clone --depth 1 https://github.com/octocat/Hello-World.git /tmp/test && ls -la /tmp/test'
echo "✓ git clone works with /bin/bash -c"

# Test 8: Check ca-certificates
echo -e "\nTest 8: Checking ca-certificates..."
docker run --rm "$IMAGE_NAME" ls -la /etc/pki/tls/certs/ca-bundle.crt
echo "✓ ca-certificates are installed"

echo -e "\n================================"
echo "All tests passed! ✓"
