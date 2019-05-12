#!/bin/bash

# Usage: build.sh [TAG]

minor_tag() {
    local RE='([0-9]+\.[0-9]+)(\..+)?'
    [[ "$1" =~ $RE ]] && echo ${BASH_REMATCH[1]} || echo "$1"
}

docker build \
    --pull \
    --cache-from $TRAVIS_REPO_SLUG \
    --build-arg TYPO3_VER=$TYPO3_VER \
    --build-arg CONTAINER_VER=$2 \
    --tag $TRAVIS_REPO_SLUG \
    .

# Use only MAJOR.MINOR and 'latest' as container version
for T in ${TYPO3_VER}-$(minor_tag $2) ${TYPO3_VER}-latest $EXTRA_TAG; do 
    echo "*************** Tagging $TRAVIS_REPO_SLUG as $TRAVIS_REPO_SLUG:$T"
    docker tag $TRAVIS_REPO_SLUG $TRAVIS_REPO_SLUG:$T
done
