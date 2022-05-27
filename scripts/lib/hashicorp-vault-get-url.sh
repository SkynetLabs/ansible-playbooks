# Get paths
script_path="$BASH_SOURCE"
script_dir=$(dirname "$script_path")
ansible_playbooks_dir="$script_dir/../.."
ansible_private_dir="$ansible_playbooks_dir/../ansible-private"

hcv_env_path_in_ansible_private="$1"
hcv_env_path_from_ansible_playbooks="$ansible_playbooks_dir/../ansible-private/$hcv_env_path_in_ansible_private"

# Source HashiCorp Vault URL
if [[ ! -f "$hcv_env_path_from_ansible_playbooks" ]]; then
  echo "Configuration errror:"
  echo "    It seems that HashiCorp config file '$hcv_env_path_in_ansible_private'"
  echo "    is missing in 'ansible-private' repository."
  echo "    'ansible-private/$hcv_env_path_in_ansible_private' does not exist."
  exit 100
else
  source "$hcv_env_path_from_ansible_playbooks"
  echo "hcv_url: $HCV_URL"
fi
