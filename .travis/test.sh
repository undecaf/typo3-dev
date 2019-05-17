#!/bin/bash

echo '********************* Testing'
docker image ls

echo "--$TRAVIS_TAG-- --${TRAVIS_TAG:-latest}--"

# TODO
