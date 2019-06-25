#!/bin/bash

echo '********************* Testing'

set -x -e

./t3 run -d mariadb -t ${TYPO3_VER}-${TRAVIS_TAG:-latest}
trap './t3 stop --rm' EXIT

docker container ls -f name='^/typo3(-db)?$'
docker volume ls -f name='^typo3-(root|data)$'

# TODO
