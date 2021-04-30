#!/usr/bin/env bash

# Set command and arguments
cmd=ansible-playbook
args="--inventory inventory/hosts.ini playbooks/portals-get-status.yml $@"

# Execute the command
source $(dirname "$0")/lib/ansible-executor.sh
