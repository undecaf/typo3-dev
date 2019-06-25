#!/bin/bash

echo '********************* Testing'

set -x

./t3 run -d mariadb
trap './t3 stop --rm' EXIT

docker container ls -f name='^/typo3(-db)?$'
docker volume ls -f name='^typo3-(root|data)$'

# TODO
