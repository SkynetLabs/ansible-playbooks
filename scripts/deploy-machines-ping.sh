#!/usr/bin/env bash

# Set command and arguments
cmd=ansible
args="--inventory inventory/hosts.ini deploy_machines -m ping $@"

source $(dirname "$0")/lib/ansible-executor.sh