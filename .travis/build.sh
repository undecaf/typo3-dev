#!/bin/bash

# Usage: build.sh [TAG]

docker build \
    --pull \
    --cache-from $TRAVIS_REPO_SLUG \
    --build-arg TYPO3_VER=$TYPO3_VER \
    --build-arg CONTAINER_VER=$2 \
    --tag $TRAVIS_REPO_SLUG \
    .

# Use only MAJOR.MINOR of tag
RE='([0-9]+\.[0-9]+)(\..+)?'
[[ "$1" =~ $RE ]] && TAG=${BASH_REMATCH[1]} || TAG="$1"

for T in ${TAG:+$TYPO3_VER-$TAG} ${TYPO3_VER}-latest $EXTRA_TAGS; do 
    echo "*************** Tagging $TRAVIS_REPO_SLUG as $TRAVIS_REPO_SLUG:$T"
    docker tag $TRAVIS_REPO_SLUG $TRAVIS_REPO_SLUG:$T
done
