#!/bin/bash

# Backup HashiCorp Vault Internal Storage (raft) backend if there are any
# updates in the secrets.
# Requires the following variables set in .env file:
#
# HCV_BACKUP_ROLE_ID
# HCV_BACKUP_SECRET_ID
# HCV_KV_V2_PATH=kv
# AWS_S3_BUCKET
# AWS_ACCESS_KEY_ID
# AWS_SECRET_ACCESS_KEY

# Load vars
. $(dirname "$0")/.env

# Login to HashiCorp Vault
# - try to login
# - get token line out of response
# - get token out of token line
# - fail if not ok
token=$(docker exec vault vault write auth/approle/login role_id=$HCV_BACKUP_ROLE_ID secret_id=$HCV_BACKUP_SECRET_ID | grep 'token\s' | sed 's/^.*\s//')
if [[ $? -ne 0 ]]; then
    echo Error logging to HashiCorp Vault.
    echo Exiting...
    exit 1
fi

# Scan kv storage for all records
function get_kv_records {
    local src_path="$1"

    echo "##################################################"
    echo "Searching recursively a path: $src_path"

    # Get direct children of a path (subdirs or secret records)
    # - list children
    # - remove 2 header lines
    # - store in an array
    readarray -t sub_paths < <(docker exec -e VAULT_TOKEN=$token vault vault kv list "$src_path" | tail -n +3)
    if [[ $? -ne 0 ]]; then
        echo Error listing directories/secrets.
        echo Exiting...
        exit 1
    fi

    # Iterate over children
    for sub_path in "${sub_paths[@]}"; do
        local full_sub_path="$src_path$sub_path"
        if [[ "$sub_path" == */ ]]; then
            # We have another subdir
            # - search recursively the subdir
            echo "Found a subdir: $full_sub_path"
            get_kv_records "$full_sub_path"
        else
            # We have a record
            echo "Found a secret: $full_sub_path"
            kv_records+=("$full_sub_path")
        fi
    done
}


kv_records=()
get_kv_records "$HCV_KV_V2_PATH/"

# Get latest update of each kv record
old_time=1900-01-01T00:00:00.00000000Z
latest_update_time=$old_time
for record in "${kv_records[@]}"; do
    echo "Getting update time of a record:"
    echo "- $record"
    update_time=$(docker exec -e VAULT_TOKEN=$token vault vault kv metadata get "$record" | grep updated_time | sed 's/^.*\s//')
    if [[ $? -ne 0 ]]; then
        echo Error getting update time.
        echo Exiting...
        exit 1
    fi
    echo "- $update_time"
    if [[ "$update_time" > "$latest_update_time" ]]; then
        latest_update_time=$update_time
    fi
done
echo Latest update time of a kv record is: $latest_update_time

# Check if we should perform a backup
backup_dir=vault/backups
last_backup_time_file=$(dirname "$0")/vault/backups/last-backup-timestamp

if [[ -f "$last_backup_time_file" ]]; then
    last_backup_time=$(<$last_backup_time_file)
    echo Found the latest backup from $last_backup_time
else
    echo No backup timestamp was found
    last_backup_time=$old_time
fi

if [[ "$last_backup_time" > "$latest_update_time" ]]; then
    echo Found a backup after the latest kv record update.
    echo No need to backup.
    exit 0
fi

# Create backup/raft snapshot
# - set vars
# - create Vault raft (Integrated Storge) snapshot
# - fix permissions for host user

backup_start_time=$(docker exec vault date -Ins)
echo Starting a backup at $backup_start_time...
backup_filename=backup-$(echo $backup_start_time | cut -c-19 | sed 's/:/-/g').snap
backup_full_path=$backup_dir/$backup_filename
docker exec -e VAULT_TOKEN=$token vault vault operator raft snapshot save $backup_full_path
if [[ $? -ne 0 ]]; then
    echo Error creating Vault raft snapshot.
    echo Exiting...
    exit 1
fi
echo Creating a snapshot finished successfully.

# Upload Vault raft snapshot to AWS S3
echo Uploading to AWS S3...
pushd $(dirname "$0") > /dev/null
docker run --rm -it \
    -v $PWD/$backup_dir:/$backup_dir \
    -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
    -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
    amazon/aws-cli:2.7.31 \
    s3 cp --no-progress /$backup_full_path s3://$AWS_S3_BUCKET/$backup_filename
if [[ $? -ne 0 ]]; then
    echo Error uploading snapshot to AWS S3.
    echo Exiting...
    popd > /dev/null
    exit 1
fi
popd > /dev/null
echo Uploading to AWS S3 finished.

# Save the latest backup time to file
echo Creating the last backup timestamp...
docker exec vault chown -R $(id -u):$(id -g) /$backup_dir
echo "$backup_start_time" > "$last_backup_time_file"
echo Finished.
