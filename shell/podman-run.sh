#!/bin/sh -x

podman run \
    --detach \
    --name typo3 \
    --hostname dev.typo3.local \
    --env HOST_IP=$(hostname -I | awk '{print $1}') \
    --volume typo3-vol:/var/www/localhost \
    --publish 127.0.0.1:8080:80 \
    undecaf/typo3-dev
