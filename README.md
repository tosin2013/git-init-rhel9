# git-init-rhel9

A minimal RHEL 9-based container image for git operations, designed for use in Kubernetes/OpenShift environments.

## Features

- **Base Image**: Red Hat Universal Base Image 9 (UBI9) minimal
- **Installed Tools**: git, bash, openssh-clients, ca-certificates
- **OpenShift Compatible**: Non-root user (UID 1001) in group 0 for OpenShift SCC compatibility
- **Workspace**: `/workspace` directory with group-writable permissions (g+rwX)
- **Git Configuration**: Global safe.directory set to `*` to allow git operations in any directory
- **Shell Support**: `/bin/bash` available for executing commands like `git clone`

## Image Location

The image is automatically built and pushed to:
- **Latest**: `quay.io/takinosh/git-init-rhel9:latest`
- **Version Tags**: `quay.io/takinosh/git-init-rhel9:v*` (for tagged releases)

## Usage

### Basic Usage

```bash
# Pull the image
podman pull quay.io/takinosh/git-init-rhel9:latest

# Run interactively
podman run -it --rm quay.io/takinosh/git-init-rhel9:latest

# Clone a repository
podman run -it --rm -v $(pwd):/workspace quay.io/takinosh/git-init-rhel9:latest \
  /bin/bash -c 'git clone https://github.com/example/repo.git'
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
podman run -it --rm \
  -v $(pwd):/workspace \
  -v ~/.ssh:/home/git-user/.ssh:ro \
  quay.io/takinosh/git-init-rhel9:latest \
  /bin/bash -c 'git clone git@github.com:example/private-repo.git'
```

## Building Locally

```bash
# Build the image
podman build -t git-init-rhel9:local .

# Test the image
podman run -it --rm git-init-rhel9:local /bin/bash -c 'git --version'
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

## License

This project is open source and available under the terms specified in the repository.