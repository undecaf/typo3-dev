#!/bin/bash

# Usage: push.sh [OWNER/REPO] [TAG]

shorten_tag() {
    test "$1" != "${1%.*}" && echo "$(shorten_tag ${1%.*}) $1"
}

OWNER_REPO=$1

for T in $(shorten_tag $2) latest; do 
    echo "*************** Pushing $OWNER_REPO:$T"
    docker push $OWNER_REPO:$T
done
