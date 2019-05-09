#!/bin/bash

# Usage: build.sh [TAG]

shorten_tag() {
    test "$1" != "${1%.*}" && echo "$(shorten_tag ${1%.*}) $1"
}

docker build --pull --cache-from $TRAVIS_REPO_SLUG --tag $TRAVIS_REPO_SLUG .

for T in $(shorten_tag $2) latest; do 
    echo "*************** Tagging $TRAVIS_REPO_SLUG as $TRAVIS_REPO_SLUG:$T"
    docker tag $TRAVIS_REPO_SLUG $TRAVIS_REPO_SLUG:$T
done
