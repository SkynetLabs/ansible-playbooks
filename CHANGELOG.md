Version Scheme
--------------
Ansible Playbooks uses the following versioning scheme, vX.X.X
 - First Digit signifies a major (compatibility breaking) release
 - Second Digit signifies a major (non compatibility breaking) release
 - Third Digit signifies a minor or patch release

Version History
---------------

Latest:

## Jun 8, 2022:
### v0.2.0
**Key Updates**
- Update playbooks to use Accounts docker image automatically if it is used
  instead of Accounts git branch. This change is backwards compatible with
  using Accounts branches (no user intervention is needed).
- Add loading of custom vars file for setups and deploys
- Add Pinner Service
- Add saving of cluster config
- Add ansible-lint to repo
- Autogenerate `mongo_db_mgkey` and save it to LastPass if it is not set.
- Add docker compose override option for website dockerfile.
- Add the ability to override docker images
- Update all variables to match server_domain and portal_domain conventions
- Add execute commands tasks for combining temporary and long term commands
- Fix running integration tests on authenticated portals (use Skynet API key).
- Add portal_modules to hosts.ini and reference in default values.
- Improve detection if MongoDB replicaset is correctly initialized.
- Add support for Ubuntu 20.04.
- Add syntax-check script and make command
- Add yamllint to repo

**Bugs Fixed**
- Update checks for restarting docker containers.
- Added task for checking if a dictionary had a difference as the built in
  difference method doesn't properly handle all differences.
- Fix blocked/unblock bad host domains variables.
- Fix permissions of `devops` directory on fresh setup.
- Fix elasticsearch permissions recursively.
- Fixed setting default values (backwards compatibility) for `.env` template.
- Fix setting MongoDB mgkey.
- Fix loading/saving from personal (or non-shared) LastPass.
- Fix setting Accounts image or branch in `docker-compose.override.yml`.
- Fix issue when `portal-setup-following` with included deploy didn't honor
  server takedown.
- Fix issue with takedown starting only `sia` service and not `mongo`.
- Enable portal deploys and restarts for takedown portals.
- Move setting iptables rules after docker is installed (`DOCKER-USER` chain is
  present in iptables).
- Fix bug in escaping characters for lastpass personal yml note loading
- Fix bug for seed being defined when it wasn't.
- Add CS sync block for initializing wallet with seed.

**Other**
- Expose `BLOCKER_PORTALS_SYNC` environment variable
- Add (NCMEC) reporting environment variable
- Abuse docker compose file was renamed in `skynet-webportal` repository. For
  backwards compatibility Ansible will now select the present Abuse file
  automatically.
- Replace `ignore_errors` with `failed_when` in setup following to avoid
  confusion around red logs.
- Handle Tor Project exit node list service outage.
- Install Python3 for Ansible if it's not installed on the fresh server.
- Do not wait for uploads/downloads to finish when sia container is restarting.
- Rename optional variable `parallel_deploys` to `parallel_executions`.
- Add an option to run `portals-setup-following` in parallel.
- Remove authentication cookie from integration tests.
- Remove helper `alpine` containers after use.
- Add an option to perform portal deployment in `portals-setup-following`
  playbook controlled by optional variable `deploy_after_setup`. Default
  behavior is do not deploy during `portals-setup-following` execution.
- Log task execution times.
- Updating a comment on redownloading and time intervals for Tor blocklists.

## Mar 8, 2022:
### v0.1.1
**Key Updates**
- Add debian 11 support
- Add m to webportal_docker_compose_files_dict for mongodb compose file
- Added `max_contract_price` and `max_sector_access_price` to default allowance
- Check user has defined public SSH keys in config to load to
  `~/.ssh/authorized_keys` to prevent locking the user out of the server.
- Clean `renter.log` using sed during portal deploys and restarts.
- Document default setup flags for community portal operators.
- On portal deploys or restarts disable portal if free disk space is below
  limit.
- Created docker command playbook to execute one off docker commands on all the
  portals.
- Add check for active downloads to health check disable task
- Add additional funds management playbooks
- Generate `.env` file including MongoDB and Accounts settings.
- Add variable `parallel_deploys` to define how many servers should be deployed in parallel
- Add MongoDB setup (excl. replicaset initialization) to portal setup.
- Add MongoDB setup (excl. replicaset initialization) to portal setup.
- Remove block for synced consensus in `portals-setup-following`
- Add block for synced consensus in `portal-docker-services-start`
- Add support for Blocker module (load it's docker compose file).
- Add support for malware Scanner module.
- Add laybook to block traffic from Tor exit nodes.
- Add a task to portal setup and a separate playbook to block anonymous Tor
  traffic.
- Add tasks for updating the allowance and include in the deploy playbook.
- Switch out simple sleep with waiting for no uploads in siac renter uploads
  when disabling health check.

**Bugs Fixed**
- Fix waiting for docker compose services by excluding waiting for
  `kratos-migrate` container name.
- Fix issue when docker is installed but docker SDK for Python3 is not
  installed.
- Fix MongoDB majority check when replicaset is not yet initialized.
- Update syntax for health-check cli commands from updates on the skynet
  webportal repo [here](https://github.com/SkynetLabs/skynet-webportal/pull/1179)
- Add handling of 490 Module not loaded error in disabling health check.
- Fix bug in the host limit check for handling the case of only one host.
- Fix logging Ansible version for `portal-setup-following` adding missing
  `portal_action`.
- Fixed a server config issue (config not defined) in `portal-setup-following`
  during setting server config default values when server config was not yet
  created in secure backend (LastPass).
- Fix bug where the default case for the `out_of_lb_message` wasn't being
  handled.
- Add handling for personal lastpass accounts with the different path separator for folders.
- Reset SSH connection in `portal-setup-following` to fix (frequent) issue with
  privilege escalation (`become: True` => `Incorrect become password.`)
- Fix bug in the takedown script where the user wasn't probably defined.

**Other**
- Add `ACCOUNTS_LIMIT_ACCESS` to `.env` generation.
- Move Airtable variabled to `.env` file and to webportal common config to
  allow parameterization for portal operators.
- Add script to stop Ansible Control Machine.
- Install and update Ansible requirements (Ansible roles and collections)
  automatically on `requirements.yml` git commit update.
- Blocking incoming traffic IPs/ranges in parallel.
- Add blocking and unblocking incoming traffic from IPs or IP ranges, load
  block and unblock lists from private variables.
- Update `portal-block-skylinks` playbook to remove skylinks from Nginx cache
  and optionally trigger blocking all skylinks from Airtable.
- Update `portal-block-skylinks` playbook to reuse webportal script.
- Add check that all docker services are running (are not restarting) when
  starting/restarting portal services by docker compose.
- Ask user to confirm MongoDB deletion/reset.
- Create webportal user password record in LastPass automatically (if missing).
- Do not include empty (undefined) discord mention vars to `.env` file. This is
  fix for `health-checker.py` (cron script) not reporting to discord.
- Print timestamp to Ansible console log before starting docker services.
- Add playbook to ensure the latest Docker version is used.
- Fix elasticsearch data directory permissions.
- Add generating `.env` vars for Blocker nad Abuse Scanner.
- Increase stopping docker compose timeout so there is enough time for MongoDB
  primary node to step down.
- Increase ufw ssh limits from default 6 hits in 30 seconds to 60 hits in 30
  seconds.
- Use authentication cookie for integration tests.
- Update command to run integration tests after they were reorged in their
  repo.
- Login to LastPass doesn't restarts Ansible CM container.
- Make `SERVER_DOMAIN` mandatory because of Blocker module.
- Allow parallel execution of playbooks in different directories.
- Add a playbook template file for people to start from.
- Remove CockroachDB variables from `.env` template.
- Remove bare sleep after starting docker services now that we actively verify
  the docker services have started.
- Remove `DOMAIN_NAME` from `.env` template.
- Add generation of `SKYNET_DB_REPLICASET` variable in `.env` file.
- Update serverlist version to `v0.0.4`.
- Add support for Abuse module.
- Add playbook to sync directories between portals.
- Tighten allowed outgoing traffic to local networks by ufw firewall.
- Update version of Ansible Control Machine, so we can use `rsync` in our plays.
- Added check that we keep majority (> 50%) of MongoDB replicaset voting
  members online before we stop mongo service during deployments, takedowns,
  restarts etc.

## Sep 13, 2021:
### v0.1.0
Initial release. Repo README contains full list of playbooks and stands as the
initial Changelog of additions.
