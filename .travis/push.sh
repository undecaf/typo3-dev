#!/bin/bash

TOKEN=$(curl -s -H "Content-Type: application/json" -X POST -d '{"username": "'$REGISTRY_USER'", "password": "'$REGISTRY_PASS'"}' https://hub.docker.com/v2/users/login/ | jq -r .token)

for T in $(.travis/tags.sh); do 
    echo $'\n*************** '"Pushing $TRAVIS_REPO_SLUG:$T"

    # Delete the tag then push it
    curl 'https://hub.docker.com/v2/repositories/$TRAVIS_REPO_SLUG/tags/$T/' \
        -X DELETE \
        -H "Authorization: JWT ${TOKEN}"

    docker push $TRAVIS_REPO_SLUG:$T
done

# README.md exceeds the size limit of Dockerhub, it has to be excerpted manually
exit

echo $'\n*************** Pushing README.md'
docker run --rm \
    -v $(readlink -f README.md):/data/README.md \
    -e DOCKERHUB_USERNAME="$REGISTRY_USER" \
    -e DOCKERHUB_PASSWORD="$REGISTRY_PASS" \
    -e DOCKERHUB_REPO_PREFIX=${TRAVIS_REPO_SLUG%/*} \
    -e DOCKERHUB_REPO_NAME=${TRAVIS_REPO_SLUG#*/} \
    sheogorath/readme-to-dockerhub
