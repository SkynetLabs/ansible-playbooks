- Removed takedown script, playbook and all its references in favor of using `deny_public_access` variable for putting a server in a state where all public access to download, upload and registry apis (status code 403 Forbidden) is blocked but the server still runs health checks, keeps files healthy and responds to requests