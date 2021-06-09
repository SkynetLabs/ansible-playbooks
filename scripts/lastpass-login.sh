#!/usr/bin/env bash

read -p "Enter your LastPass username: " lpass_username
read -p "Enter desired LastPass timeout in seconds: " lpass_timeout

# Set command and arguments
cmd=lpass
args="login $lpass_username"
restart_ansible_cm=true

# Execute the command
source $(dirname "$0")/lib/ansible-executor.sh