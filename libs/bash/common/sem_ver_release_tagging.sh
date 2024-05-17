#!/usr/bin/env bash

set -e

declare CHANGELOG_PATH
declare LINES_FOR_CONTEXT
declare MSG
declare SEM_VER
declare PREV_TARGET

PREV_TARGET="HEAD~1"

{
    CHANGELOG_PATH=$(git diff $PREV_TARGET --name-only | grep docs/CHANGELOG.md)
    printf "INFO: CHANGELOG_PATH is %s.\n" "$CHANGELOG_PATH"
} || {
    printf "WARN: No changes to '**/CHANGELOG.md' found between commit and %s.\n" "$PREV_TARGET"
    exit 0
}

# get the messge from the CHANGELOG
# Remove the git line leading `+` character
# Remove the git status title line
# Double backslash escape for Jenkins
# https://stackoverflow.com/questions/59716090/how-to-remove-first-line-from-a-string
MSG=$(git diff $PREV_TARGET --unified=0 "$CHANGELOG_PATH" | \
    grep -E "^\\+" | \
    sed 's/+//' | \
    sed 1d
)
printf "INFO: MSG is:\n%s\n" "$MSG"

# ignore changes to the header section. Look for changes only after the first pattern of ## [N.N.N]


# output git diff, include --unified=2 to ensure unchanged text (up to 2 lines) in the middle of a diff is included. Specifically this ensures ### Added || ### Fixed || ### Deleted are included in the output
# remove Git header
# remove header $LINES_FOR_CONTEXT count of lines
# remove tail $LINES_FOR_CONTEXT count of lines
# remove lines starting with `-` (git remove) character
# remove `+` from line if the first character (git add)
LINES_FOR_CONTEXT=2
printf "LINES_FOR_CONTEXT: %s\n" "$LINES_FOR_CONTEXT"

# shellcheck disable=SC2004
MSG=$(git diff $PREV_TARGET --unified="$LINES_FOR_CONTEXT" "$CHANGELOG_PATH" | \
    tail -n +$((5+$LINES_FOR_CONTEXT)) | \
    tail -n +"$LINES_FOR_CONTEXT" | \
    head -n -"$LINES_FOR_CONTEXT" | \
    sed '/^-/d' | \
    sed 's/+//'
)
printf "INFO: MSG is:\n%s\n" "$MSG"

# grep extract SemVer from string
# https://stackoverflow.com/questions/16817646/extract-version-number-from-a-string
SEM_VER=$(echo "$MSG" | grep -Po "([0-9]+([.][0-9]+)+)")
if [[ ! "$SEM_VER" ]]
then
    printf "ERR: Valid SEM_VER not found. Is %s properly formatted?.\n" "$CHANGELOG_PATH"
    exit 1
fi
# Return only the most recent SemVer string if multiple are found
SEM_VER=$(echo "$SEM_VER" | head -n 1)

# Output SEM_VER being worked with
printf "INFO: SEM_VER is:\n%s\n" "$SEM_VER"

if [[ $DRY_RUN == "" ]]
then
    printf "INFO: Creating and pushing tag with value %s.\n" "$SEM_VER"
    # https://stackoverflow.com/questions/4457009/special-character-in-git-possible
    {
        git tag \
            --annotate "$SEM_VER" \
            --cleanup="verbatim" \
            --message="$(printf "%s" "$MSG")"
        git config --global push.default matching
        git push origin "$SEM_VER"
    } || {
        printf "WARN: Tag %s already exists in project, skipping." "$SEM_VER"
        exit 0
    }
fi

printf "INFO: ...done.\n"
