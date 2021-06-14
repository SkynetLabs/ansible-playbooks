# Skynet Labs Ansible Playbooks

<!-- TOC -->

- [Skynet Labs Ansible Playbooks](#skynet-labs-ansible-playbooks)
    - [Requirements](#requirements)
        - [Git repository ansible-private](#git-repository-ansible-private)
        - [Docker](#docker)
        - [Ansible Roles and Collections](#ansible-roles-and-collections)
    - [Repository Organization](#repository-organization)
    - [Playbook Execution](#playbook-execution)
        - [Check Access](#check-access)
        - [LastPass Login](#lastpass-login)
    - [Playbooks](#playbooks)
        - [Get Webportal Status](#get-webportal-status)
        - [Restart Skynet Webportal](#restart-skynet-webportal)
        - [Deploy Skynet Webportal](#deploy-skynet-webportal)
            - [Deploy Playbook Actions:](#deploy-playbook-actions)
            - [Portal Modules](#portal-modules)
            - [How to set portal, skyd, accounts versions:](#how-to-set-portal-skyd-accounts-versions)
        - [Rollback Skynet Webportal](#rollback-skynet-webportal)
        - [Get Skynet Webportal Versions](#get-skynet-webportal-versions)
        - [Set Allowance](#set-allowance)
        - [Run Integration Tests](#run-integration-tests)
    - [Playbook Live Demos](#playbook-live-demos)
    - [Troubleshooting](#troubleshooting)
        - [Role Not Installed](#role-not-installed)
        - [Unreachable Host](#unreachable-host)

<!-- /TOC -->

## Requirements

### Git repository ansible-private

Git repository `ansible-private` must be sibling of this repository
`ansible-playbooks`.

`ansible-private` contains `inventory/hosts.ini` file
which defines a list of our servers which we target with our Ansible scripts.
`hosts.ini` definition is quite flexible, we can e.g. define server subgroups
if needed etc. Also if you need a short term change in the `hosts.ini` you can
edit the file locally according to your needs.

### Docker

Docker installation on your local machine is required.

Our scripts execute Ansible from a Docker container that is automatically
pulled from Docker Hub. Local Ansible installation is NOT required.

### Ansible Roles and Collections

Ansible playbooks can use libraries (roles and collections) deployed to Ansible
Galaxy or just to Github. The roles and collections a playbook uses must be
installed prior to the playbook execution.

To install all roles and collections required for Skynet Labs playbooks, execute:

`scripts/install-ansible-roles-and-collections.sh`

## Repository Organization

* `ansible_collections`
  * ignored by git
  * stores installed Ansible collections
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
* `roles`
  * ignored by git
  * stores installed Ansible roles
* `scripts`
  * stores scripts to be executed

## Playbook Execution

### Check Access

To check that you have access to all portals, execute:   
`scripts/portals-ping.sh`

### LastPass Login

Some playbooks require you to login to LastPass. If you get error message:
```
Your LastPass session is not active.
Execute:

    scripts/lastpass-login.sh
```
execute `scripts/lastpass-login.sh` and follow the instructions.

## Playbooks

### Get Webportal Status

Playbook:
* Gets `skynet-webportal` repository version (git tag, branch or commit).
* Gets skyd version from `docker-compose.override.yml`.
* Gets Accounts version from `docker-compose.override.yml`.
* Gets list of all files in `skynet-webportal` directory modified after the
  last Ansible deployment.
* Checks that URL `https://skapp.hns.<portal domain>` returns status code 200.
* Sends the result to Skynet Labs Discord channel `#ansible-logs` defined by
  `discord_ansible_logs_webhook` webhook variable.

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

You can see logs locally in `./my-logs`
* Ansible playbook version
* skynet-webportal, skyd, accounts versions
* `last-portal-versions.yml` which can be used for portal deployment on another
  host (more info below at: Playbook: Deploy Skynet Portal)

To restart `eu-ger-1` server execute:  
`scripts/portals-restart.sh --limit ger-1`

To restart `eu-ger-1` and `us-pa-1` server execute:  
`scripts/portals-restart.sh --limit eu-ger-1,us-pa-1`

Server aliases (`eu-ger-1`, `us-pa-1`, ...) are stored in `inventory/hosts.ini`.

### Deploy Skynet Webportal

#### Deploy Playbook Actions:
* Disables health check.
* Waits 5 minutes for load balancer (with dev servers it doesn't wait).
* Stops docker compose services.
* Sets portal versions:
  * Checks out skynet-webportal at specific branch/tag/commit.
  * Selects skyd version in `docker-compose.override.yml`.
  * Selects account version in `docker-compose.accounts.yml`.
* Builds docker images.
* Starts docker compose services.
* Waits for Sia full setup finished.
* Waits for Sia `/daemon/ready` (if the endpoint is available).
* Runs portal integration tests.
* Enables health check.

For logs see above Playbook: Restart Skynet Webportal.

#### Portal Modules

Deployment of portal modules (Jaeger, Accounts) depends on `PORTAL_MODULES`
setting in `.env` file in `skynet-webportal` directory.

When `PORTAL_MODULES` setting is missing or is set to empty string, only base
portal services defined in `docker-compose.yml` and in (if the file is present)
`docker-compose.override.yml` are deployed.

`PORTAL_MODULES` can contain flags `a` or `j` to include deployment of Accounts
or Jaeger defined in `docker-compose.accounts.yml` or
`docker-compose.override.yml`files. Order of flags is significant, i.e.
Accounts and Jaeger docker compose files will be loaded according to the flag
order in `PORTAL_MODULES`.

#### How to set portal, skyd, accounts versions:

* Go to `my-vars`.
* Copy `portal-versions.sample.do-not-edit.yml` as `portal-versions.yml`
* Set `skynet-webportal`, `skyd` and `accounts` versions you want to deploy in
  `portal-versions.yml` (or whatever you named the file).
* Start the playbook with `-e @my-vars/portal-versions.yml` (see below).

Alternatively you can use settings from the last playbook execution on
another host:
* Start the playbook with `-e @my-logs/last-portal-versions.yml`

To deploy portal at `eu-ger-1` execute:  
`scripts/portals-deploy.sh -e @my-vars/portal-versions.yml --limit eu-ger-1`  
or:  
`scripts/portals-deploy.sh -e @my-logs/last-portal-versions.yml --limit eu-ger-1`

To deploy portal at `eu-ger-1` and `us-pa-1` execute:  
`scripts/portals-deploy.sh -e @my-vars/portal-versions.yml --limit eu-ger-1,us-pa-1`  
or:  
`scripts/portals-deploy.sh -e @my-logs/last-portal-versions.yml --limit eu-ger-1.us-pa-1`

### Rollback Skynet Webportal

!!! WARNING:  
Using this playbook is DANGEROUS, because you might try to rollback to
versions that crossed compatibility border. Use only if you know what are you
doing!!!

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

To rollback portal on `eu-ger-1` execute:  
`scripts/portal-rollback.sh --limit eu-ger-1`

To rollback portal on `eu-ger-1` and `us-pa-1` execute:  
`scripts/portal-rollback.sh --limit eu-ger-1,us-pa-1`

### Get Skynet Webportal Versions

Playbook:
* Extracts versions from skynet-webportal repo and its files.
* Lists all files modified manually after last Ansible docker re-/start.
* Fails for the portal if it finds any modified files.

To check all portals:
`scripts/portals-get-versions.sh`

To check `eu-ger-1` portal:
`scripts/portals-get-versions.sh --limit eu-ger-1`

To check `eu-ger-1`, `us-pa-1` and `us-va-1` portals:
`scripts/portals-get-versions.sh --limit eu-ger-1,us-pa-1,us-va-1`

### Set Allowance

Playbook:
* Sets allowance defined in `playbooks/portals-set-allowance.yml` > `vars` >
  `allowance` on the portal server(s).

Note: `--limit` must be used, it's not possible to set allowance on all
`portals_dev` and `portals_prod` servers at once.

To run:  
`scripts/portals-set-allowance.sh --limit portals_prod`   
`scripts/portals-set-allowance.sh --limit eu-ger-3`

### Run Integration Tests

Playbook:
* Checks out `skynet-js` repo locally.
* Runs integration tests from local docker container against portal.

Note: `--limit` must be used, it's not possible to set allowance on all
`portals_dev` and `portals_prod` servers at once.

To run:  
`scripts/portals-run-integration-tests.sh --limit portals_prod`  
`scripts/portals-run-integration-tests.sh --limit eu-ger-3`

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

## Troubleshooting

### Role Not Installed

Example error:
```
ERROR! the role 'geerlingguy.docker' was not found in /tmp/playbook/playbooks/roles:/tmp/playbook/roles:/tmp/playbook/playbooks
```

Cause:  
The role the playbook is using is not installed.

Fix:  
Install all required roles and collections by executing:  
`scripts/install-ansible-roles-and-collections.sh`

### Unreachable Host

Example error:
```
fatal: [fin-1]: UNREACHABLE! => {
    "changed": false,
    "unreachable": true
}

MSG:

Data could not be sent to remote host "eu-fin-1.siasky.net".
Make sure this host can be reached over ssh: ...
```

This error means that your local Ansible Control Machine can't reach the
specified host. Either the host is not set correctly in `hosts.ini` file SSH
connection to the host can't be established or was lost.

In the second case, try to rerun the playbook for the affected host, i.e. with
`--limit <your-failing-host>`.
