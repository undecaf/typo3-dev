#!/bin/bash

# Usage: push.sh [EXTRA-TAG]

# Use only MAJOR.MINOR of $TRAVIS_TAG
RE='^([0-9]+\.[0-9]+)(\..+)?'
[[ "$TRAVIS_TAG" =~ $RE ]] && TAG=${BASH_REMATCH[1]} || TAG=

for T in ${TAG:+$TYPO3_VER-$TAG} ${1:+$TYPO3_VER-$1} ${EXTRA_TAG:+$1}; do 
    echo "*************** Pushing $TRAVIS_REPO_SLUG:$T"
    docker push $TRAVIS_REPO_SLUG:$T
done

echo "*************** Pushing README.md"
docker run --rm \
    -v $(readlink -f README.md):/data/README.md \
    -e DOCKERHUB_USERNAME="$REGISTRY_USER" \
    -e DOCKERHUB_PASSWORD="$REGISTRY_PASS" \
    -e DOCKERHUB_REPO_PREFIX=${TRAVIS_REPO_SLUG%/*} \
    -e DOCKERHUB_REPO_NAME=${TRAVIS_REPO_SLUG#*/} \
    sheogorath/readme-to-dockerhub
