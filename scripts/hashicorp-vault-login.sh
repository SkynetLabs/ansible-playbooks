#!/usr/bin/env bash

# Config:
# Path in 'ansible-private' repository with HashiCorp Vault env config.
# Expects set server URL set via 'HCV_URL' variable.
hcv_env_path="private-vars/hashicorp-vault.env"

# Get and set paths.
script_path="$BASH_SOURCE"
script_path_non_exact="$0"
script_dir=$(dirname "$script_path")
lib_dir="$script_dir/lib"

# Check that the script execution was sourced.
# We need this script to be sourced because we want to export HashiCorp Vault
# token to the user's current shell.
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

  # We can use exit here, because the script was not sourced and exit will not
  # close user's shell.
  exit 111
fi

# Get server URL.
echo "Getting HashiCorp Vault server URL from ansible-private config..."
url_result=$("$lib_dir/hashicorp-vault-get-url.sh" "$hcv_env_path")

# Extract URL by removing prefix.
hcv_url_prefix="hcv_url: "

# Check we got URL.
if [[ "$url_result" != "$hcv_url_prefix"* ]]; then
  echo "Error: HashiCorp Vault get URL subscript didn't returned URL."
  echo "$url_result"

  # We can't use exit here because the script was sourced and exit would close
  # current user's shell.
  return
fi

# Export server URL to current user shell.
url=${url_result#"$hcv_url_prefix"}
export HCV_URL="$url"
echo "Success."

# Get username.
echo "Logging to HashiCorp Vault server at $HCV_URL"
read -p "    Enter username: " hcv_username

if [ -z "$hcv_username" ]; then
  echo "User error: Username can't be empty."
  return
fi

# Get password
read -sp "    Enter password: " hcv_password
echo

if [ -z "$hcv_password" ]; then
  echo "User error: Password can't be empty."
  return
fi

# Login to HashiCorp Vault.
login_result=$("$lib_dir/hashicorp-vault-login-subscript.sh" "$hcv_username" "$hcv_password")

# Clear username and password in the current shell
hcv_username=''
hcv_password=''

# Login subscript returns token prefix followed by token.
hcv_token_prefix="hcv_token: "

# Check we got token or error.
if [[ "$login_result" != "$hcv_token_prefix"* ]]; then
  echo "$login_result"

  # We can't use exit here because the script was sourced and exit would close
  # current user's shell.
  return
fi

# Extract token by removing prefix and export it in shell for Ansible.
token=${login_result#"$hcv_token_prefix"}
export HCV_TOKEN="$token"
echo "Success."
