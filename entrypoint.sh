#!/bin/bash
set -e

# Default command if none provided
if [ $# -eq 0 ]; then
    exec /bin/bash
fi

# If first arg looks like a git command, run it
if [ "$1" = "clone" ] || [ "$1" = "pull" ] || [ "$1" = "fetch" ]; then
    exec git "$@"
fi

# Otherwise execute as-is
exec "$@"
