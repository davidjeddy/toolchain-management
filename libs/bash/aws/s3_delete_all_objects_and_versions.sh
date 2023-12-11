#!/bin/bash -e

# source https://gist.github.com/weavenet/f40b09847ac17dd99d16
# version 0.0.5
# usage s3_delete_all_objects_and_versions.sh BUCKET [BUCKET…]

set -o errexit -o noclobber -o nounset -o pipefail

if [[ "$#" -eq 0 ]]
then
    cat >&2 << 'EOF'
./s3_delete_all_objects_and_versions.sh BUCKET [BUCKET…]

Deletes *all* versions of *all* files in *all* given buckets. Only to be used in case of emergency!
EOF
    exit 1
fi

read -n1 -p "THIS WILL DELETE EVERYTHING IN BUCKETS ${*}! Press Ctrl-c to cancel or anything else to continue: " -r

declare VERSION_LOG
VERSION_LOG="output_$(date +%s).log"
touch "$VERSION_LOG" || exit 1

declare MARKER_LOG
MARKER_LOG="output_$(date +%s).log"
touch "$MARKER_LOG" || exit 1

delete_objects() {
    declare LOG="${2}"

    count="$(jq length <<< "$1")"

    if [[ "$count" -eq 0 ]]
    then
        echo "No objects found; skipping" >> "$LOG"
        return
    fi

    echo "Removing objects" >> "$LOG"
    for index in $(seq 0 $(("$count" - 1)))
    do
        key="$(jq --raw-output ".[${index}].Key" <<< "$1")"
        version_id="$(jq --raw-output ".[${index}].VersionId" <<< "$1")"
        delete_command=(aws s3api delete-object --bucket="$bucket" --key="$key" --version-id="$version_id")

        printf '%q ' "${delete_command[@]}" >> "$LOG"
        printf '\n' >> "$LOG"

        "${delete_command[@]}"
    done
}

for bucket
do
    versions="$(aws s3api list-object-versions --bucket="$bucket" | jq .Versions)"
    echo "INFO: $bucket delete_objects $($versions | jq -r .Key)"
    # https://unix.stackexchange.com/questions/286971/putting-subshell-in-background-vs-putting-command-in-background
    delete_objects "$versions" "$VERSION_LOG" &

    markers="$(aws s3api list-object-versions --bucket="$bucket" | jq .DeleteMarkers)"
    echo "INFO: $bucket delete_objects $($markers | jq -r .Key)"
    # https://unix.stackexchange.com/questions/286971/putting-subshell-in-background-vs-putting-command-in-background
    delete_objects "$markers" "$MARKER_LOG" &

    sleep 1
done
