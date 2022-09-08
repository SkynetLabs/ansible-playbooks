#!/usr/bin/env bash

# Config:
# Path in 'ansible-private' repository with HashiCorp Vault env config.
# Expects HashiCorp Vault server URL set via 'HCV_URL' variable.
hcv_env_path_in_ansible_private="private-vars/hashicorp-vault.env"

# Get and set paths:
# Paths of this script file. "$0" is not correct if this script is sourced.
script_path="$BASH_SOURCE"
script_path_non_exact="$0"
# Directory path of this scripts file:
script_dir=$(dirname "$script_path")
# Directory path of scripts/lib:
lib_dir="$script_dir/lib"
# Ansible playbooks root directory:
ansible_playbooks_dir="$script_dir/.."
# File path in Ansible private repository where we expect configured HashiCorp
# Vault environment variables.
hcv_env_path_from_ansible_playbooks="$ansible_playbooks_dir/../ansible-private/$hcv_env_path_in_ansible_private"

# Check that the script execution was sourced:
# We need this script to be sourced because we want to export HashiCorp Vault
# token to the user's current shell. To determine if the script was sourced we
# compare results of 2 methods getting script path.
if [[ "$script_path" == "$script_path_non_exact" ]]; then
  echo "Error executing HashiCorp Vault login script:"
  echo "    This script needs to export the Vault token for the current user shell"
  echo "    so it must be sourced within the current shell."
  echo "Execute it in one of the following ways:"
  echo "From ansible-playbooks dir:"
  echo "    . scripts/hashicorp-vault-login.sh"
  echo "    source scripts/hashicorp-vault-login.sh"
  echo "From ansible-playbooks/scripts dir:"
  echo "    . hashicorp-vault-login.sh"
  echo "    source hashicorp-vault-login.sh"
  echo "Exiting the login script now."

  # We should use exit here, because the script was not sourced and exit will
  # not close user's shell.
  exit 111
fi

# Start getting server URL:
echo "Getting HashiCorp Vault server URL from ansible-private config..."

# Check config file is present:
if [[ ! -f "$hcv_env_path_from_ansible_playbooks" ]]; then
  echo "Configuration errror:"
  echo "    It seems that HashiCorp config file '$hcv_env_path_in_ansible_private'"
  echo "    is missing in 'ansible-private' repository."
  echo "    'ansible-private/$hcv_env_path_in_ansible_private' does not exist."
  
  # We can't use exit here because the script was sourced and exit would close
  # current user's shell.
  return
fi

# Check config file is readable:
if [[ ! -r "$hcv_env_path_from_ansible_playbooks" ]]; then
  echo "    It seems that HashiCorp config file '$hcv_env_path_in_ansible_private'"
  echo "    in 'ansible-private' repository exists, but it is not readable."
  echo "    You should fix permissions (in git)."

  # We can't use exit here because the script was sourced and exit would close
  # current user's shell.
  return
fi

# Reset HashiCorp Vault old URL and token
export HCV_URL=''
export HCV_TOKEN=''

# Source config file:
source "$hcv_env_path_from_ansible_playbooks"

# Check we got server URL:
if [[ "$HCV_URL" == "" ]]; then
  echo "Configuration error:"
  echo "    HashiCorp Vault server URL was not set correctly"
  echo "    in ansible-private repository"
  echo "    at '$hcv_env_path_in_ansible_private' path"
  echo "    via 'HCV_URL' variable."

  # We can't use exit here because the script was sourced and exit would close
  # current user's shell.
  return
fi

echo "Success."

# Get username:
echo "Logging to HashiCorp Vault server at $HCV_URL"
read -p "    Enter username: " hcv_username

if [ -z "$hcv_username" ]; then
  echo "User error: Username can't be empty."
  return
fi

# Get password:
read -sp "    Enter password: " hcv_password
echo

if [ -z "$hcv_password" ]; then
  echo "User error: Password can't be empty."
  return
fi

# Login to HashiCorp Vault via subscript:
login_result=$("$lib_dir/hashicorp-vault-login-subscript.sh" "$hcv_username" "$hcv_password")

# Clear username and password in the current shell (for security reasons):
hcv_username=''
hcv_password=''

# Login subscript returns token prefix followed by token, set prefix:
hcv_token_prefix="hcv_token: "

# Check we got token or error:
if [[ "$login_result" != "$hcv_token_prefix"* ]]; then
  echo "$login_result"

  # We can't use exit here because the script was sourced and exit would close
  # current user's shell.
  return
fi

# Extract token by removing prefix and export it in the current user's shell
# for Ansible:
token=${login_result#"$hcv_token_prefix"}
export HCV_TOKEN="$token"
echo "Success."
