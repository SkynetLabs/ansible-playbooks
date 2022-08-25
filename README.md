[![Lint](https://github.com/SkynetLabs/ansible-playbooks/actions/workflows/lint.yml/badge.svg)](https://github.com/SkynetLabs/ansible-playbooks/actions/workflows/lint.yml)

# Skynet Labs Ansible Playbooks

> The table of contents for this README can be accessed from the menu icon by `README.md`

This repo is a collection of ansible playbooks used to manage a Skynet
Webportal. For more information of setting up a Skynet Webportal checkout the
documentation [here](https://docs.siasky.net/webportal-management/overview).

## Requirements

Clone this repository to the machine you plan to use to run the ansible
playbooks from. This can be either your local machine or a dedicated deploy
machine. There is currently no need to fork this repo.

### Git repository ansible-private

Head over to the
[ansible-private-sample](https://github.com/SkynetLabs/ansible-private-sample)
repo and follow the process of coping that repo outlined in the README.

`ansible-private` contains `inventory/hosts.ini` file which defines a list of
our servers which we target with our Ansible scripts. `hosts.ini` definition is
quite flexible, we can e.g. define server subgroups if needed etc. Also if you
need a short term change in the `hosts.ini` you can edit the file locally
according to your needs.

### Docker

Docker installation on your local machine is required.

Our scripts execute Ansible from a Docker container that is automatically
pulled from Docker Hub. Local Ansible installation is NOT required.

### Ansible Roles and Collections

Ansible playbooks can use libraries (roles and collections) deployed to Ansible
Galaxy or just to Github. The roles and collections a playbook uses must be
installed prior to the playbook execution.

Our Ansible scripts are installing Ansible roles and collections (defined in
`requirements.yml`) automatically.

When you are developing Ansible playbooks and don't want yet to commit new
`requirements.yml` file, you can force installing new/updated roles and
collections by deleting `my-logs/requirements-installed.txt` file and executing
a playbook.

## Repository Organization

- `ansible_collections`
  - ignored by git
  - stores installed Ansible collections
- `my-logs`
  - content ignored by git
  - stores logs (playbook branch/commit used, for portal: docker-compose files
    used, portal, skyd, account versions) from playbook executions executed
    from your machine.
  - `last-portal-versions.yml` could be used to rerun portal deploy on another
    host (more info below).
- `my-vars`
  - content ignored by git (with exception of `config-sample-do-not-edit.yml`)
  - you can store your variables for playbook executions (more info below)
- `playbooks`
  - stores our Ansible playbooks
  - playbooks should not be executed directly but through `scripts` commands
  - `group_vars`
    - stores group specific var files e.g. for `webportals_dev` and
      `webportals_prod` groups
    - group_vars files are loaded automatically based on host group names
  - `tasks`
    - stores Ansible playbook tasks (reusable Ansible sub-tasks)
  - `templates`
    - stores file templates for playbooks
  - `vars`
    - stores common and playbook specific variables
- `roles`
  - ignored by git
  - stores installed Ansible roles
- `scripts`
  - stores scripts to be executed

## Playbook Execution

### Check Access

To check that you have access to all portals with the [portal-ping](#portal-ping) script.

### LastPass Login

Some playbooks might use variables stored in LastPass or you can store and
reference variables in LastPass yourself (e.g. in vars files).

Execution of playbooks using variables stored in LastPass requires you to login
to LastPass prior to the playbooks execution.

You will know, that the playbook requires active LastPass session if you get
one of the error messages mentioned in
[Troubleshooting > LastPass Session Not Active](#lastpass-session-not-active).

To login to LastPass, execute `scripts/lastpass-login.sh` and follow the
instructions to login to LastPass.

After the login is successful, your LastPass session is active and
you can execute playbooks as usually.

**NOTE** if you update files or variables in LastPass, you will need to re-run
the login script to refresh your session to be able to see the updates.

## Playbooks

### Portal Ping

#### Playbook Actions

This playbook pings a portal to check if it is accessible.

**NOTE** The ansible `ping` module is going to try and ping `user@host`. So if
you have not run the [`portal-setup-initial`](#playbook-portals-setup-initial)
script yet to initialize the user, you should include the `-u root` option. Or,
if your server was initialized with a non root user, use that username, i.e.
`-u debian`.

#### Execution

`scripts/portals-ping.sh --limit eu-ger-1`  
`scripts/portals-ping.sh -u root --limit eu-ger-1`  
`scripts/portals-ping.sh -u debian --limit eu-ger-1`

### Get Webportal Status

Playbook:

- Gets `skynet-webportal` repository version (git tag, branch or commit).
- Gets skyd version from `docker-compose.override.yml`.
- Gets Accounts version from `docker-compose.override.yml`.
- Gets list of all files in `skynet-webportal` directory modified after the
  last Ansible deployment.
- Checks that URL `https://skapp.hns.<portal domain>` returns status code 200.
- Sends the result to Skynet Labs Discord channel `#ansible-logs` defined by
  `discord_ansible_logs_webhook` webhook variable.

### Restart Skynet Webportal

Playbook:

- Disables health check.
- Waits 5 minutes for load balancer (with dev servers it doesn't wait).
- Stops docker compose services.
- Starts docker compose services.
- Runs portal integration tests.
- Enables health check.

You can see logs in `/home/user/devops/logs` on the server:

- Ansible playbook version.
- skynet-webportal, skyd, accounts versions.
- Used docker-compose files.
- Used `.env` file.
- Status:
  - starting: versions were set, docker compose up is being called
  - started: docker compose up started without error, integration tests started
  - tested: portal intagration tests passed

You can see logs locally in `./my-logs`

- Ansible playbook version
- skynet-webportal, skyd, accounts versions
- `last-portal-versions.yml` which can be used for portal deployment on another
  host (more info below at: Playbook: Deploy Skynet Portal)

To restart `eu-ger-1` server execute:  
`scripts/portals-restart.sh --limit ger-1`

To restart `eu-ger-1` and `us-pa-1` server execute:  
`scripts/portals-restart.sh --limit eu-ger-1,us-pa-1`

Server aliases (`eu-ger-1`, `us-pa-1`, ...) are stored in `inventory/hosts.ini`.

### Deploy Skynet Webportal

#### Deploy Playbook Actions:

- Disables health check.
- Waits 5 minutes for load balancer (with dev servers it doesn't wait).
- Stops docker compose services.
- Sets portal versions:
  - Checks out skynet-webportal at specific branch/tag/commit.
  - Selects skyd version in `docker-compose.override.yml`.
  - Selects account version in `docker-compose.accounts.yml`.
- Builds docker images.
- Starts docker compose services.
- Waits for Sia full setup finished.
- Waits for Sia `/daemon/ready` (if the endpoint is available).
- Waits for Sia Blockchain to be synced.
- Runs portal integration tests.
- Runs portal health check.
- Enables health check.

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

#### How to set portal, skyd, accounts versions

- Go to `my-vars`.
- Copy `config-sample-do-not-edit.yml` as `config.yml`
- Set `skynet-webportal`, `skyd` and `accounts` versions you want to deploy in
  `config.yml` (or whatever you named the file).
- Start the playbook with `-e @my-vars/config.yml` (see below).

Alternatively you can use settings from the last playbook execution on
another host:

- Start the playbook with `-e @my-logs/last-portal-versions.yml`

To deploy portal at `eu-ger-1` execute:  
`scripts/portals-deploy.sh -e @my-vars/config.yml --limit eu-ger-1`  
or:  
`scripts/portals-deploy.sh -e @my-logs/last-portal-versions.yml --limit eu-ger-1`

To deploy portal at `eu-ger-1` and `us-pa-1` execute:  
`scripts/portals-deploy.sh -e @my-vars/config.yml --limit eu-ger-1,us-pa-1`  
or:  
`scripts/portals-deploy.sh -e @my-logs/last-portal-versions.yml --limit eu-ger-1.us-pa-1`

#### How to enable parallel deployments

By default portals-deploy playbook performs deployments one server at a time
(rolling updates/deploys). You can enable parallel deployments (deploy to the
given number of hosts in parallel) by setting optional `parallel_executions`
variable in used `config.yml`.

Example `config.yml`:

```yaml
---
portal_repo_version: "deploy-2021-08-24"
portal_skyd_version: "deploy-2021-08-24"
portal_accounts_version: "deploy-2021-08-23"

parallel_executions: 3
```

#### How to Set Deploy Batch

We can split deployment into several batches, so we can deploy e.g. in 3
batches during 3 days where we target 1/3 of hosts in each batch. To set batch
size (how many deployment subgroups of the hosts we want to create) and batch
number (which of the subgroup we want to deploy to), edit your portal versions
file (described above) which you reference during playbook execution.

Technical note: Hosts from the selected inventory group are assigned to the
batches based on modulo of their index divided by batch size, so in one batch we
target just a part of hosts in the same region (when they are ordered by region
in the selected inventory group).

Example of settings with 3 batches, day 1 execution:

```yaml
<portal versions settings>...

batch_size: 3
batch_number: 1
```

Day 2 execution:

```yaml
<portal versions settings>...

batch_size: 3
batch_number: 2
```

Day 3 execution:

```yaml
<portal versions settings>...

batch_size: 3
batch_number: 3
```

When you want to target all hosts defined with `--limit` argument and don't
want to divide deployment into batches, set:

```yaml
<portal versions settings>...

batch_size: 1
batch_number: 1
```

### Stop A Skynet Webportal

#### Playbook Actions

This playbook shuts down a portal by removing it from the load balancer and
stopping all the docker services.

#### Execution

`scripts/portals-stop.sh --limit eu-ger-1`

### Deny Public Access

There are valid use cases where portal operator would want to deny public access to skynet endpoints for downloading or uploading a file and accessing the skynet registry. This applies to both anonymous portals and portals that require either authentication or subscription.

Portal that denies public access continues to run normally while only the aforementioned endpoints are denied when accessing from public ip addresses - accessing from host or private networks will still work so health checks, locally running integration tests and executing curl from that machine will return successful response.

#### Denying public access on a single server

Portals should define an environment variable `DENY_PUBLIC_ACCESS` that is responsible for denying public access and is stored in`.env` file. By default this setting is set to `false` but portal operator can toggle it to `true`. This can be automated using ansible by setting `deny_public_access` variable in `inventory/hosts.ini` file (it is located `ansible-private` directory).

Inline hosts.ini setting example:

```ini
[skynet_servers]
server-01 ansible_host=server-01.example.com deny_public_access=true
```

Group hosts.ini setting example:

```ini
[skynet_servers:vars]
deny_public_access=true
```

Once the `deny_public_access` is changed, `DENY_PUBLIC_ACCESS` will be updated on the server during next deploy using `portals-setup-following.sh` script.

:warning: Use `portals-setup-following.sh` script when deploying, regular deploy using `portals-deploy.sh` script will not update `.env` file!

#### Restoring public access

Once public access can be restored, portal operator should remove (or set to `false`) the `deny_public_access` variable from `inventory/hosts.ini` file and run `portals-setup-following.sh` script.

:warning: Use `portals-setup-following.sh` script when deploying, regular deploy using `portals-deploy.sh` script will not update `.env` file!

### Rollback Skynet Webportal

!!! WARNING:  
Using this playbook is DANGEROUS, because you might try to rollback to
versions that crossed compatibility border. Use only if you know what are you
doing!!!

Playbook:

- Disables health check.
- Waits for all uploads/downloads to finish (max 5 minutes), on dev servers it
  doesn't wait.
- Stops docker compose services.
- Gets last working portal configuration with passed integration tests (i.e.
  with `status.tested`).
- Updates status of the last working configuration from `status.tested` to
  `status.rollback-tested` so if we perform another rollback, this
  configuration is not repeated.
- Sets portal versions:
  - Checks out skynet-webportal at specific branch/tag/commit.
  - Selects skyd version in `docker-compose.override.yml`.
  - Selects account version in `docker-compose.accounts.yml`.
- Builds docker images.
- Starts docker compose services.
- Runs portal integration tests.
- Enables health check.

For logs see above Playbook: Restart Skynet Webportal.

Playbook chooses last webportal configuration (incl. `.env` file) which passed
integration tests, i.e. status is `status.tested`.

To rollback portal on `eu-ger-1` execute:  
`scripts/portal-rollback.sh --limit eu-ger-1`

To rollback portal on `eu-ger-1` and `us-pa-1` execute:  
`scripts/portal-rollback.sh --limit eu-ger-1,us-pa-1`

### Get Skynet Webportal Versions

Playbook:

- Extracts versions from skynet-webportal repo and its files.
- Lists all files modified manually after last Ansible docker re-/start.
- Fails for the portal if it finds any modified files.

To check all portals:
`scripts/portals-get-versions.sh`

To check `eu-ger-1` portal:
`scripts/portals-get-versions.sh --limit eu-ger-1`

To check `eu-ger-1`, `us-pa-1` and `us-va-1` portals:
`scripts/portals-get-versions.sh --limit eu-ger-1,us-pa-1,us-va-1`

### Set Allowance Max Storage Price, Max Contract Price, and Max Sector Access

Price

Playbook:

- Sets allowance defined in
  `playbooks/portals-set-allowance-price-controls.yml` > `vars` >
  `max_storage_price`, `max_contract_price`, `max_sector_access_price`
  on the portal server(s).

Notes:

- `--limit` must be used, it's not possible to set allowance on all
  `portals_dev` and `portals_prod` servers at once.
- Format of `max_storage_price`, `max_contract_price`, `max_sector_access_price`
  value must be same as is expected by executing
  `docker exec sia siac renter setallowance --max-storage-price --max-contract-price --max-sector-access-price`

To run:  
`scripts/portals-set-allowance-price-controls.sh --limit webportals_prod`  
`scripts/portals-set-allowance-price-controls.sh --limit eu-ger-3`

### Block Portal Skylinks

Playbook:

- Prompts if you want to block all skylinks from Airtable too.
- Blocks portal skylinks defined in `skylinks_block_list` variable in Sia.
- Removes skylinks defined in `skylinks_block_list` variable from Nginx cache.
- Starts blocking all skylinks from Airtable (same script as is run from cron)
  if prompt answer starts with `y` or `Y`.

Preparation:  
Create a file `skylinks-block.yml` in `my-vars` directory with defined
`skylinks_block_list` variable.

Example `skylinks-block.yml` content:

```yaml
---
skylinks_block_list:
  - <skylink 1>
  - <skylink 2>
```

To run:  
`scripts/portals-block-skylinks.sh -e @my-vars/skylinks-block.yml --limit eu-fin-1`  
`scripts/portals-block-skylinks.sh -e @my-vars/skylinks-block.yml --limit webportals_prod`

If you just want to run Airtable block script, you can leave `skynet_block_list`
empty:

```yaml
---
skylinks_block_list: []
```

or do not define `skynet_block_list` at all and run the script this way:  
`scripts/portals-block-skylinks.sh --limit eu-fin-1`  
`scripts/portals-block-skylinks.sh --limit webportals_prod`

### Unblock Portal Skylinks

Playbook:

- Unblocks portal skylinks defined in `skylinks_unblock_list` variable.

Preparation:  
Create a file `skylinks-unblock.yml` in `my-vars` directory with defined
`skylinks_unblock_list` variable.

Example `skylinks-unblock.yml` content:

```yaml
---
skylinks_unblock_list:
  - 3AF1z9V61r5w1A_5oCnxQ5gPbU4Ymn0IWlMNicPBxty6zg
  - 3AFseaFttl533Ma3hmkUEOhvx7dQgklcnS4-Nhx3LPyrMg
  - 3AHuMny_l2DqQUZty6OdhW-MXnDjT411rryLuQVWa0Sw_g
```

To run:  
`scripts/portals-unblock-skylinks.sh -e @my-vars/skylinks-unblock.yml --limit eu-fin-1`  
`scripts/portals-unblock-skylinks.sh -e @my-vars/skylinks-unblock.yml --limit webportals_prod`

### Block and Unblock Incoming Traffic to Portals

Playbook:

- Blocks incoming traffic from IPs or IP ranges defined in
  `private_vars.incoming_ips_ip_ranges_block` list.
- Unblocks previously blocked incoming traffic from IPs or IP ranges defined in
  `private_vars.incoming_ips_ip_ranges_unblock` list.

Preparation:  
`private_vars_file` defined in `webportals.yml` defines a filepath where
private variables are stored. Default path is in `ansible-private` repository,
in `private-vars/private-vars.yml` file. In this file there are defined 2 lists
of IPs or Ip ranges: `incoming_ips_ip_ranges_block` and
`incoming_ips_ip_ranges_unblock`. To block an IP/IP range, add it to the block
list, execute the playbook and keep the IP/IP range in the list so it is
blocked also later on newly setup portals. To unblock the previously blocked
IP/IP range, remove it from the block list and add it to the unblock list and
execute the playbook.

Example `private-vars.yml` file:

```yaml
incoming_ips_ip_ranges_block:
  - "1.2.3.4"
  - "4.5.6.7"
  - "11.22.33.0/24"
  - "22.33.44.0/24"

incoming_ips_ip_ranges_unblock: []
```

Example `private-vars.yml` file to unblock previously blocked IPs/IP ranges:

```yaml
incoming_ips_ip_ranges_block:
  - "1.2.3.4"
  - "11.22.33.0/24"

incoming_ips_ip_ranges_unblock:
  - "4.5.6.7"
  - "22.33.44.0/24"
```

To run:  
`scripts/portals-block-unblock-incoming-traffic.sh --limit eu-fin-1`  
`scripts/portals-block-unblock-incoming-traffic.sh --limit webportals_prod`

### Run Integration Tests

Playbook:

- Checks out `skynet-js` repo locally.
- Runs integration tests from local docker container against portal.

Note: `--limit` must be used, it's not possible to run integration tests on all
`portals_dev` and `portals_prod` servers at once.

To run:  
`scripts/portals-run-integration-tests.sh --limit portals_prod`  
`scripts/portals-run-integration-tests.sh --limit eu-ger-3`

### Run Health Checks

Playbook:

- Runs health checks on portal.

Note: `--limit` must be used, it's not possible to run health checks on all
`portals_dev` and `portals_prod` servers at once.

To run:  
`scripts/portals-run-health-checks.sh --limit portals_prod`  
`scripts/portals-run-health-checks.sh --limit eu-ger-3`

### Setup Portal from Scratch

Setup process requires 3 playbooks:

- `portals-setup-initial.sh` (run once)
- `portals-setup-following.sh`
- `portals-deploy.sh`

#### Playbook portals-setup-initial

Requires:

- Server side
  - Fresh `Debian 10 minimal` server
  - SSH key added to `root` authorized keys
- Ansible inventory
  - Ansible hostname (e.g. `eu-fin-5`) added to (one of) `webportals` group
    - Example: `us-va-3 ansible_host=us-va-3.siasky.net`
  - `initial_root_like_user` set if the server is initialized with a non `root` user i.e. `debian` as the initial root user.
    - Example: `us-va-6 ansible_host=us-va-6.siasky.net initial_root_like_user=debian`
- LastPass
  - Desired password added for the user `user`
  - Active LastPass session (see `LastPass Login` section above)

Playbook (as `root`):

- Installs `sudo`
- Creates passworded user
- Adds SSH keys from `skynet-webportal` repo (defined by `webportal_user_authorized_keys` variable in `my-vars/config.yml`)
- Performs basic security setup
  - Disables `root` access, ...

This playbook can be run successfully just once, then root access is disabled.

Execute (e.g. on `eu-fin-5`):  
`scripts/portals-setup-initial.sh --limit eu-fin-5`

If you are using any no default variable values, i.e. LastPass folder names or `webportal_user_authorized_keys`,
include your config file in the command.
`scripts/portals-setup-initial.sh -e @my-vars/config.yml --limit eu-fin-5`

#### Playbook portals-setup-following

Requires:

- Active LastPass session (see `LastPass Login` section above)
- Portal versions
  - See `How to set portal, skyd, accounts versions` section above
  - Portal versions should be the same or lower than portal versions that will
    be later deployed to the portal
  - It is recommended to use the same portal versions yml file during setup and then
    during the first deployment

Playbook:

- Prepares the server
  - Performs basic security setup
  - Performs ufw firewall setup
  - Installs python3-pip, git, docker, Python modules
  - Sets timezone
  - Updates hostname
- Sets dev tools
  - Setup dotfiles
  - TBD: Setup dev tools
- Sets portal (simplified)
  - Checkout `skynet-webportal` repo
  - Load existing portal config (if exists) from LastPass otherwise generate
    portal config and save it to LastPass
  - Always recreate `.env` file from `.env.j2` template and portal config
  - Start sia container if not running, restart if config changed
  - Init new wallet (if not done previously)
  - Init wallet (with existing seed if exists, takes time, can timeout)
  - Unlock wallet
  - Set default allowance
  - Setup health checks
- If variable `deploy_after_setup` is set to True
  - Portal deployment is performed. Then you do not need to run `portals-deploy`
    playbook separately, it's tasks are performed within `portal-setup-following`
    playbook.
- If variable `deploy_after_setup` is not set at all (it is default behaviur) or
  is set to False
  - Portal deployment is not performed. You need to run `portals-deploy` playbook
    separately to bring portal online.

Execute (e.g. on `eu-fin-5`):
`scripts/portals-setup-following.sh -e @my-vars/config.yml --limit eu-fin-5`

#### Playbook portals-deploy

To finish portal setup and deployment execute portal deploy playbook (see
separate section above).

**NOTE** You should give your node enough time to sync the Sia blockchain and
*form file contracts before running the deploy script. Otherwise the health
*checks will fail as your node is not ready to upload and download

### Run Docker Command

Playbook:

- Run a docker command on portals define in `docker_commands` variable.

Preparation:  
Defined a `docker_commands` variable in your `portal_versions.yml` file.

Example:

```yaml
---
docker_commands:
  - "docker exec sia siac"
  - "docker exec sia siac renter"
```

To run:  
`scripts/portals-docker-command.sh -e @my-vars/config.yml --limit eu-fin-1`

The deploy script also supports the docker command execution:
`scripts/portals-deploy.sh -e @my-vars/config.yml --limit eu-fin-1`

### Update Allowance

Playbook:

- Automatically update the allowance of a webportal based on the same
  calculations of the Skynet dashboard.

To run:  
`scripts/portals-update-allowance.sh --limit eu-fin-1`

The deploy script also supports the update allowance functionality. To do so,
define a list of webportals you would like to enable auto updating the
allowance on with `update_allowance`. This allows updating some webportals that
need updating during deployments.

Example:

```yaml
---
update_allowance:
  - eu-fin-1
  - eu-fin-2
```

`scripts/portals-deploy.sh -e @my-vars/config.yml --limit depl_batch1`

### Send Funds

Playbook:

- Send funds from one portal to another.

Preparation:  
Define a `wallet_fund_amount` variable in your `portal_versions.yml` file to
define how much should be sent between the portals. Define a `funding_portal`
variable in your `portal_versions.yml` file to define the portal that should send
the funds.

Example:

```yaml
---
wallet_fund_amount: 100KS
funding_portal: eu-pol-4
```

To run:  
`scripts/portals-send-funds.sh -e @my-vars/portal_versions.yml --limit eu-fin-1`

In this example, `eu-pol-4` will send 100KS to `eu-fin-1`.

### Migrate Data Between Secrets Storages

This playbook can migrate secrets records between any of secrets storages
(LastPass <=> plaintext files <=> HashiCorp Vault) for portal cluster(s).

Playbook:

- Gets user input which portal cluster to migrate
  (prompt is skipped if only one cluster is defined in hosts.ini).
- Gets user input on source and destination secrets storage.
- Performs the following checks and fails if not ok (manual fix is needed)
  - Destination config paths are defined
  - Configured cluster configs lists (their lengths) must match between source
    and destination
  - If the destination record already exists, but is not synced with source
    (the playbook can't determine which record is valid/obsolete).
- Migrates the following records
  - Cluster configs
  - Cluster Accounts JWKS json config
  - Server configs
  - Server credentials

To run:

- Login to all secrets storages you want to migrate from or to.
- Execute `scripts/x-secrets-storage-migration-wizzard.sh`
  - DO NOT USE `--limit`.
  - Follow instructions/prompts from Ansible playbook.

## Playbook Live Demos

- Deploy portal on xyz:  
  https://asciinema.org/a/XMXVFDB96R5FaGgYhoEHVno04
- Restart portal on xyz:  
  https://asciinema.org/a/cIILRC6QHU3vAgzGIpOyc2rS6
- Set versions and redeploy portal on xyz:  
  https://asciinema.org/a/iqIXxYwvdxkaKg7MGaZQ5HLZD
- Rollback to the previous portal configuration with passed integration tests
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

### LastPass Session Not Active

Example error 1:

```
Your LastPass session is not active.
Execute:

    scripts/lastpass-login.sh
```

Example error 2:

```
Error: Could not find decryption key. Perhaps you need to login with `lpass login`.
```

Description:  
This error means that the playbook tries to read data from LastPass, but you
didn't login to LastPass or your LastPass session expired.

Fix:  
Execute `scripts/lastpass-login.sh`.

For more details see: [Playbook Execution > LastPass Login](#lastpass-login).

### Host not found

There are a few errors are can happen that are both related to a host not being found in the `hosts.ini` file.

Example 1:

```
% ./scripts/portals-ping.sh --limit sev1
Stopping Ansible Control Machine...
Starting Ansible Control Machine...
Ansible requirements (roles and collections) are up-to-date
Executing:
    ansible --inventory /tmp/ansible-private/inventory/hosts.ini webportals -m ping -u user --limit sev1
in a docker container...
[WARNING]: Could not match supplied host pattern, ignoring: sev1
ERROR! Specified hosts and/or --limit does not match any hosts
ERROR: Error 1
```

Example 2:

```
❯ scripts/portals-ping.sh
Ansible Control Machine is running
Ansible requirements (roles and collections) are up-to-date
Executing:
    ansible --inventory /tmp/ansible-private/inventory/hosts.ini webportals -m ping -u user
in a docker container...
[WARNING]: Unable to parse /tmp/ansible-private/inventory/hosts.ini as an
inventory source
[WARNING]: No inventory was parsed, only implicit localhost is available
[WARNING]: provided hosts list is empty, only localhost is available. Note that
the implicit localhost does not match 'all'
[WARNING]: Could not match supplied host pattern, ignoring: webportals
SUCCESS: Command finished successfully
```

This can happen if the `ansiblecm` was started when you were not at the expected relative directory to `ansible-private` or started ansible before the directory existed. The fix is to stop `ansbilecm` and re-run the command.

```
docker stop ansiblecm
```
