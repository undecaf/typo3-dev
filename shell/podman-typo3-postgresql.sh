#!/bin/sh

# Starts the PosgreSQL container, must expose HTTP port _now_ for later
podman run \
    --detach \
    --rm \
    --name postgresql \
    --env POSTGRESQL_DATABASE=t3 \
    --env POSTGRESQL_USERNAME=t3 \
    --env POSTGRESQL_PASSWORD=t3 \
    --volume postgresql-vol:/bitnami/postgresql \
    --publish 127.0.0.1:5432:5432 \
    --publish 127.0.0.1:8080:80 \
    bitnami/postgresql

# Starts the TYPO3 container and joins the PosgreSQL network namespace
podman run \
    --detach \
    --rm \
    --env HOST_IP=$(hostname -I | awk '{print $1}') \
    --cap-add=SYS_ADMIN \
    --volume typo3-vol:/var/www/localhost \
    --net container:postgresql \
    --stop-timeout 2 \
    $@ \
    undecaf/typo3-dev
