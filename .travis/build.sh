#!/bin/bash

# Usage: build.sh [EXTRA-TAG]

docker build \
    --pull \
    --cache-from $TRAVIS_REPO_SLUG \
    --build-arg TYPO3_VER=$TYPO3_VER \
    --build-arg CONTAINER_VER=$2 \
    --tag $TRAVIS_REPO_SLUG \
    .

# Use only MAJOR.MINOR of $TRAVIS_TAG
RE='^([0-9]+\.[0-9]+)(\..+)?'
[[ "$TRAVIS_TAG" =~ $RE ]] && TAG=${BASH_REMATCH[1]} || TAG=

for T in ${TAG:+$TYPO3_VER-$TAG} ${1:+$TYPO3_VER-$1} ${EXTRA_TAG:+$1}; do 
    echo "*************** Tagging $TRAVIS_REPO_SLUG as $TRAVIS_REPO_SLUG:$T"
    docker tag $TRAVIS_REPO_SLUG $TRAVIS_REPO_SLUG:$T
done
