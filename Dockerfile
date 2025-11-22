FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

# Install git, bash, openssh-clients, and ca-certificates
RUN microdnf install -y \
    git \
    bash \
    openssh-clients \
    ca-certificates \
    && microdnf clean all

# Copy entrypoint and other scripts
COPY entrypoint.sh /entrypoint.sh
COPY healthcheck.sh /healthcheck.sh
COPY git-credential-helper.sh /usr/local/bin/git-credential-helper.sh

# Create non-root user with UID 1001 and add to group 0 (for OpenShift SCC compatibility)
RUN useradd -u 1001 -g 0 -m -s /bin/bash git-user

# Create /workspace directory with proper ownership and permissions
RUN mkdir -p /workspace && \
    chown 1001:0 /workspace && \
    chmod g+rwX /workspace

# Switch to non-root user
USER 1001

# Configure git to trust all directories (safe.directory)
RUN git config --global safe.directory '*'

# Configure git for verbose debugging (disable fsck and detached head warnings)
RUN git config --global --add transfer.fsckObjects false && \
    git config --global --add advice.detachedHead false

# Set permissions for scripts
USER 0
RUN chmod +x /entrypoint.sh /healthcheck.sh /usr/local/bin/git-credential-helper.sh
USER 1001

# Set working directory
WORKDIR /workspace

# Configure entrypoint and default command
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/bin/bash"]
