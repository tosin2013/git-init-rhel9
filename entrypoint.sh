#!/bin/bash
set -e

# Default command if none provided
if [ $# -eq 0 ]; then
    exec /bin/bash
fi

# If first arg looks like a git command (not starting with / or -)
# and it's a valid git command, run it
if [[ "$1" != /* ]] && [[ "$1" != -* ]] && git help -a 2>/dev/null | grep -qw "$1" 2>/dev/null; then
    exec git "$@"
fi

# Otherwise execute as-is
exec "$@"
