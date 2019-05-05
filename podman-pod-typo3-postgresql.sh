#!/bin/sh

# Creates the pod and defines the exposed ports
podman pod create \
    --name typo3-pod \
    --publish 127.0.0.1:5432:5432 \
    --publish 127.0.0.1:8080:80 \
    --share net

# Starts the MariaDB container in the pod
podman run \
    --detach \
    --name postgresql \
    --pod typo3-pod \
    --env POSTGRESQL_DATABASE=t3 \
    --env POSTGRESQL_USERNAME=t3 \
    --env POSTGRESQL_PASSWORD=t3 \
    --volume postgresql-vol:/bitnami/postgresql \
    bitnami/postgresql

# Starts the TYPO3 container in the pod
podman run \
    --detach \
    --name typo3 \
    --pod typo3-pod \
    --hostname dev.typo3.local \
    --volume typo3-vol:/var/www/localhost \
    $@ \
    undecaf/typo3-dev
    