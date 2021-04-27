# Skynet Labs Ansible Playbooks

<!-- TOC -->

- [Skynet Labs Ansible Playbooks](#skynet-labs-ansible-playbooks)
  - [Requirements](#requirements)
    - [Ansible](#ansible)
    - [Ansible Hosts](#ansible-hosts)
    - [Ansible Roles and Collections](#ansible-roles-and-collections)
  - [Repository organization](#repository-organization)
  - [Playbook Execution](#playbook-execution)
    - [LastPass Login](#lastpass-login)
    - [Check access](#check-access)
    - [Playbook execution protection](#playbook-execution-protection)
  - [Playbooks](#playbooks)
    - [Server Preparation for Ansible](#server-preparation-for-ansible)
    - [Restart Skynet Webportal](#restart-skynet-webportal)
    - [Deploy Skynet Webportal](#deploy-skynet-webportal)
    - [Rollback Skynet Webportal](#rollback-skynet-webportal)
    - [Get Skynet Webportal Versions](#get-skynet-webportal-versions)
  - [Playbook Live Demos](#playbook-live-demos)

<!-- /TOC -->

## Requirements

### Ansible

Ansible (Ansible Control Machine) is usually installed locally, but to ensure
consistency within our local executions our Ansible scripts do not use local
installation, but execute Ansible Control Machine from a Docker container. For
this the requirement is Docker installed locally.

### Ansible Hosts

Ansible inventory (i.e. list of individual servers behind a load balancer with
their URLs and variables) is not part of this public repository. The
`hosts.ini` inventory file is loaded from LastPass.

`lastpass-cli` (https://github.com/lastpass/lastpass-cli) must be installed
locally. Before or during each Ansible script execution a local user must login
to his/her lastpass account using `lpass` command-line utility from
`lastpass-cli`.

### Ansible Roles and Collections

Ansible playbooks can use libraries (roles and collections) deployed to Ansible
Galaxy or just to Github.

To install all required roles and collections for our playbooks, execute:

`scripts/install-ansible-roles-and-collections.sh`

## Repository organization

* `ansible_collections`
  * ignored by git
  * stores installed Ansible collections
* `inventory`
  * stores `hosts.ini` which defines our servers and their variables
* `my-logs`
  * content ignored by git
  * stores logs (playbook branch/commit used, for portal: docker-compose files
    used, portal, skyd, account versions) from playbook executions executed
    from your machine.
  * `last-portal-versions.yml` could be used to rerun portal deploy on another
    host (more info below).
* `my-vars`
  * content ignored by git (with exception of `portal-versions.sample.do-not-edit.yml`)
  * you can store your variables for playbook executions (more info below)
* `playbooks`
  * stores our Ansible playbooks
  * playbooks should not be executed directly but through `scripts` commands
  * `group_vars`
    * stores group specific var files e.g. for `webportals_dev` and
      `webportals_prod` groups
    * group_vars files are loaded automatically based on host group names
  * `tasks`
    * stores Ansible playbook tasks (reusable Ansible sub-tasks)
  * `templates`
    * stores file templates for playbooks
  * `vars`
    * stores common and playbook specific variables
* `scripts`
  * stores scripts to be executed

## Playbook Execution

### LastPass Login

You can login to LastPass using `lpass` before execution of an Ansible command
e.g. by executing:  
`lpass show ansible-dummy`  
otherwise you have to login to LastPass just after you started Ansible command
execution.
### Check access

To check that you have access to all portals, execute:   
`scripts/portals-ping.sh`

### Playbook execution protection

Playbook can be executed against 1 or 2 hosts
(target servers), when the number of hosts is higher than 2 the playbook stops
to prevent taking down all Skynet servers in case of mistake or error.

## Playbooks

### Server Preparation for Ansible

To prepare a portal server (e.g. `ger-1`) for Ansible execution (installs
Docker SDK and docker-compose SDK for Python, creates devops/logs dir), execute:  
`scripts/portals-prepare.sh --limit ger-1`

If there are no more changes in requirements, this script can be executed
against the host only once (from any Ansible control machine).

If there are new requirements, this script will be updated and should be re-
executed against all portal servers again.

### Restart Skynet Webportal

Playbook:
* Disables health check.
* Waits 5 minutes for load balancer (with dev servers it doesn't wait).
* Stops docker compose services.
* Starts docker compose services.
* Runs portal integration tests.
* Enables health check.

You can see logs in `/home/user/devops/logs` on the server:
* Ansible playbook version.
* skynet-webportal, skyd, accounts versions.
* Used docker-compose files.
* Used `.env` file.
* Status:
  * starting: versions were set, docker compose up is being called
  * started: docker compose up started without error, integration tests started
  * tested: portal intagration tests passed

You can see logs in `./my-logs`
* Ansible playbook version
* skynet-webportal, skyd, accounts versions
* `last-portal-versions.yml` which can be used for portal deployment on another
  host (more info below at: Playbook: Deploy Skynet Portal)

To restart `ger-1` server execute:  
`scripts/portals-restart.sh --limit ger-1`

To restart `ger-1` and `pa-1` server execute:  
`scripts/portals-restart.sh --limit ger-1,pa-1`

Server aliases (`ger-1`, `pa-1`, ...) are stored in `inventory/hosts.ini`.

### Deploy Skynet Webportal

Playbook:
* Disables health check.
* Waits 5 minutes for load balancer (with dev servers it doesn't wait).
* Stops docker compose services.
* Sets portal versions:
  * Checks out skynet-webportal at specific branch/tag/commit.
  * Selects skyd version in `docker-compose.override.yml`.
  * Selects account version in `docker-compose.accounts.yml`.
* Builds docker images.
* Starts docker compose services.
* Runs portal integration tests.
* Enables health check.

For logs see above Playbook: Restart Skynet Webportal.

How to set portal, skyd, accounts versions:

* Go to `my-vars`.
* Copy `portal-versions.sample.do-not-edit.yml` as `portal-versions.yml`
* Start the playbook with `-e @my-vars/portal-versions.yml` (see below).

Alternatively you can use settings from the last playbook execution on
another host:
* Start the playbook with `-e @my-logs/last-portal-versions.yml`

To deploy portal at `ger-1` execute:  
`scripts/portals-deploy.sh --limit ger-1 -e @my-vars/portal-versions.yml`  
or:  
`scripts/portals-deploy.sh --limit ger-1 -e @my-logs/last-portal-versions.yml`

To deploy portal at `ger-1` and `pa-1` execute:  
`scripts/portals-deploy.sh --limit ger-1,pa-1 -e @my-vars/portal-versions.yml`  
or:  
`scripts/portals-deploy.sh --limit ger-1.pa-1 -e @my-logs/last-portal-versions.yml`

### Rollback Skynet Webportal

Playbook:
* Disables health check.
* Waits 5 minutes for load balancer (with dev servers it doesn't wait).
* Stops docker compose services.
* Gets last working portal configuration with passed integration tests (i.e.
  with `status.tested`).
* Updates status of the last working configuration from `status.tested` to
  `status.rollback-tested` so if we perform another rollback, this
  configuration is not repeated.
* Sets portal versions:
  * Checks out skynet-webportal at specific branch/tag/commit.
  * Selects skyd version in `docker-compose.override.yml`.
  * Selects account version in `docker-compose.accounts.yml`.
* Builds docker images.
* Starts docker compose services.
* Runs portal integration tests.
* Enables health check.

For logs see above Playbook: Restart Skynet Webportal.

Playbook chooses last webportal configuration (incl. `.env` file) which passed
integration tests, i.e. status is `status.tested`.

To rollback portal on `ger-1` execute:  
`scripts/portal-rollback.sh --limit ger-1`

To rollback portal on `ger-1` and `pa-1` execute:  
`scripts/portal-rollback.sh --limit ger-1,pa-1`

### Get Skynet Webportal Versions

Playbook:
* Extracts versions from skynet-webportal repo and its files.
* Lists all files modified manually after last Ansible docker re-/start.
* Fails for the portal if it finds any modified files.

To check all portals:
`scripts/portals-get-versions.sh`

To check `ger-1` portal:
`scripts/portals-get-versions.sh --limit ger-1`

To check `ger-1`, `pa-1` and `va-1` portals:
`scripts/portals-get-versions.sh --limit ger-1,pa-1,va-1`

## Playbook Live Demos

* Deploy portal on xyz:  
  https://asciinema.org/a/XMXVFDB96R5FaGgYhoEHVno04
* Restart portal on xyz:  
  https://asciinema.org/a/cIILRC6QHU3vAgzGIpOyc2rS6
* Set versions and redeploy portal on xyz:  
  https://asciinema.org/a/iqIXxYwvdxkaKg7MGaZQ5HLZD
* Rollback to the previous portal configuration with passed integration tests
  on xyz:  
  https://asciinema.org/a/miJgwUK806bpxDPBx5PqRX7l3
