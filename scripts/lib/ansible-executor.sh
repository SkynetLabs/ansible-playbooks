# Exit on any error
set -e

# Set function to be called on exit
trap 'on_exit $?' EXIT

###############################################################################
# on_exit is called at exit, if there was an error it logs an error.
# Globals: none
# Parameters:
# - $1: Script exit code
###############################################################################
on_exit() {
  popd > /dev/null

  # Log an error
  if [ "$1" != "0" ]; then
    echo "ERROR: Error $1"
  else
    echo "SUCCESS: Command finished successfully"
  fi
  exit $1
}

# Get root ansible dir
ans_dir=$(dirname "$0")/..
pushd $ans_dir > /dev/null

# Configs
# Current Ansible Control Machine image
ansible_image='skynetlabs/ansiblecm:ansible-3.1.0-skynetlabs-0.5.0'
default_lpass_timeout_secs=3600

# Set LastPass session timeout
if [ -z "$lpass_timeout" ]; then
  lpass_timeout=$default_lpass_timeout_secs
fi

# Check if we want to restart Ansible CM logging to LastPass or updating wanted image
if [ "$restart_ansible_cm" != true ] && docker ps | grep "\s$ansible_image\s" > /dev/null; then
  echo "Ansible Control Machine is running"
else
  echo "Stopping Ansible Control Machine..."

  # Stop older/non-wanted Ansible container versions if running
  # - list all running docker containers
  # - get only ansible control machines
  # - get container id
  # - stop containers if found
  docker ps -a | grep ansiblecm | awk '{print $1;}' | xargs -r docker stop > /dev/null

  # Start current version
  echo "Starting Ansible Control Machine..."

  # Start Ansible Control Machine and keep it running. This is especially
  # needed for LastPass session.
  docker run -it --rm \
    --entrypoint sleep \
    -e ANSIBLE_STDOUT_CALLBACK=debug \
    -e LPASS_AGENT_TIMEOUT=$lpass_timeout \
    -v ~/.ssh:/root/.ssh:ro \
    -v $(pwd):/tmp/playbook:Z \
    -v $(pwd)/../ansible-private:/tmp/ansible-private \
    -v /tmp/SkynetLabs-ansible:/tmp/SkynetLabs-ansible \
    -v /var/run/docker.sock:/var/run/docker.sock \
    --detach \
    --name ansiblecm \
    $ansible_image \
    infinity > /dev/null
fi

# Execute the playbook from Ansible CM in a Docker container
echo "Executing:"
echo "    $cmd $args"
echo "in a docker container..."

docker exec -it ansiblecm $cmd $args