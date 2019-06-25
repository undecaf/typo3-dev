#!/bin/bash

echo '********************* Testing'

set -x

./t3 run --

docker container ls -f name='^/typo3$'
docker volume ls -f name=typo3-root

./t3 stop --

# TODO
