#!/bin/sh -x

podman run \
    --detach \
    --rm \
    --name typo3 \
    --hostname dev.typo3.local \
    --volume typo3-vol:/var/www/localhost \
    --publish 127.0.0.1:8080:80 \
    undecaf/typo3-dev
