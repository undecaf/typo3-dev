#!/bin/bash

echo '********************* Testing'

# Extract MAJOR.MINOR of $TRAVIS_TAG
RE='^([0-9]+\.[0-9]+)(\..+)?'
[[ "$TRAVIS_TAG" =~ $RE ]] && TAG=$TYPO3_VER-${BASH_REMATCH[1]} || TAG=${TYPO3_VER}-latest

set -x -e

./t3 run -d mariadb -t $TAG
trap './t3 stop --rm' EXIT

docker container ls -f name='^/typo3(-db)?$'
docker volume ls -f name='^typo3-(root|data)$'
