#!/usr/bin/env bash

# LastPass config
default_lpass_timeout_secs=3600

read -p "Enter your LastPass username (email): " lpass_username
read -p "Enter desired LastPass timeout in seconds (empty for default $default_lpass_timeout_secs): " lpass_timeout

# Set command and arguments
cmd=lpass
args="login $lpass_username"
restart_ansible_cm=true

# Execute the command
source $(dirname "$0")/lib/ansible-executor.sh