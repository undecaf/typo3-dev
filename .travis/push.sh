#!/bin/bash

# Usage: push.sh [TAG]

shorten_tag() {
    test "$1" != "${1%.*}" && echo "$(shorten_tag ${1%.*}) $1"
}

for T in $(shorten_tag $2) latest; do 
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
