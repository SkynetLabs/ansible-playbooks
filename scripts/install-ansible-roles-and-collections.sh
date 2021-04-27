#!/usr/bin/env bash

# Set command and arguments
cmd=ansible-galaxy
args="install -r requirements.yml --force"
load_hosts=false

# Execute the command
source $(dirname "$0")/lib/ansible-executor.sh
