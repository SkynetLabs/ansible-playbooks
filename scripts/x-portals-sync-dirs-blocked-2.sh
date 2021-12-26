#!/usr/bin/env bash

# Set command and arguments
cmd=ansible-playbook
args="--inventory /tmp/ansible-private/inventory/hosts.ini playbooks/x-portals-sync-dirs-blocked-2.yml $@"

# Execute the command
source $(dirname "$0")/lib/ansible-executor.sh
