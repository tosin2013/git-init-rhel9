# git-init-rhel9

A minimal RHEL 9-based container image for git operations, designed for use in Kubernetes/OpenShift environments.

## Features

- **Base Image**: Red Hat Universal Base Image 9 (UBI9) minimal
- **Installed Tools**: git, bash, openssh-clients, ca-certificates
- **OpenShift Compatible**: Non-root user (UID 1001) in group 0 for OpenShift SCC compatibility
- **Workspace**: `/workspace` directory with group-writable permissions (g+rwX)
- **Git Configuration**: Global safe.directory set to `*` to allow git operations in any directory
- **Shell Support**: `/bin/bash` available for executing commands like `git clone`
- **Flexible Entrypoint**: Smart entrypoint that handles git commands directly or runs custom commands
- **Verbose Debugging**: Pre-configured git settings for troubleshooting
- **Credential Helper**: Built-in secure credential handling via environment variables
- **Multi-Architecture**: Supports both amd64 and arm64 architectures
- **Health Check**: Includes health check script for container orchestration

## Image Location

The image is automatically built and pushed to:
- **Latest**: `quay.io/takinosh/git-init-rhel9:latest`
- **Version Tags**: `quay.io/takinosh/git-init-rhel9:v1.0.0` (semantic versioning)
- **Architectures**: linux/amd64, linux/arm64

Version tags follow semantic versioning (e.g., v1.0.0, v1.1.0) and may include git version information.

## Usage

### Basic Usage

```bash
# Pull the image
podman pull quay.io/takinosh/git-init-rhel9:latest

# Run interactively
podman run -it --rm quay.io/takinosh/git-init-rhel9:latest

# Clone a repository using git command directly (via entrypoint)
podman run --rm -v $(pwd):/workspace quay.io/takinosh/git-init-rhel9:latest \
  clone https://github.com/example/repo.git

# Clone with bash -c (traditional method)
podman run --rm -v $(pwd):/workspace quay.io/takinosh/git-init-rhel9:latest \
  /bin/bash -c 'git clone https://github.com/example/repo.git'

# Shallow clone for faster operations
podman run --rm -v $(pwd):/workspace quay.io/takinosh/git-init-rhel9:latest \
  clone --depth 1 https://github.com/example/repo.git
```

### Kubernetes/OpenShift Init Container

Use as an init container to clone repositories before your main application starts:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-with-git-init
spec:
  initContainers:
  - name: git-clone
    image: quay.io/takinosh/git-init-rhel9:latest
    command: ["/bin/bash", "-c"]
    args:
    - |
      git clone https://github.com/example/repo.git /workspace/repo
    volumeMounts:
    - name: workspace
      mountPath: /workspace
  containers:
  - name: app
    image: your-app:latest
    volumeMounts:
    - name: workspace
      mountPath: /workspace
  volumes:
  - name: workspace
    emptyDir: {}
```

### With SSH Keys

```bash
# Mount SSH keys for private repository access
podman run --rm \
  -v $(pwd):/workspace \
  -v ~/.ssh:/home/git-user/.ssh:ro \
  quay.io/takinosh/git-init-rhel9:latest \
  clone git@github.com:example/private-repo.git
```

### With HTTPS Credentials

```bash
# Using environment variables with credential helper
podman run --rm \
  -v $(pwd):/workspace \
  -e GIT_USERNAME="your-username" \
  -e GIT_PASSWORD="your-token" \
  quay.io/takinosh/git-init-rhel9:latest \
  /bin/bash -c 'git config --global credential.helper "/usr/local/bin/git-credential-helper.sh" && \
                git clone https://github.com/example/private-repo.git'
```

## Environment Variables

The image supports the following environment variables:

- **GIT_USERNAME**: Username for HTTPS authentication (used with credential helper)
- **GIT_PASSWORD**: Password or token for HTTPS authentication (used with credential helper)
- **GIT_TRACE**: Set to `1` to enable git operation tracing for debugging
- **GIT_CURL_VERBOSE**: Set to `1` to enable verbose HTTPS debugging
- **GIT_SSH_COMMAND**: Custom SSH command (e.g., `ssh -i /path/to/key`)

## Building Locally

```bash
# Build the image
podman build -t git-init-rhel9:local .

# Test the image
podman run --rm git-init-rhel9:local /bin/bash -c 'git --version'

# Run comprehensive tests
chmod +x test.sh
./test.sh git-init-rhel9:local

# Run health check
podman run --rm git-init-rhel9:local /healthcheck.sh
```

## CI/CD

The image is automatically built and pushed to Quay.io via GitHub Actions on:
- **Push to main branch**: Updates the `latest` tag
- **Version tags** (e.g., `v1.0.0`): Creates corresponding version tags
- **Pull requests**: Builds but doesn't push (validation only)

### Required Secrets

Configure the following secrets in your GitHub repository:
- `QUAY_USERNAME`: Quay.io username
- `QUAY_PASSWORD`: Quay.io password or robot token

## Dependabot

Automated updates are enabled for:
- Docker base images (weekly)
- GitHub Actions (weekly)

## Security

- Runs as non-root user (UID 1001)
- Minimal attack surface (ubi-minimal base)
- Regular base image updates via Dependabot
- OpenShift Security Context Constraints (SCC) compatible

## Troubleshooting

### Common Error Scenarios

#### 1. Permission Denied Errors
**Problem**: Cannot write to `/workspace` directory.  
**Solution**: Ensure the volume is mounted with proper permissions. OpenShift automatically handles this, but in Docker/Podman you may need to set ownership:
```bash
podman run --rm -v $(pwd):/workspace:Z quay.io/takinosh/git-init-rhel9:latest clone https://github.com/example/repo.git
```

#### 2. Authentication Failures
**Problem**: "Authentication failed" or "Permission denied" for private repositories.  
**Solution**: 
- For HTTPS: Use the credential helper with `GIT_USERNAME` and `GIT_PASSWORD` environment variables
- For SSH: Mount your SSH keys to `/home/git-user/.ssh` and ensure proper permissions
```bash
# For SSH keys
podman run --rm -v ~/.ssh:/home/git-user/.ssh:ro -v $(pwd):/workspace quay.io/takinosh/git-init-rhel9:latest clone git@github.com:user/repo.git
```

#### 3. SSL Certificate Errors
**Problem**: "SSL certificate problem" or certificate verification failures.  
**Solution**: The image includes `ca-certificates`. For self-signed certificates:
```bash
podman run --rm -e GIT_SSL_NO_VERIFY=1 -v $(pwd):/workspace quay.io/takinosh/git-init-rhel9:latest clone https://example.com/repo.git
```

#### 4. Detached HEAD Warnings
**Problem**: Seeing "You are in 'detached HEAD' state" warnings.  
**Solution**: These warnings are disabled by default in this image. If you need to enable them:
```bash
git config --global advice.detachedHead true
```

### Enabling Verbose Debugging

For troubleshooting git operations:

```bash
# Enable git trace
podman run --rm -e GIT_TRACE=1 -v $(pwd):/workspace quay.io/takinosh/git-init-rhel9:latest clone https://github.com/example/repo.git

# Enable HTTPS debugging
podman run --rm -e GIT_CURL_VERBOSE=1 -v $(pwd):/workspace quay.io/takinosh/git-init-rhel9:latest clone https://github.com/example/repo.git

# Enable all debugging
podman run --rm -e GIT_TRACE=1 -e GIT_CURL_VERBOSE=1 -e GIT_TRACE_PACKET=1 -v $(pwd):/workspace quay.io/takinosh/git-init-rhel9:latest clone https://github.com/example/repo.git
```

## Testing

The repository includes comprehensive test scripts:

- **test-image.sh**: Basic validation tests
- **test.sh**: Comprehensive test suite including:
  - Anonymous HTTPS clones
  - Authenticated HTTPS clones with credentials
  - SSH clone support verification
  - Branch/tag checkout
  - Shallow clone (--depth 1)
  - Entrypoint functionality
  - Health checks

Run tests with:
```bash
# Test latest from Quay.io
./test.sh

# Test local build
IMAGE_NAME=git-init-rhel9:local ./test.sh
```

## License

This project is open source and available under the terms specified in the repository.