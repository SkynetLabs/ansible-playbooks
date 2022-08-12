# Expected parameters:
# - $1: HashiCorp Vault username
# - $2: HashiCorp Vault password

# Set working directory to ansible-playbooks root directory:
script_path="$BASH_SOURCE"
script_dir=$(dirname "$script_path")
ansible_playbooks_dir="$script_dir/../.."
pushd $ansible_playbooks_dir > /dev/null

# Try to login to HashiCorp Vault:
# Use host network so that possible Vault server addresss at 127.0.0.1 is not
# inside curl container but on host.
login_result=$(docker run --rm --network host dwdraju/alpine-curl-jq \
  curl \
  --request POST \
  -sS \
  --data '{"password": "'"$2"'"}' \
  "$HCV_URL/v1/auth/userpass/login/$1")

# Exit if there was a docker run or curl error:
ec=$?
if [[ $ec -ne 0 ]]; then
  echo "There was a docker run curl error."
  popd > /dev/null
  exit $ec
fi

# Exit if there was Vault error (Vault is sealed, login not successfull, ...):
if [[ "$login_result" == *"errors"* ]]; then
  echo "$login_result"

  # Log extra message if Vault is sealed:
  if [[ "$login_result" == *"Vault is sealed"* ]]; then
    echo "    Vault is sealed e.g. after the vault container restart or the server restart."
    echo "    You need to unseal the Vault via web UI or command line."
  fi

  popd > /dev/null
  exit 111
fi

# Extract HashiCorp Vault client token from response data:
# -r switch is to remove quotes from the result.
token_result=$(echo "$login_result" | docker run -i --rm dwdraju/alpine-curl-jq jq -r .auth.client_token)

# Exit if there was a docker or jq error:
ec=$?
if [[ $ec -ne 0 ]]; then
  echo "There was a docker run jq error."
  popd > /dev/null
  exit $ec
fi

# Exit if token was not found:
if [[ "$token_result" == "null" ]]; then
  echo "Token couldn't be found using jq."
  popd > /dev/null
  exit 1
fi

# Return result (client token):
echo "hcv_token: $token_result"
popd > /dev/null
