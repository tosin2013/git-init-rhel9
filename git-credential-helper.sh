#!/bin/bash
# git-credential-helper.sh
# Usage: git config --global credential.helper '/usr/local/bin/git-credential-helper.sh'

if [ "$1" = "get" ]; then
    if [ -n "${GIT_USERNAME}" ] && [ -n "${GIT_PASSWORD}" ]; then
        echo "username=${GIT_USERNAME}"
        echo "password=${GIT_PASSWORD}"
    fi
fi
