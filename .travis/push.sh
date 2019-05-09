#!/bin/bash

# Usage: push.sh [OWNER/REPO] [TAG]

expand_tag() {
    test "$1" = "${1%.*}" && echo "$1" || echo "$(expand_tag ${1%.*}) $1"
}

OWNER_REPO=$1

for T in $(expand_tag $2) latest; do 
    echo "*************** Pushing $OWNER_REPO:$T"
    docker push $OWNER_REPO:$T
done
