#!/usr/bin/env bash

# Set command and arguments
cmd=ansible
args="--inventory /tmp/ansible-private/inventory/hosts.ini webportals -m ping -u user $@ "

source $(dirname "$0")/lib/ansible-executor.sh