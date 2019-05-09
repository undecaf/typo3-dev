#!/bin/bash

# Usage: build.sh [OWNER/REPO] [TAG]

expand_tag() {
    test "$1" = "${1%.*}" && echo "$1" || echo "$(expand_tag ${1%.*}) $1"
}

OWNER_REPO=$1

docker build --pull --cache-from $OWNER_REPO --tag $OWNER_REPO .

for T in $(expand_tag $2) latest; do 
    echo "*************** Tagging $OWNER_REPO as $OWNER_REPO:$T"
    docker tag $OWNER_REPO $OWNER_REPO:$T
done
