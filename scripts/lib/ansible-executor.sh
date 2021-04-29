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
  popd

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
pushd $ans_dir

# Load inventory from LastPass
if [[ "$load_hosts" != "false" ]]; then
  echo Loading hosts.ini from LastPass...
  lpass show --notes hosts.ini > inventory/hosts.ini
fi

# Execute the playbook from Ansible CM in Docker container
echo "Executing: '$cmd $args' in a docker container..."
docker run -it --rm \
  --entrypoint $cmd \
  -e ANSIBLE_STDOUT_CALLBACK=debug \
  -v ~/.ssh:/root/.ssh:ro \
  -v $(pwd):/tmp/playbook:Z \
  -v /tmp:/tmp \
  -v /var/run/docker.sock:/var/run/docker.sock \
  skynetlabs/ansiblecm:ansible-3.1.0-skynetlabs-0.2.0 \
  $args