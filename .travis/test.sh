#!/bin/bash

echo '********************* Testing'
docker image ls

# Simulate failed test
exit 1
