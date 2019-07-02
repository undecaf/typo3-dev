#!/bin/bash

for T in $(.travis/tags.sh); do 
    echo $'\n*************** '"Pushing $TRAVIS_REPO_SLUG:$T"
    docker push $TRAVIS_REPO_SLUG:$T
done
exit

# README.md exceeds the capabilities of Dockerhub, has to be updated manually
echo $'\n*************** Pushing README.md'
docker run --rm \
    -v $(readlink -f README.md):/data/README.md \
    -e DOCKERHUB_USERNAME="$REGISTRY_USER" \
    -e DOCKERHUB_PASSWORD="$REGISTRY_PASS" \
    -e DOCKERHUB_REPO_PREFIX=${TRAVIS_REPO_SLUG%/*} \
    -e DOCKERHUB_REPO_NAME=${TRAVIS_REPO_SLUG#*/} \
    sheogorath/readme-to-dockerhub
