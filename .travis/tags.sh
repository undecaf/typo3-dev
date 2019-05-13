#!/bin/bash

# Extract MAJOR.MINOR of $TRAVIS_TAG
RE='^([0-9]+\.[0-9]+)(\..+)?'
[[ "$TRAVIS_TAG" =~ $RE ]] && TAGS=$TYPO3_VER-${BASH_REMATCH[1]} || TAGS=

# Use branch name, replacing 'master' with 'latest'
case "$TRAVIS_BRANCH" in
    $TRAVIS_TAG|master)
        BRANCH=latest
        TAGS="$TAGS $TYPO3_VER-$BRANCH ${VERY_LAST:+$BRANCH}"
        ;;
    *)
        TAGS="$TAGS-$TRAVIS_BRANCH $TYPO3_VER-$TRAVIS_BRANCH"
        ;;
esac

echo "$TAGS"
