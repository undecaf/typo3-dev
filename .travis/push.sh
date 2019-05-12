#!/bin/bash

# Usage: push.sh [TAG]

minor_tag() {
    local RE='([0-9]+\.[0-9]+)(\..+)?'
    [[ "$1" =~ $RE ]] && echo ${BASH_REMATCH[1]} || echo "$1"
}

# Use only MAJOR.MINOR and 'latest' as container version
for T in $(minor_tag $2) latest; do 
    echo "*************** Pushing $TRAVIS_REPO_SLUG:$TYPO3_VER-$T"
    docker push $TRAVIS_REPO_SLUG:$TYPO3_VER-$T
done

echo "*************** Pushing README.md"
docker run --rm \
    -v $(readlink -f README.md):/data/README.md \
    -e DOCKERHUB_USERNAME="$REGISTRY_USER" \
    -e DOCKERHUB_PASSWORD="$REGISTRY_PASS" \
    -e DOCKERHUB_REPO_PREFIX=${TRAVIS_REPO_SLUG%/*} \
    -e DOCKERHUB_REPO_NAME=${TRAVIS_REPO_SLUG#*/} \
    sheogorath/readme-to-dockerhub
