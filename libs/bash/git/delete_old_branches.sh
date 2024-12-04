#!/bin/bash -l

## configuration

set -eo pipefail

# shellcheck disable=SC1091
source "$HOME/.bashrc" || exit 1

if [[ $LOG_LEVEL == "TRACE" ]]
then 
    set -x
fi

# -----

printf "INFO: Starting...\n"

declare ALLOWED_TIME
declare BRANCHES
declare NOW_TIME

# -----

printf "INFO: Setting defaults...\n"

ALLOWED_TIME="2592000" # 30 days as seconds
echo "${1}"
if [[ $1 != "" ]]
then
    ALLOWED_TIME="${1}"
fi

BRANCHES="$(git for-each-ref --sort=authordate --format '%(authordate:unix) %(refname:short)' refs/heads)"
NOW_TIME=$(date +%s)

# -----

printf "INFO: Processing branches...\n"

# `for/do` loops words, `while/read` loops lines. We want to loop per line
printf "%s" "$BRANCHES" | while read -r BRANCH
do
    declare BRANCH_NAME
    BRANCH_NAME=$(echo "$BRANCH" | awk '{print $2}')
    # printf 'BRANCH_NAME: %s\n' "$BRANCH_NAME"

    if [[ $BRANCH_NAME ==  'main' || $BRANCH_NAME == 'master' ]]
    then
        printf "INFO: Always ignore main branch.\n"
        continue
    fi

    declare BRANCH_TIME 
    BRANCH_TIME=$(echo "$BRANCH" | awk '{print $1}')
    # printf 'BRANCH_TIME: %s\n' "$BRANCH_TIME"

    declare TIME_DIFF
    TIME_DIFF="$((NOW_TIME-BRANCH_TIME))"
    # printf 'TIME_DIFF: %s\n' "$TIME_DIFF"
    # printf 'NOW_TIME: %s\n' "$NOW_TIME"
    # printf 'ALLOWED_TIME: %s\n' "$ALLOWED_TIME"

    if [[ $TIME_DIFF -gt $ALLOWED_TIME ]]
    then
        printf "INFO: Branch older allowed time. Deleting branch %s\n" "$BRANCH_NAME"

        printf 'BRANCH_TIME: %s\n' "$BRANCH_TIME"
        printf 'NOW_TIME: %s\n' "$NOW_TIME"
        printf 'TIME_DIFF: %s\n' "$TIME_DIFF"

        ## checkout main
        git checkout main
        ## delete remove branch
        git branch -D "$BRANCH_NAME"
        ## delete local branch
        git push "origin/$BRANCH_NAME"

        ## TODO Trigger Jenkins multi-branch pipeline scan or fail w/ INFO
        continue
    fi

    printf "INFO: Branch %s not yet expired.\n" "$BRANCH_NAME"
done

printf "INFO: ...done.\n"
