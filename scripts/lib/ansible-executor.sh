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

# xxx
# # Execute the playbook from Ansible CM in Docker container
# echo "Executing: '$cmd $args' in a docker container..."
# docker run -it --rm \
#   --entrypoint $cmd \
#   -e ANSIBLE_STDOUT_CALLBACK=debug \
#   -v ~/.ssh:/root/.ssh:ro \
#   -v $(pwd):/tmp/playbook:Z \
#   -v $(pwd)/../ansible-private:/tmp/ansible-private \
#   -v /tmp/SkynetLabs-ansible:/tmp/SkynetLabs-ansible \
#   -v /var/run/docker.sock:/var/run/docker.sock \
#   skynetlabs/ansiblecm:ansible-3.1.0-skynetlabs-0.2.0 \
#   $args

# Handle LastPass login. LastPass session is kept inside docker container.
ansible_image='firyx/ansiblecm:ansible-3.1.0-skynetlabs-0.3.0'

if docker ps | grep "\s$ansible_image\s"; then
  echo "Ansible Control Machine version $ansible_image is already running"
else
  # Stop older/non-wanted Ansible container versions if running
  # - list all running docker containers
  # - get only ansible control machines
  # - exclude wanted image version
  # - get container id
  # - stop containers if found
  echo "Stopping unwanted Ansible Control Machine versions"
  docker ps -a | grep ansiblecm | grep -v "\s$ansible_image\s" | awk '{print $1;}' | xargs -r docker stop

  # Start current version
  echo "Starting Ansible Control Machine version $ansible_image"
  read -p "Enter your LastPass username (email): " lpass_login
  echo "NOTE: If you get stuck at LastPass master password (e.g. entered wrong email), you need:"
  echo
  echo "    docker stop <container name>"
  echo
  docker run -it --rm \
    --entrypoint /bin/sh \
    -e ANSIBLE_STDOUT_CALLBACK=debug \
    -v ~/.ssh:/root/.ssh:ro \
    -v $(pwd):/tmp/playbook:Z \
    -v $(pwd)/../ansible-private:/tmp/ansible-private \
    -v /tmp/SkynetLabs-ansible:/tmp/SkynetLabs-ansible \
    -v /var/run/docker.sock:/var/run/docker.sock \
    --name ansiblecm \
    $ansible_image \
    -c "lpass login $lpass_login && sleep infinity"
fi

# # xxx switch from firyx to skynetlabs
# # Execute the playbook from Ansible CM in Docker container
# echo "Executing: '$cmd $args' in a docker container..."

# docker exec -it ansiblecm $cmd $args
  