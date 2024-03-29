#!/usr/bin/env bash

# This script is a helper for checking the syntax of any ansible playbook

# Set command and arguments
cmd=ansible-playbook
args="--syntax-check $@"

# This script is used in a github action
github_action=true

# Execute the command
source $(dirname "$0")/lib/ansible-executor.sh
