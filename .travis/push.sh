#!/bin/bash

# Usage: push.sh [TAG]

# Use only MAJOR.MINOR of tag
RE='([0-9]+\.[0-9]+)(\..+)?'
[[ "$1" =~ $RE ]] && TAG=${BASH_REMATCH[1]} || TAG="$1"

for T in ${TAG:+$TYPO3_VER-$TAG} ${TYPO3_VER}-latest $EXTRA_TAGS; do 
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
