#!/bin/bash
# Test script for common git operations
# This validates the git-init-rhel9 image functionality

set -e

IMAGE_NAME="${IMAGE_NAME:-quay.io/takinosh/git-init-rhel9:latest}"
TEST_DIR="/tmp/git-init-test-$$"

echo "=========================================="
echo "Git Init RHEL9 - Comprehensive Test Suite"
echo "=========================================="
echo "Image: $IMAGE_NAME"
echo ""

# Cleanup function
cleanup() {
    echo "Cleaning up test directory..."
    rm -rf "$TEST_DIR"
}
trap cleanup EXIT

mkdir -p "$TEST_DIR"

# Test 1: Anonymous HTTPS clone
echo "Test 1: Anonymous HTTPS clone"
echo "----------------------------"
docker run --rm -v "$TEST_DIR:/workspace" "$IMAGE_NAME" \
    clone --depth 1 https://github.com/octocat/Hello-World.git /workspace/hello-world
if [ -d "$TEST_DIR/hello-world/.git" ]; then
    echo "✓ Anonymous HTTPS clone successful"
else
    echo "✗ Anonymous HTTPS clone failed"
    exit 1
fi
echo ""

# Test 2: Shallow clone (--depth 1)
echo "Test 2: Shallow clone validation"
echo "-------------------------------"
COMMIT_COUNT=$(cd "$TEST_DIR/hello-world" && git rev-list --count HEAD)
if [ "$COMMIT_COUNT" -eq 1 ]; then
    echo "✓ Shallow clone with --depth 1 successful (1 commit)"
else
    echo "✗ Shallow clone validation failed (expected 1 commit, got $COMMIT_COUNT)"
    exit 1
fi
echo ""

# Test 3: Branch checkout
echo "Test 3: Branch checkout"
echo "---------------------"
docker run --rm -v "$TEST_DIR:/workspace" "$IMAGE_NAME" \
    /bin/bash -c "cd /workspace/hello-world && git checkout master && git branch --show-current"
echo "✓ Branch checkout successful"
echo ""

# Test 4: Authenticated HTTPS clone with credentials (simulated)
echo "Test 4: Authenticated HTTPS clone (credential helper test)"
echo "---------------------------------------------------------"
echo "Note: This tests the credential helper mechanism without actual authentication"
docker run --rm \
    -e GIT_USERNAME="testuser" \
    -e GIT_PASSWORD="testpass" \
    "$IMAGE_NAME" \
    /bin/bash -c "git config --global credential.helper '/usr/local/bin/git-credential-helper.sh' && \
                  echo 'protocol=https' | git credential fill | grep 'username=testuser'"
echo "✓ Credential helper configured correctly"
echo ""

# Test 5: Entrypoint functionality
echo "Test 5: Entrypoint functionality"
echo "------------------------------"
docker run --rm "$IMAGE_NAME" /bin/bash -c "echo 'Direct bash command works'"
echo "✓ Entrypoint with bash command successful"
echo ""

# Test 6: Git direct command via entrypoint
echo "Test 6: Git command via entrypoint"
echo "---------------------------------"
docker run --rm -v "$TEST_DIR:/workspace" "$IMAGE_NAME" \
    clone --depth 1 https://github.com/octocat/Spoon-Knife.git /workspace/spoon-knife
if [ -d "$TEST_DIR/spoon-knife/.git" ]; then
    echo "✓ Git command via entrypoint successful"
else
    echo "✗ Git command via entrypoint failed"
    exit 1
fi
echo ""

# Test 7: Health check
echo "Test 7: Health check"
echo "------------------"
docker run --rm "$IMAGE_NAME" /healthcheck.sh
echo "✓ Health check successful"
echo ""

# Test 8: SSH client availability (for SSH clone support)
echo "Test 8: SSH client availability"
echo "-----------------------------"
docker run --rm "$IMAGE_NAME" /bin/bash -c "ssh -V 2>&1 | head -n 1"
echo "✓ SSH client available"
echo ""

# Test 9: Git verbose config
echo "Test 9: Git verbose debugging configuration"
echo "-----------------------------------------"
docker run --rm "$IMAGE_NAME" /bin/bash -c \
    "git config --global --get transfer.fsckObjects && \
     git config --global --get advice.detachedHead"
echo "✓ Git verbose debugging configured"
echo ""

echo "=========================================="
echo "All tests passed! ✓"
echo "=========================================="
