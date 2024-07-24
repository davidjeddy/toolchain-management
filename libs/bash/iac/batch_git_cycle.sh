#!/bin/bash -l

## configuration

set -eo pipefail

# shellcheck disable=SC1091
source "$HOME/.bashrc" || exit 1

if [[ $LOG_LEVEL == "TRACE" ]]
then 
    set -x
fi

# Example: /path/to/script/batch_git_cycle.sh "Updated installer"
# Note: Must be used from the parent directory containing the module library
# Usage: /path/to/script/batch_git_cycle.sh STRING
# Version: 0.1.0 - 2024-06-21 - David Eddy - Init add of logic

# input validations

if [[ ! $1 ]]
then
    printf "ERR: Must provide Git commit message.\n"
    exit 1
fi

# configuration

declare GIT_COMMIT_MSG
GIT_COMMIT_MSG="${1}"
printf "INFO: The Git commit message to be used is: \"%s\"\n" "$GIT_COMMIT_MSG"

declare DIR_LIST
DIR_LIST=$(tree -di --prune --sort=name -L 1 | head -n -2 | tail -n +2)
printf "INFO: Directory list contains modules: \n%s\n" "$DIR_LIST"

# execution

for DIR in $DIR_LIST
do
    cd "$DIR" || exit 1

    # Safety checks
    if [[ ! -d ".tmp/toolchain-management" ]]
    then
        printf "WARN: .tmp/toolchain-management not found, installing.\n"
        ./libs/bash/install.sh
    fi

    if [[ $(git rev-parse --abbrev-ref HEAD) == "main" && $(git rev-parse --abbrev-ref HEAD) == "master" ]]
    then
        printf "WARN: Can not process changes on main/master branch, exiting.\n"
        exit 1
    fi

    # git processing
    printf "INFO: Processing IAC modules %s\n" "$DIR"
    {
        git add .
        git commit -m "${GIT_COMMIT_MSG}"
        git push
    } || {
        printf "ERR: 'git' process failed for module %s\n" "$DIR"

        printf "INFO: Should we continues? (y/n)\n"
        read -r ACCEPT_ERROR
        if [[ $ACCEPT_ERROR != 'y' ]]
        then
            cd ../
            exit 1
        fi
    }
    cd ../
done

printf "INFO: ...done.\n"
