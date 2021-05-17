#!/usr/bin/env bash

# Set command and arguments
cmd=lpass
args="login fil@siasky.net"

# Execute the command
source $(dirname "$0")/lib/ansible-executor.sh
